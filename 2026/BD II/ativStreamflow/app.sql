use streamflow;

/*Ver dados da sua conta*/
select * from assinantes where id = 1;

/*Criar conta*/
insert into assinantes(nome, cpf, email, data_nascimento, uf)
values("Fulano da Silva", "12312312312", "silva.fulano@gmail.com", "2001-02-23", "SP");

/*Inserir saldo*/
update assinantes set saldo = saldo + 10 where id = 1;

/*Renovar assinatura / Cobrança de assinatura*/
update assinantes set 
assinatura_ativa = if(saldo>=10, 1, 0),
saldo = if(saldo>=10, saldo-10, saldo)
where id = 1;

/*Atualizar dados*/
update assinantes set 
nome = "Ciclano de Souza",
cpf = "45645645645",
email = "souza.ciclano@outlook.net",
data_nascimento = "1994-11-09",
uf = "RJ"
where id = 1;



/*Ver perfis da sua conta*/
select * from perfis where assinante_id = 1 and ativo = 1;

/*Criar perfil*/
insert into perfis (nome_exibicao, assinante_id)
select "amigo", 1
where (SELECT count(*) FROM perfis WHERE assinante_id = 1 and ativo = 1) <= 4 and 
(select count(*) from perfis where assinante_id = 1 and nome_exibicao like "amigo" and ativo = 1) = 0; /*apenas faz o insert caso não tenha 5 perfis ou mais e caso não tenha nome duplicado*/

/*Atualizar nome de perfil*/
update perfis set
nome_exibicao = if((select count(*) from perfis where assinante_id = 1 and nome_exibicao like "amigo" and ativo = 1) = 0, "amigo", nome_exibicao) /*apenas atualiza caso não gere nome duplicado*/
where id = 1;

/*Desativar perfil*/
update perfis set 
ativo = 0
where id = 1;



/*Listar catálogo de filmes*/
select videos.titulo as Título, sec_to_time(duracao_segundos) as Duracao_do_Filme
from filmes
inner join videos on filmes.video_id = videos.id
where videos.ativo = 1;

/*Listar produtoras de um filme*/
select videos.titulo as Título, produtoras.nome as Produtora_do_filme
from filmes
inner join videos on filmes.video_id = videos.id
inner join videosprodutoras on videos.id = videosprodutoras.video_id
inner join produtoras on videosprodutoras.produtora_id = produtoras.id
where filmes.id = 2;

/*Listar catálogo de séries*/
select series.titulo as Título, count(distinct temporadas.id) as Quantidade_de_Temporadas, count(episodios.id) as Quantidade_de_Episódios
from series
inner join temporadas on series.id = temporadas.serie_id
inner join episodios on temporadas.id = episodios.temporada_id
inner join videos on episodios.video_id = videos.id where videos.ativo = 1
having count(episodios.id) >= 1;

/*Listar temporadas e episódios de uma série*/
select series.titulo as Série, temporadas.titulo as Título_da_Temporada, temporadas.numero as Número_da_temporada, videos.titulo as Título_do_Episódio, episodios.numero as Número_do_Episódio, sec_to_time(duracao_segundos) as Duração
from series
inner join temporadas on series.id = temporadas.serie_id
inner join episodios on temporadas.id = episodios.temporada_id
inner join videos on episodios.video_id = videos.id
where videos.ativo = 1
order by Número_da_Temporada, Número_do_Episódio;

/*Listar produtoras de um episódio*/
select videos.titulo as Título, produtoras.nome as Produtora_do_Episódio
from episodios
inner join videos on episodios.video_id = videos.id
inner join videosprodutoras on videos.id = videosprodutoras.video_id
inner join produtoras on videosprodutoras.produtora_id = produtoras.id
where episodios.id = 2;

/*Criação de relatório ao clicar em play*/
insert into reproducoes(ip, dispositivo, perfil_id, video_id)
values("123.12.123.12", "Web", 1, 2);

/*Marca todos os registros como concluído de um vídeo e perfil caso o perfil tenha terminado o vídeo*/
update reproducoes set
concluido = 1
where perfil_id = 1 and video_id = 4;

/*Atualiza o tempo assistido de um relatório específico após o fim da sessão*/
update reproducoes set
tempo_assistido_segundos = 10000
where id = 7;

/*Painel de Tela Inicial (Continuar Assistindo)*/
select videos.titulo as Vídeo, reproducoes.data_hora_inicio as Última_Visualização
from reproducoes
inner join videos on reproducoes.video_id = videos.id
inner join perfis on reproducoes.perfil_id = perfis.id
where perfis.id = 1 and reproducoes.concluido = 0 and videos.ativo = 1
group by videos.id
order by Última_Visualização desc;