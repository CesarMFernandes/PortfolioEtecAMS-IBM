package br.edu.etec.biblioteca;

import br.edu.etec.biblioteca.core.Database;
import br.edu.etec.biblioteca.models.Aluno;
import br.edu.etec.biblioteca.models.Emprestimo;
import br.edu.etec.biblioteca.models.Livro;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RegraDeNegocioTest {

    @BeforeEach
    void prepararBanco() {
        Database.criarBancoSeNecessario();
    }

    @AfterEach
    void limpar() {
        // TODO(opcional): remover o banco de teste ao final de cada teste.
    }

    @Test
    void conexaoDeveEstarDisponivel() {
        assertNotNull(Database.getConnection());
    }

    @Test
    void bancoDeveEstarPopulado() {
        assertEquals(4, new Aluno().todos().size(),
            "O seed deve criar 4 alunos.");
    }

    @Test
    void deveCalcularQuantidadeDisponivel() {
        Livro livro = new Livro();
        int disp = livro.quantidadeDisponivel(4); // Vidas Secas (qtd 4)
        // Com o seed, ainda não há empréstimos de Vidas Secas -> deve dar 4.
        assertEquals(4, disp);
    }

    //TESTES DAS REGRAS DE NEGÓCIO DA SPEC
    @Test
    void naoDeveriaEmprestarAlemDoEstoque() {
        Livro livro = new Livro();
        Emprestimo emprestimo = new Emprestimo();

        int livroId = 3; // O Cortico
        int outroAlunoId = 3; // Carla Dias (ainda não tem esse livro)

        int disponivelAntes = livro.quantidadeDisponivel(livroId);
        assertEquals(0, disponivelAntes,
            "Pré-condição: pelo seed, este livro já deveria estar com 0 disponíveis.");

        boolean resultado = emprestimo.emprestar(outroAlunoId, livroId);

        assertFalse(resultado,
            "BUG: emprestar() registrou o empréstimo mesmo com disponibilidade 0. "
            + "A variável 'disponivel' é calculada e nunca verificada antes do INSERT.");
    }


    @Test
    void naoDeveriaPermitirDevolucaoDupla() {
        Emprestimo emprestimo = new Emprestimo();
        int alunoId = 1;  // Ana Souza
        int livroId = 5;  // Capitães da Areia (qtd 2, livre no seed)

        boolean emprestou = emprestimo.emprestar(alunoId, livroId);
        assertTrue(emprestou, "Pré-condição: o empréstimo inicial deveria ser aceito.");

        List<String[]> todos = emprestimo.todos(); // ordenado por data DESC
        String idEmprestimo = todos.get(0)[0];

        boolean primeiraDevolucao = emprestimo.devolver(Integer.parseInt(idEmprestimo));
        assertTrue(primeiraDevolucao, "A primeira devolução deveria funcionar normalmente.");

        boolean segundaDevolucao = emprestimo.devolver(Integer.parseInt(idEmprestimo));
        assertFalse(segundaDevolucao,
            "BUG: devolver() não verifica se o empréstimo já foi devolvido; "
            + "é possível 'devolver' o mesmo registro mais de uma vez, "
            + "sobrescrevendo a data de devolução.");
    }


    @Test
    void alunoNaoDeveriaPassarDoLimiteDeLivros() {
        Emprestimo emprestimo = new Emprestimo();
        int alunoId = 4; // Diego Rocha

        assertTrue(emprestimo.emprestar(alunoId, 2), "1º empréstimo deveria ser aceito.");
        assertTrue(emprestimo.emprestar(alunoId, 4), "2º empréstimo deveria ser aceito.");
        assertTrue(emprestimo.emprestar(alunoId, 1), "3º empréstimo deveria ser aceito.");

        boolean quarto = emprestimo.emprestar(alunoId, 4);
        assertFalse(quarto, "O aluno não deveria conseguir um 4º empréstimo simultâneo.");
    }

    // TESTES EXTRAS (outras regras/defeitos observados na UI)
    @Test
    void naoDeveriaEmprestarMesmoLivroDuasVezesParaMesmoAluno() {
        Emprestimo emprestimo = new Emprestimo();
        int alunoId = 2; // Bruno Lima
        int livroId = 1; // Dom Casmurro

        boolean primeiro = emprestimo.emprestar(alunoId, livroId);
        assertTrue(primeiro, "Primeiro empréstimo deveria funcionar.");

        boolean segundo = emprestimo.emprestar(alunoId, livroId);
        assertFalse(segundo,
            "BUG: o sistema permite que o mesmo aluno tenha duas cópias do "
            + "mesmo livro emprestadas simultaneamente.");
    }

 
    @Test
    void naoDeveriaAceitarEmailDuplicado() {
        Aluno aluno = new Aluno();
        String emailExistente = "ana@escola.edu"; // já existe no seed (Ana Souza)

        boolean resultado = aluno.criar("Outra Pessoa", emailExistente, "3A", "11999999999");

        assertFalse(resultado,
            "O cadastro com e-mail duplicado é de fato recusado (a constraint UNIQUE "
            + "do banco garante isso), mas o defeito real é de UX: a causa "
            + "específica não chega até o usuário na tela (ver AlunoPanel).");
    }


    @Test
    void naoDeveriaAceitarQuantidadeNegativa() {
        Livro livro = new Livro();

        boolean resultado = livro.criar(
            "Livro Teste Bugado", "Autor Teste", 2020, "Teste", -5, "0000000000000");

        assertFalse(resultado,
            "BUG: Livro.criar() não valida quantidade negativa; o registro "
            + "é inserido no banco mesmo com quantidade = -5.");
    }
}