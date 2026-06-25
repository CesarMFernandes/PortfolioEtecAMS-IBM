use streamflow;

-- Mostra o tempo total assistido de todos os vídeos produzidos por diferentes produtoras
select * from cobranca_estudios;

-- Mostra total de visualizações, agrupando por estado e dispositivo
select * from trafego_regiao;

-- Lista usuários e quantidade de visualizações, não mostrando informações sensíveis, como nome, email e cpf
select * from metricas_engajamento_LGPD;

/*Listar filmes por nome*/
call filmes_por_nome("Backrooms"); -- título

/*Listar séries por nome*/
call series_por_nome("Jojo"); -- título

/*Listar produtoras por nome*/
call produtoras_por_nome("Amazon"); -- nome da produtora

/*Ver episódios e filmes feitos por uma produtora*/
call videos_de_produtoras(1); -- id da produtora

/*Listar generos de um filme*/
call listar_generos_filmes(1); -- id do filme

/*Listar generos de uma série*/
call listar_generos_series(1); -- id da série

/*Listar temporadas de uma série*/
call listar_temporadas(1); -- id da série

/*Listar temporadas e episódios de uma série*/
call listar_episodios(1); -- id da série

/*Listar produtoras de um vídeo*/
call listar_produtoras_videos(1); -- id da produtora