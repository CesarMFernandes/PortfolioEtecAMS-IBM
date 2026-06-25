create database streamflow;
use streamflow;

drop database streamflow;
drop user 'app_streamflow'@'localhost';
drop user 'auditor_streamflow'@'localhost';
drop user 'produtora_streamflow'@'localhost';

create table assinantes(
	id int primary key auto_increment,
    nome varchar(50) not null, /*podem existir pessoas com o mesmo nome, por isso não usar unique*/
    cpf char(11) not null unique check(cpf not like '%[^0-9]%'), /*Usa char pois cpf tem um formato padrão + check pra ver se só tem número*/
    email varchar(100) not null unique check(email LIKE '%_@__%.__%'), /*chek para ver formato de email válido*/
    data_nascimento date not null,
    uf char(2) not null,
    saldo decimal(10, 2) not null default(0) check(saldo>=0), /*uso de decimal para prevenir erro de ponto flutuante, 0 por padrão pois o saldo é colocado depois da criação da conta, check para respeitar a regra de negócio*/
    data_cadastro date not null default(current_timestamp()),
    assinatura_ativa boolean not null default(0) /*status da assinatura, desativada por padrão até ser renovada*/
);

create table perfis(
	id int primary key auto_increment,
    nome_exibicao varchar(30) not null,
    ativo boolean not null default(1), /*Usuários apenas podem desativar perfis para não interferir com relatórios*/
    assinante_id int not null,
    foreign key (assinante_id) references assinantes(id) on delete restrict on update cascade /*Os dados devem sempre ser preservados com on delete restrict, usa-se on update cascade para poder rastrear a conta correta mesmo com a autalização de id*/
);

create table preferencias(
	id int primary key auto_increment,
    perfil_id int not null,
    preferencia enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário") not null,
    foreign key (perfil_id) references perfis(id) 
);

create table videos(
	id int primary key auto_increment,
    titulo varchar(50) not null,
    duracao_segundos int not null, /*usar o int pois é mais fácil somar, agregar e evita limitações do tipo time*/
    ativo boolean not null default(1) /*melhor alterar para "desativar" um vídeo do que deletar para caso ter informações necessárias para relatórios*/
);

create table filmes(
	id int primary key auto_increment,
	video_id int not null,
    foreign key (video_id) references videos(id) on delete restrict on update cascade /*Mesma lógica do perfil*/
);

create table series(
	id int primary key auto_increment,
	titulo varchar(50) not null
);

create table temporadas(
	id int primary key auto_increment,
	titulo varchar(50), /*pode ser null pois nem todas as temporadas tem um nome*/
    numero int not null,
    serie_id int not null,
    foreign key (serie_id) references series(id) on delete restrict on update cascade /*Mesma lógica do filme e do perfil*/
);

create table episodios(
	id int primary key auto_increment,
    numero int not null,
    video_id int not null,
    temporada_id int not null,
    foreign key (video_id) references videos(id) on delete restrict on update cascade, /*Mesma lógica do resto (mas raramente é aplicável pois as informações dos vídeos não podem ser deletadas normalmente)*/
    foreign key (temporada_id) references temporadas(id) on delete restrict on update cascade 
);

create table produtoras(
	id int primary key auto_increment,
    nome varchar(50) not null,
    pais varchar(30) not null
);

create table videosprodutoras(
	video_id int not null,
	produtora_id int not null,
    foreign key (video_id) references videos(id) on delete restrict on update cascade ,
    foreign key (produtora_id) references produtoras(id) on delete restrict on update cascade ,
    primary key(video_id, produtora_id)
);

create table generofilmes(
	id int primary key auto_increment,
    filme_id int not null,
    genero enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário") not null,
    foreign key (filme_id) references filmes(id) 
);

create table generoseries(
	id int primary key auto_increment,
    serie_id int not null,
    genero enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário") not null,
    foreign key (serie_id) references series(id) 
);

/*O histórico imutável de logs. Nessa tabela vai ser usado on delete restrict e nenhum usuário além do root poderá deletar ou alterar essa tabela*/
create table reproducoes( 
	id int primary key auto_increment,
    data_hora_inicio datetime not null default(current_timestamp()),
    ip varchar(15) not null,
    dispositivo enum('SmartTV', 'App Smartphone', 'App Tablet', 'App PC', 'Web', 'Geladeira Smart') not null,
    tempo_assistido_segundos int not null default(0), /*0 por padrão pois uma query é feita quando o vídeo começa a rodar. O registro é alterado depois quando o usuário para de assistir ou termina o vídeo*/
    concluido boolean not null default(0), /*0 por padrão pelo mesmo motivo*/
    perfil_id int not null,
    video_id int not null,
    foreign key (perfil_id) references perfis(id) on delete restrict on update cascade, 
    foreign key (video_id) references videos(id) on delete restrict on update cascade /*Usa-se on delete restrict pois o histórico deve ser imutável, porém usa-se on update cascade para não ter chance de confundir as produtoras quando calcular o pagamento*/
);

-- Procedures e indices para usuários
delimiter //
create procedure informacoes_assinantes(
	in id_dado int
)
begin
	select * from assinantes where id = id_dado;
end//
delimiter ;

delimiter //
create procedure criar_assinantes(
	in nome_dado varchar(50), 
	in cpf_dado varchar(11), 
	in email_dado varchar(100), 
	in data_nascimento_dado date, 
	in uf_dado char(2)
)
begin
	insert into assinantes(nome, cpf, email, data_nascimento, uf)
	values(nome_dado, cpf_dado, email_dado, data_nascimento_dado, uf_dado);
end//
delimiter ;

delimiter //
create procedure inserir_saldo(
	in id_dado int, 
	in saldo_dado decimal(10, 2)
)
begin
	update assinantes set saldo = saldo + saldo_dado where id = id_dado;
end//
delimiter ;

delimiter //
create procedure assinatura(
	in id_dado int
)
begin
	update assinantes set 
	assinatura_ativa = if(saldo>=10, 1, 0),
	saldo = if(saldo>=10, saldo-10, saldo)
	where id = id_dado;
end//
delimiter ;

delimiter //
create procedure atualizar_dados_assinantes(
	in id_dado int,
	in nome_dado varchar(50), 
	in cpf_dado varchar(11), 
	in email_dado varchar(100), 
	in data_nascimento_dado date, 
	in uf_dado char(2)
)
begin
	update assinantes set 
	nome = nome_dado,
	cpf = cpf_dado,
	email = email_dado,
	data_nascimento = data_nascimento_dado,
	uf = uf_dado
	where id = id_dado;
end//
delimiter ;

delimiter //
create procedure listar_perfis(
	in id_dado int
)
begin
	select * from perfis where assinante_id = id_dado and ativo = 1;
end//
delimiter ;

delimiter //
create procedure criar_perfis(
	in id_dado int,
    in nome_exibicao_dado varchar(30)
)
begin
	insert into perfis (nome_exibicao, assinante_id)
	select nome_exibicao_dado, id_dado
	where (SELECT count(*) FROM perfis WHERE assinante_id = id_dado and ativo = 1) <= 4 and 
	(select count(*) from perfis where assinante_id = id_dado and nome_exibicao like nome_exibicao_dado and ativo = 1) = 0; /*apenas faz o insert caso não tenha 5 perfis ou mais e caso não tenha nome duplicado*/
end//
delimiter ;

delimiter //
create procedure atualizar_perfis(
	in id_dado int,
    in nome_exibicao_dado varchar(30)
)
begin
	update perfis set
	nome_exibicao = if((select count(*) from perfis where assinante_id = id_dado and nome_exibicao like nome_exibicao_dado and ativo = 1) = 0, nome_exibicao_dado, nome_exibicao) /*apenas atualiza caso não gere nome duplicado*/
	where id = id_dado;
end//
delimiter ;

delimiter //
create procedure registrar_preferencias(
	in id_dado int,
    in preferencia_dada enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário")
)
begin
	insert into preferencias (perfil_id, preferencia)
	select id_dado, preferencia_dada
	where (select count(*) from preferencias where perfil_id = id_dado and preferencia like preferencia_dada) = 0;
end//
delimiter ;

delimiter //
create procedure listar_preferencias(
	in id_dado int
)
begin
	select * from preferencias where perfil_id = id_dado;
end//
delimiter ;

delimiter //
create procedure remover_preferencias(
	in id_dado int
)
begin
	delete from preferencias where id = id_dado;
end//
delimiter ;

delimiter //
create procedure desativar_perfis(
	in id_dado int
)
begin
	update perfis set 
	ativo = 0
	where id = id_dado;
end//
delimiter ;

delimiter //
create procedure listar_filmes(
	in id_dado int
)
begin
	select videos.id as Id_do_Vídeo, filmes.id as Id_do_Filme, videos.titulo as Título, sec_to_time(duracao_segundos) as Duracao_do_Filme
	from filmes
	inner join videos on filmes.video_id = videos.id
	inner join generofilmes on filmes.id = generofilmes.filme_id
	where videos.ativo = 1 and generofilmes.genero in (select preferencia from preferencias where perfil_id = id_dado);
end//
delimiter ;

delimiter //
create procedure listar_series(
	in id_dado int
)
begin
	select series.id as Id_da_Serie, series.titulo as Título, count(distinct temporadas.id) as Quantidade_de_Temporadas, count(episodios.id) as Quantidade_de_Episódios
	from series
	inner join generoseries on series.id = generoseries.serie_id
	inner join temporadas on series.id = temporadas.serie_id
	inner join episodios on temporadas.id = episodios.temporada_id
	inner join videos on episodios.video_id = videos.id 
	where videos.ativo = 1 and generoseries.genero in (select preferencia from preferencias where perfil_id = id_dado)
	having count(episodios.id) >= 1;
end//
delimiter ;

delimiter //
create procedure criar_relatorios(
	in ip_dado varchar(15),
    in dispositivo_dado enum('SmartTV', 'App Smartphone', 'App Tablet', 'App PC', 'Web', 'Geladeira Smart'),
    in perfil_id_dado int,
    in video_id_dado int
)
begin
	insert into reproducoes(ip, dispositivo, perfil_id, video_id)
	values(ip_dado, dispositivo_dado, perfil_id_dado, video_id_dado);
    
    select id from reproducoes where id = last_insert_id();
end//
delimiter ;

delimiter //
create procedure marcar_concluido(
	in perfil_id_dado int,
    in video_id_dado int
)
begin
	update reproducoes set
	concluido = 1
	where perfil_id = perfil_id_dado and video_id = video_id_dado;
end//
delimiter ;

delimiter //
create procedure atualizar_tempo_sessao(
	in id_dado int,
    in tempo_dado int
)
begin
	update reproducoes set
	tempo_assistido_segundos = tempo_dado
	where id = id_dado;
end//
delimiter ;

delimiter //
create procedure painel_continuar_assistindo(
	in id_dado int
)
begin
	select videos.titulo as Vídeo, reproducoes.data_hora_inicio as Última_Visualização
	from reproducoes
	inner join videos on reproducoes.video_id = videos.id
	inner join perfis on reproducoes.perfil_id = perfis.id
	where perfis.id = id_dado and reproducoes.concluido = 0 and videos.ativo = 1
	group by videos.id
	order by Última_Visualização desc;
end//
delimiter ;

CREATE INDEX idx_perfis_assinante_ativo_nome ON perfis (assinante_id, ativo, nome_exibicao);
CREATE INDEX idx_preferencias_perfil_genero ON preferencias (perfil_id, preferencia);
CREATE INDEX idx_generofilmes_genero ON generofilmes (genero);
CREATE INDEX idx_generoseries_genero ON generoseries (genero);
CREATE INDEX idx_reproducoes_perfil_video_concluido ON reproducoes (perfil_id, video_id, concluido);
CREATE INDEX idx_temporadas_serie ON temporadas (serie_id);
CREATE INDEX idx_episodios_temporada ON episodios (temporada_id);

-- Procedures para produtoras
delimiter //
create procedure adicionar_filmes(
    in titulo_dado varchar(50),
    in duracao_dada int
)
begin
	insert into videos(titulo, duracao_segundos)
	values(titulo_dado, duracao_dada);
    
	insert into filmes(video_id)
	values(LAST_INSERT_ID());
end//
delimiter ;

delimiter //
create procedure colocar_generos_filmes(
    in filme_id_dado int,
    in genero_dado enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário")
)
	begin
		insert into generofilmes(filme_id, genero)
		values(filme_id_dado, genero_dado);
	end//
delimiter ;

delimiter //
create procedure colocar_produtoras(
    in video_id_dado int,
    in produtora_id_dado int
)
begin
	insert into videosprodutoras(video_id, produtora_id)
	values(video_id_dado, produtora_id_dado);
end//
delimiter ;

delimiter //
create procedure adicionar_series(
    in titulo_dado varchar(50)
)
begin
	insert into series(titulo)
	values(titulo_dado);
	end//
delimiter ;

delimiter //
create procedure colocar_generos_series(
    in serie_id_dado int,
    in genero_dado enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário")
)
	begin
		insert into generoseries(serie_id, genero)
		values(serie_id_dado, genero_dado);
	end//
delimiter ;

delimiter //
create procedure adicionar_temporadas(
    in titulo_dado varchar(50),
    in numero_dado int,
    in serie_id_dado int
)
begin
	insert into temporadas(titulo, numero, serie_id)
	values
	(titulo_dado, numero_dado, serie_id_dado);
end//
delimiter ;

delimiter //
create procedure adicionar_episodios(
    in titulo_dado varchar(50),
    in duracao_dada int,
    in numero_dado int,
    in id_temporada_dada int
)
begin
	insert into videos(titulo, duracao_segundos)
	values
	(titulo_dado, duracao_dada);
    
	insert into episodios(numero, video_id, temporada_id)
	values
	(numero_dado, LAST_INSERT_ID(), id_temporada_dada);
end//
delimiter ;

delimiter //
create procedure status_videos(
    in id_dado int
)
begin
	update videos set
	ativo = if(ativo = 1, 0, 1)
	where id = id_dado;
end//
delimiter ;

/*Views e indices para a auditoria*/
CREATE OR REPLACE VIEW cobranca_estudios AS 
select produtoras.nome as Produtora, sum(reproducoes.tempo_assistido_segundos) / 60 as Tempo_Assistido_Minutos
from produtoras
inner join videosprodutoras on produtoras.id = videosprodutoras.produtora_id
inner join videos on videosprodutoras.video_id = videos.id
inner join reproducoes on videos.id = reproducoes.video_id 
where reproducoes.data_hora_inicio >= DATE_FORMAT(current_timestamp(), '%Y-%m-01 00:00:00')
group by produtoras.id
having Tempo_Assistido_Minutos / 60 > 5000;

create or replace view trafego_regiao as
select assinantes.uf as UF, reproducoes.dispositivo as Dispositivo, count(reproducoes.id) as Quantidade_de_Reproduções
from assinantes
inner join perfis on assinantes.id = perfis.assinante_id
inner join reproducoes on perfis.id = reproducoes.perfil_id
group by UF, Dispositivo;

create or replace view metricas_engajamento_LGPD as
SELECT 
	CONCAT(assinantes.id) AS Id_do_Usuário,
    TIMESTAMPDIFF(YEAR, assinantes.data_nascimento, CURDATE()) AS Idade,
    sec_to_time(sum(reproducoes.tempo_assistido_segundos)) as Tempo_Assistindo,
    count(reproducoes.id) as Número_de_Acessos,
    preferencias.preferencia as Preferências
FROM assinantes
inner join perfis on assinantes.id = perfis.assinante_id
inner join reproducoes on perfis.id = reproducoes.perfil_id
inner join preferencias on perfis.id = preferencias.perfil_id
group by preferencias.id
order by sum(reproducoes.tempo_assistido_segundos) desc;

CREATE INDEX idx_reproducoes_video_data ON reproducoes(video_id, data_hora_inicio);
CREATE INDEX idx_reproducoes_perfil_dispositivo ON reproducoes(dispositivo);
CREATE INDEX idx_vid_prod ON videosprodutoras(video_id, produtora_id);
CREATE INDEX idx_assinantes_uf ON assinantes(uf);

/*Procedures e indices gerais*/
delimiter //
create procedure filmes_por_nome(
    in titulo_dado varchar(50)
)
begin
	select videos.id as Id_do_Vídeo, filmes.id as Id_do_Filme, videos.titulo as Título, videos.duracao_segundos as Duração_do_Filme
    from filmes 
    inner join videos on filmes.video_id = videos.id
    where videos.titulo like concat('%',titulo_dado,'%') and videos.ativo = 1;
end//
delimiter ;

delimiter //
create procedure series_por_nome(
    in titulo_dado varchar(50)
)
begin
	select series.id as Id_da_Série, series.titulo as Título, count(distinct temporadas.id) as Quantidade_de_Temporadas, count(episodios.id) as Quantidade_de_Episódios
	from series
	inner join temporadas on series.id = temporadas.serie_id
	inner join episodios on temporadas.id = episodios.temporada_id
	inner join videos on episodios.video_id = videos.id 
	where videos.ativo = 1 and series.titulo like concat('%', titulo_dado,'%') 
    having count(episodios.id) >= 1;
	
end//
delimiter ;

delimiter //
create procedure produtoras_por_nome(
    in nome_dado varchar(50)
)
begin
	select * from produtoras where nome like concat('%',nome_dado,'%');
end//
delimiter ;

delimiter //
create procedure videos_de_produtoras(
    in id_dado int
)
begin
	select videos.id as Id_do_Vídeo, videos.titulo as Título, produtoras.nome as Nome_da_Produtora
    from videosprodutoras
    inner join videos on videosprodutoras.video_id = videos.id
    inner join produtoras on videosprodutoras.produtora_id = produtoras.id
    where videos.ativo = 1 and produtoras.id = id_dado;
end//
delimiter ;

delimiter //
create procedure listar_generos_filmes(
	in id_dado int
)
begin
	select videos.id as Id_do_Vídeo, filmes.id as Id_do_Filme, videos.titulo as Título, generofilmes.genero as Gênero
	from filmes
	inner join videos on filmes.video_id = videos.id
	inner join generofilmes on filmes.id = generofilmes.filme_id
	where filmes.id = id_dado;
end//
delimiter ;

delimiter //
create procedure listar_produtoras_videos(
	in id_dado int
)
begin
	select videos.id as Id_do_Vídeo, videos.titulo as Título, produtoras.nome as Produtora_do_Vídeo
	from videos
	inner join videosprodutoras on videos.id = videosprodutoras.video_id
	inner join produtoras on videosprodutoras.produtora_id = produtoras.id
	where videos.id = id_dado;
end//
delimiter ;

delimiter //
create procedure listar_temporadas(
	in id_dado int
)
begin
	select series.id as Id_da_Série, series.titulo as Série, temporadas.id as Id_da_Temporada,temporadas.titulo as Título_da_Temporada, temporadas.numero as Número_da_temporada, count(episodios.id) as Número_de_Episódios
	from series
	inner join temporadas on series.id = temporadas.serie_id
	inner join episodios on temporadas.id = episodios.temporada_id
	inner join videos on episodios.video_id = videos.id
	where videos.ativo = 1 and series.id = id_dado
    group by temporadas.id
	order by Número_da_Temporada;
end//
delimiter ;

delimiter //
create procedure listar_episodios(
	in id_dado int
)
begin
	select series.id as Id_da_Série, series.titulo as Série, temporadas.titulo as Título_da_Temporada, temporadas.numero as Número_da_temporada, videos.id as Id_do_Vídeo, videos.titulo as Título_do_Episódio, episodios.numero as Número_do_Episódio, sec_to_time(duracao_segundos) as Duração
	from series
	inner join temporadas on series.id = temporadas.serie_id
	inner join episodios on temporadas.id = episodios.temporada_id
	inner join videos on episodios.video_id = videos.id
	where videos.ativo = 1 and temporadas.id = id_dado
	order by Número_da_Temporada, Número_do_Episódio;
end//
delimiter ;

delimiter //
create procedure listar_generos_series(
	in id_dado int
)
begin
	select series.titulo as Título, generoseries.genero as Gênero
	from series
	inner join generoseries on series.id = generoseries.serie_id
	where series.id = id_dado;
end//
delimiter ;

CREATE INDEX idx_videos_titulo ON videos(titulo);
CREATE INDEX idx_series_titulo ON series(titulo);
CREATE INDEX idx_produtoras_nome ON produtoras(nome);



/*Sistema do app/site da streamflow. Inclui ações do usuário + geração automática de relatórios*/
create user 'app_streamflow'@'localhost' identified by 'SenhaApp#123';

grant execute on procedure streamflow.informacoes_assinantes to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.criar_assinantes to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.inserir_saldo to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.assinatura to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.atualizar_dados_assinantes to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_perfis to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.criar_perfis to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.atualizar_perfis to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.registrar_preferencias to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_preferencias to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.remover_preferencias to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.desativar_perfis to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_filmes to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_series to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.criar_relatorios to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.marcar_concluido to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.atualizar_tempo_sessao to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.painel_continuar_assistindo to 'app_streamflow'@'localhost';

grant execute on procedure streamflow.filmes_por_nome to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.series_por_nome to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.produtoras_por_nome to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.videos_de_produtoras to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_generos_filmes to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_generos_series to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_episodios to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_produtoras_videos to 'app_streamflow'@'localhost';
grant execute on procedure streamflow.listar_temporadas to 'app_streamflow'@'localhost';

/*Sistema usado pelos auditores (equipe de marketing e analistas)*/
create user 'auditor_streamflow'@'localhost' identified by 'SenhaAuditor#123';

grant select on cobranca_estudios to 'auditor_streamflow'@'localhost';
grant select on trafego_regiao to 'auditor_streamflow'@'localhost';
grant select on metricas_engajamento_LGPD to 'auditor_streamflow'@'localhost';

grant execute on procedure streamflow.filmes_por_nome to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.series_por_nome to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.produtoras_por_nome to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.videos_de_produtoras to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.listar_generos_filmes to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.listar_generos_series to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.listar_episodios to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.listar_produtoras_videos to 'auditor_streamflow'@'localhost';
grant execute on procedure streamflow.listar_temporadas to 'auditor_streamflow'@'localhost';

/*Sistema usado pelas produtoras para lançar filmes e séries*/
create user 'produtora_streamflow'@'localhost' identified by 'SenhaProdutora#123';

grant execute on procedure streamflow.adicionar_filmes to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.colocar_generos_filmes to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.adicionar_series to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.colocar_generos_series to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.adicionar_temporadas to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.adicionar_episodios to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.colocar_produtoras to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.status_videos to 'produtora_streamflow'@'localhost';

grant execute on procedure streamflow.filmes_por_nome to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.series_por_nome to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.produtoras_por_nome to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.videos_de_produtoras to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.listar_generos_filmes to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.listar_generos_series to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.listar_episodios to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.listar_produtoras_videos to 'produtora_streamflow'@'localhost';
grant execute on procedure streamflow.listar_temporadas to 'produtora_streamflow'@'localhost';

insert into produtoras(nome, pais)
values
("Lord Miller Productions", "Estados Unidos"), ("Amazon MGM Studios", "Estados Unidos"),
("A24", "Estados Unidos"),
("David Production", "Japão");