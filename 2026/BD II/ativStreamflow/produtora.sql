use streamflow;

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

/*Listar temporadas e episódios de uma série*/
call listar_episodios(1); -- id da série

/*Listar produtoras de um vídeo*/
call listar_produtoras_videos(1); -- id da produtora



/*Sequencia de inserts para colocar um filme no ar*/
call adicionar_filmes("Devoradores de Estrelas", 9360);
call adicionar_filmes("Backrooms, Um Não-Lugar", 6600);

/*Colocar gêneros de um filme*/
call colocar_generos_filmes(1, "Ficção Científica");
call colocar_generos_filmes(1, "Drama");
call colocar_generos_filmes(2, "Terror");

/*Adicionar uma série*/
call adicionar_series("JoJo no Kimyou na Bouken");

/*Colocar gêneros de uma série*/
call colocar_generos_series(1, "Ação");
call colocar_generos_series(1, "Comédia");

/*Adicionar temporadas*/
call adicionar_temporadas("Phantom Blood / Battle Tendency", 1, 1);
call adicionar_temporadas("Stardust Crusaders", 2, 1);

/*Adicionar Episodios*/
call adicionar_episodios("Dio, o Invasor", 1440, 1, 1);
call adicionar_episodios("Uma Carta do Passado", 1440, 2, 1);
call adicionar_episodios("O Homem Possuído por um Espírito Maligno", 1440, 1, 2);
call adicionar_episodios("Quem Será o Juiz?", 1440, 2, 2);

/*Colocar produtora(s) de um vídeo*/
call colocar_produtoras(1, 1);
call colocar_produtoras(1, 2);

call colocar_produtoras(2, 3);

call colocar_produtoras(3, 4);
call colocar_produtoras(4, 4);
call colocar_produtoras(5, 4);
call colocar_produtoras(6, 4);

/*Desativar / Ativar um vídeo*/
call status_videos(1);
