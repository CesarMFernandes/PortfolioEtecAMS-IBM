CREATE DATABASE streaming_db;
USE streaming_db;

CREATE TABLE filmes (
    id_filme INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(150),
    ano_lancamento INT,
    categoria VARCHAR(50),
    classificacao VARCHAR(5),
    preco_aluguel DECIMAL(5,2)
);

CREATE TABLE acessos (
    id_acesso INT AUTO_INCREMENT PRIMARY KEY,
    id_filme INT,
    data_acesso DATETIME,
    usuario VARCHAR(50),
    FOREIGN KEY (id_filme) REFERENCES filmes(id_filme)
);

-- Massa de Dados: 30 Filmes
INSERT INTO filmes (titulo, ano_lancamento, categoria, classificacao, preco_aluguel) VALUES 
('Matrix Recarregado', 2003, 'Ficção', '16', 5.90),
('Matrix Revolutions', 2003, 'Ficção', '16', 5.90),
('O Segredo do SQL', 2024, 'Documentário', 'L', 0.00),
('A Rede Social', 2010, 'Drama', '12', 3.50),
('Toy Story 1', 1995, 'Animação', 'L', 2.00),
('Toy Story 2', 1999, 'Animação', 'L', 2.50),
('Toy Story 3', 2010, 'Animação', 'L', 4.00),
('Batman: O Cavaleiro das Trevas', 2008, 'Ação', '14', 4.50),
('Coringa', 2019, 'Drama', '16', 6.00),
('Blade Runner 2049', 2017, 'Ficção', '14', 7.00),
('O Poderoso Chefão', 1972, 'Policial', '14', 2.90),
('Pulp Fiction', 1994, 'Policial', '18', 3.00),
('Clube da Luta', 1999, 'Drama', '18', 3.50),
('Forrest Gump', 1994, 'Drama', 'L', 2.50),
('Inception', 2010, 'Ficção', '14', 5.00),
('Interstellar', 2014, 'Ficção', '10', 6.50),
('O Rei Leão', 1994, 'Animação', 'L', 1.50),
('Gladiador', 2000, 'Ação', '14', 3.20),
('Vingadores: Ultimato', 2019, 'Ação', '12', 8.00),
('Parasita', 2019, 'Suspense', '16', 7.50),
('O Auto da Compadecida', 2000, 'Comédia', 'L', 2.00),
('Cidade de Deus', 2002, 'Policial', '18', 4.00),
('Central do Brasil', 1998, 'Drama', '12', 2.50),
('Duna: Parte 2', 2024, 'Ficção', '14', 9.90),
('O Exterminador do Futuro 2', 1991, 'Ação', '14', 2.00),
('De Volta para o Futuro', 1985, 'Ficção', 'L', 1.50),
('Tropa de Elite', 2007, 'Policial', '16', 4.50),
('O Show de Truman', 1998, 'Drama', 'L', 3.00),
('A Lista de Schindler', 1993, 'Drama', '14', 2.00),
('O Silêncio dos Inocentes', 1991, 'Suspense', '14', 3.50);

-- Massa de Dados: 20 Acessos
INSERT INTO acessos (id_filme, data_acesso, usuario) VALUES
(1, '2024-01-10 08:30:00', 'Ana Oliveira'),
(3, '2024-01-12 14:20:00', 'Ricardo Santos'),
(5, '2024-01-15 19:00:00', 'Carla Souza'),
(10, '2024-01-20 22:45:00', 'Ana Oliveira'),
(15, '2024-02-05 10:00:00', 'Marcos Lima'),
(20, '2024-02-10 15:30:00', 'Ricardo Santos'),
(24, '2024-02-28 23:59:59', 'Carla Souza'),
(3, '2024-03-01 09:15:00', 'Ana Oliveira'),
(8, '2024-03-15 20:00:00', 'Marcos Lima'),
(2, '2024-03-20 18:30:00', 'Bruno Ferreira'),
(22, '2024-03-25 21:00:00', 'Ricardo Santos'),
(30, '2024-03-31 23:50:00', 'Ana Oliveira'),
(1, '2024-04-01 07:00:00', 'Marcos Lima'),
(19, '2024-04-05 19:20:00', 'Bruno Ferreira'),
(27, '2024-04-10 20:45:00', 'Ricardo Santos'),
(11, '2024-04-12 14:00:00', 'Ana Oliveira'),
(14, '2024-04-15 16:30:00', 'Bruno Ferreira'),
(17, '2024-04-18 10:00:00', 'Marcos Lima'),
(26, '2024-04-20 09:00:00', 'Ricardo Santos'),
(3, '2024-04-22 13:15:00', 'Ana Oliveira');

select * from filmes where titulo like '%Futuro%';
select * from filmes where titulo like 'O%o';
select * from filmes where titulo like 'Toy Story _';
select * from filmes where titulo like '% de %';
select * from filmes where titulo like '% ____';

select * from filmes where ano_lancamento between 1990 and 1999;
select * from filmes where preco_aluguel between 2 and 5;
select * from acessos where data_acesso between '2024-03-01 00:00:00' and '2024-03-31 23:59:59';
select * from filmes where preco_aluguel not between 0 and 3;
select * from filmes where id_filme between 10 and 20 order by titulo;

select * from filmes where categoria in('Ação', 'Policial', 'Suspense');
select * from filmes where classificacao in('L', '10', '12');
select titulo from filmes where id_filme in(select id_filme from acessos);
select * from filmes where id_filme not in(select id_filme from acessos);
select * from acessos where usuario in('Ana Oliveira', 'Ricardo Santos');

drop database streaming_db;