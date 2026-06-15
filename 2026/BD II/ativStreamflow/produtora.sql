use streamflow;

/*Listagens produtoras*/
select * from produtoras;
select * from videos;
select * from videosprodutoras;
select * from filmes;
select * from series;
select * from temporadas;
select * from episodios;

/*Sequencia de inserts para colocar um filme no ar*/
insert into videos(titulo, duracao_segundos)
values("Rango", 6420);
insert into videosprodutoras(video_id, produtora_id)
values(1, 1);
insert into filmes(video_id)
values(1);

insert into videos(titulo, duracao_segundos)
values("Devoradores de Estrela", 9360);
insert into videosprodutoras(video_id, produtora_id)
values(2, 2);
insert into videosprodutoras(video_id, produtora_id)
values(2, 3);
insert into filmes(video_id)
values(2);

/*Adicionar uma série*/
insert into series(titulo)
values("JoJo no Kimyou na Bouken");

/*Adicionar temporadas*/
insert into temporadas(titulo, numero, serie_id)
values
("Phantom Blood / Battle Tendency", 1, 1),
("Stardust Crusaders", 2, 1);

/*Adicionar Episodios*/
insert into videos(titulo, duracao_segundos)
values
("Dio, o Invasor", 1440), ("Uma Carta do Passado", 1440),
("O Homem Possuído por um Espírito Maligno", 1440), ("Quem Será o Juiz?", 1440);
insert into videosprodutoras(video_id, produtora_id)
values
(3, 4), (4, 4),
(5, 4), (6, 4);
insert into episodios(numero, video_id, temporada_id)
values
(1, 3, 1), (2, 4, 1),
(1, 5, 2), (2, 6, 2);

/*Desativar um vídeo*/
update videos set
ativo = 0
where id = 5;

/*Ativar um vídeo*/
update videos set
ativo = 1
where id = 5;