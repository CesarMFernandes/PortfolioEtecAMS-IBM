use streamflow;

/*Ver dados da sua conta*/
call informacoes_assinantes(1); -- id do assinante

/*Criar conta*/
call criar_assinantes("Fulano da Silva", "12312312312", "silva.fulano@gmail.com", "2001-02-23", "SP"); -- nome, cpf, email, data de nascimento, UF

/*Inserir saldo*/
call inserir_saldo(1, 10.00); -- id do assinante, saldo a ser acrescentado

/*Renovar assinatura / Cobrança de assinatura*/
call assinatura(1); -- id do assinante

/*Atualizar dados*/
call atualizar_dados_assinantes(1, "Ciclano de Souza", "45645645645", "souza.ciclano@outlook.net", "1994-11-09", "RJ"); -- id do assinante, nome, cpf, email, data de nascimento, UF



/*Ver perfis da sua conta*/
call listar_perfis(1); -- id do assinante

/*Criar perfil*/
call criar_perfis(1, "filho"); -- id do assinante, nome do perfil

/*Atualizar nome de perfil*/
call atualizar_perfis(1, "pai"); -- id do perfil, nome do perfil

/*Adicionar preferência ao perfil*/
call registrar_preferencias(1, "Ação"); -- id do perfil, preferência
call registrar_preferencias(1, "Terror");

/*Desativar perfil*/
call desativar_perfis(1); -- id do perfil



/*Listar filmes por nome*/
call filmes_por_nome("Backrooms"); -- título

/*Listar séries por nome*/
call series_por_nome("Jojo"); -- título

/*Listar produtoras por nome*/
call produtoras_por_nome("Amazon"); -- nome da produtora

/*Ver episódios e filmes feitos por uma produtora*/
call videos_de_produtoras(1); -- id da produtora

/*Listar catálogo de filmes baseado nas preferências do perfil*/
call listar_filmes(1); -- id do perfil

/*Listar generos de um filme*/
call listar_generos_filmes(1); -- id do filme

/*Listar catálogo de séries*/
call listar_series(1); -- id do perfil

/*Listar generos de uma série*/
call listar_generos_series(1); -- id da série

/*Listar temporadas e episódios de uma série*/
call listar_episodios(1); -- id da série

/*Listar produtoras de um vídeo*/
call listar_produtoras_videos(1); -- id do vídeo

/*Criação de relatório ao clicar em play*/
call criar_relatorios("123.12.123.12", "Web", 1, 2); -- ip, dispositivo, id perfil, id vídeo

/*Marca todos os registros como concluído de um vídeo e perfil caso o perfil tenha terminado o vídeo*/
call marcar_concluido(1, 2); -- id perfil, id vídeo

/*Atualiza o tempo assistido de um relatório específico após o fim da sessão*/
call atualizar_tempo_sessao(1, 10000); -- id relatório, duração da sessão

/*Painel de Tela Inicial (Continuar Assistindo)*/
call painel_continuar_assistindo(1); -- id do perfil