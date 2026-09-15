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
    data_cadastro date not null default(current_timestamp())
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

/*Mostra quantos minutos cada produtora atingiu em seus vídeos. Necessário para calcular faturamento*/
create table faturamento_produtoras( 
	id int primary key auto_increment,
    produtora_id int not null,
    competencia date not null,
    minutos_consumidos int not null,
    foreign key (produtora_id) references produtoras(id) on delete restrict on update cascade
);

/*Cria um registro para cada query sql*/
create table auditoria_log( 
	id int primary key auto_increment,
    tabela varchar(30) not null,
    operacao varchar(10) not null,
    usuario varchar(30) not null,
    valor_antigo varchar(100),
    valor_novo varchar(100),
    data_hora datetime not null default(current_timestamp())
);

/*Mostra quantas reproduções foram feitas em um vídeo*/
create table resumo_reproducao( 
	id int primary key auto_increment,
    total_acessos int,
    video_id int,
    foreign key (video_id) references videos(id) on delete restrict on update cascade
);

-- Triggers e Handlers
DELIMITER //

CREATE TRIGGER verificar_saldo
BEFORE UPDATE ON assinantes
FOR EACH ROW
BEGIN
IF NEW.saldo < 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Saldo insuficiente';
END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER verificar_perfil_insert
BEFORE INSERT ON perfis
FOR EACH ROW
BEGIN
-- Verifica se o assinante já possui 5 perfis ativos
IF (SELECT COUNT(*) FROM perfis WHERE assinante_id = NEW.assinante_id AND ativo = 1) >= 5 THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'O assinante já possui o limite de 5 perfis ativos';
END IF;

-- Verifica se já existe um perfil com o mesmo nome
IF (SELECT COUNT(*) FROM perfis WHERE assinante_id = NEW.assinante_id AND nome_exibicao = NEW.nome_exibicao AND ativo = 1) > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Já existe um perfil com esse nome para este assinante';
END IF;


END //

CREATE TRIGGER verificar_perfil_update
BEFORE UPDATE ON perfis
FOR EACH ROW
BEGIN
-- Verifica se o novo nome já pertence a outro perfil
IF (
SELECT COUNT(*)
FROM perfis
WHERE assinante_id = NEW.assinante_id
AND nome_exibicao = NEW.nome_exibicao
AND ativo = 1
AND id <> OLD.id
) > 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Já existe outro perfil com esse nome para este assinante';
END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER verificar_preferencia
BEFORE INSERT ON preferencias
FOR EACH ROW
BEGIN
IF (SELECT COUNT(*) FROM preferencias WHERE perfil_id = NEW.perfil_id AND preferencia = NEW.preferencia) > 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Esta preferência já foi cadastrada para este perfil';
END IF;
END //

DELIMITER ;



-- Procedures e indices para usuários
delimiter //
create procedure criar_auditoria_log(
	in id_dado int,
    in tabela_dada varchar(30),
    in operacao_dada varchar(30),
    in usuario_dado varchar(30),
    in valor_antigo varchar(100),
    in valor_atual varchar(100),
    in data_hora datetime
)
begin
	insert into auditoria(tabela, operacao, usuario, valor_antigo, valor_novo, data_hora)
    values(tabela_dada, operacao_dada, usuario_dado, valor_antigo_dado, valor_atual_dado, data_hora_dada);
end//
delimiter ;

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
    call criar_auditoria_log("assinantes", "insert", current_user(), null, nome_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure inserir_saldo(
	in id_dado int, 
	in saldo_dado decimal(10, 2)
)
begin
	declare v_saldo int;
    select saldo into v_saldo from assinantes where id = id_dado;
    set novo_saldo = v_saldo + saldo_dado;
	update assinantes set saldo = novo_saldo where id = id_dado;
    call criar_auditoria_log("assinantes", "update", current_user(), v_saldo, novo_saldo, current_timestamp());
end//
delimiter ;

delimiter //
create procedure assinatura(
	in id_dado int,
    in valor_mensalidade_dado int,
    out novo_saldo decimal(10, 2)
)
begin
	declare v_saldo decimal(10, 2);
    
    -- Buscar saldo
    select saldo
    into v_saldo
    from assinantes
    where id = id_dado;
    
    -- Atualizar saldo
	update assinantes set
	saldo = saldo - valor_mensalidade_dado
	where id = id_dado;
	set novo_saldo = v_saldo - valor_mensalidade_dado;
    call criar_auditoria_log("assinantes", "update", current_user(), v_saldo, novo_saldo, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_nome_assinantes(
	in id_dado int,
	in nome_dado varchar(50)
)
begin
	declare v_nome varchar(50);
    select nome into v_nome from assinantes where id = id_dado;
	
	update assinantes set 
	nome = nome_dado
	where id = id_dado;
    
    call criar_auditoria_log("assinantes", "update", current_user(), v_nome, nome_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_cpf_assinantes(
	in id_dado int,
	in cpf_dado varchar(11)
)
begin
	declare v_cpf varchar(11);
    select cpf into v_cpf from assinantes where id = id_dado;
	
	update assinantes set 
	cpf = cpf_dado
	where id = id_dado;
    
    call criar_auditoria_log("assinantes", "update", current_user(), v_cpf, cpf_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_email_assinantes(
	in id_dado int,
	in email_dado varchar(100)
)
begin
	declare v_email varchar(100);
    select email into v_email from assinantes where id = id_dado;
	
	update assinantes set 
	email = email_dado
	where id = id_dado;
    
    call criar_auditoria_log("assinantes", "update", current_user(), v_email, email_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_data_nascimento_assinantes(
	in id_dado int, 
	in data_nascimento_dado date
)
begin
	declare v_data_nascimento date;
    select data_nascimento into v_data_nascimento from assinantes where id = id_dado;
	
	update assinantes set 
	data_nascimento = data_nascimento_dado
	where id = id_dado;
    
    call criar_auditoria_log("assinantes", "update", current_user(), v_data_nascimento, data_nascimento_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_uf_assinantes(
	in id_dado int,
	in uf_dado char(2)
)
begin
	declare v_uf char(2);
    select uf into v_uf from assinantes where id = id_dado;
	
	update assinantes set 
	uf = uf_dado
	where id = id_dado;
    
    call criar_auditoria_log("assinantes", "update", current_user(), v_uf, uf_dado, current_timestamp());
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
	insert into perfis(nome_exibicao, assinante_id)
	values(nome_exibicao_dado, id_dado);
    
    call criar_auditoria_log("perfis", "insert", current_user(), null, nome_exibicao_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_perfis(
	in id_dado int,
    in nome_exibicao_dado varchar(30)
)
begin
	declare v_nome_exibicao varchar(30);
    select nome_exibicao into v_nome_exibicao from perfis where id = id_dado;

	update perfis set
	nome_exibicao = nome_dado
	where id = id_dado;
    
    call criar_auditoria_log("perfis", "insert", current_user(), v_nome_exibicao, nome_exibicao_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure registrar_preferencias(
	in id_dado int,
    in preferencia_dada enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário")
)
begin
	insert into preferencias(perfil_id, preferencia)
	values(id_dado, nome_exibicao_dado);
    
    call criar_auditoria_log("preferencias", "insert", current_user(), null, preferencia_dada, current_timestamp());
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
    call criar_auditoria_log("preferencias", "delete", current_user(), id_dado, null, current_timestamp());
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
    
    call criar_auditoria_log("perfis", "update", current_user(), 1, 0, current_timestamp());
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
create procedure registrar_reproducao(
	in ip_dado varchar(15),
    in dispositivo_dado enum('SmartTV', 'App Smartphone', 'App Tablet', 'App PC', 'Web', 'Geladeira Smart'),
    in perfil_id_dado int,
    in video_id_dado int
)
begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Erro ao registrar reprodução';
	END;
	
	start transaction;
	insert into reproducoes(ip, dispositivo, perfil_id, video_id)
	values(ip_dado, dispositivo_dado, perfil_id_dado, video_id_dado);
    
    select last_insert_id() as id;
    
    call criar_auditoria_log("reproducoes", "insert", current_user(), null, ip_dado, current_timestamp());
    commit;
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
    
    call criar_auditoria_log("reproducoes", "update", current_user(), 0, 1, current_timestamp());
end//
delimiter ;

delimiter //
create procedure atualizar_tempo_sessao(
	in id_dado int,
    in tempo_dado int
)
begin
	declare v_tempo int;
    select tempo_assistido_segundos into v_tempo from reproducoes where id = id_dado;

	update reproducoes set
	tempo_assistido_segundos = tempo_dado
	where id = id_dado;
    
    call criar_auditoria_log("reproducoes", "update", current_user(), v_tempo, tempo_dado, current_timestamp());
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
    
    call criar_auditoria_log("videos", "insert", current_user(), null, titulo_dado, current_timestamp());
    call criar_auditoria_log("filmes", "insert", current_user(), null, titulo_dado, current_timestamp());
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
        call criar_auditoria_log("generofilmes", "insert", current_user(), null, genero_dado, current_timestamp());
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
    call criar_auditoria_log("videosprodutoras", "insert", current_user(), null, produtora_id_dado, current_timestamp());
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
    call criar_auditoria_log("series", "insert", current_user(), null, titulo_dado, current_timestamp());
delimiter ;

delimiter //
create procedure colocar_generos_series(
    in serie_id_dado int,
    in genero_dado enum("Ação", "Comédia", "Drama", "Terror", "Ficção Científica", "Suspense", "Romance", "Fantasia", "Documentário")
)
	begin
		insert into generoseries(serie_id, genero)
		values(serie_id_dado, genero_dado);
        call criar_auditoria_log("generoseries", "insert", current_user(), null, genero_dado, current_timestamp());
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
    call criar_auditoria_log("temporadas", "insert", current_user(), null, titulo_dado, current_timestamp());
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
    
    call criar_auditoria_log("videos", "insert", current_user(), null, titulo_dado, current_timestamp());
    call criar_auditoria_log("episodios", "insert", current_user(), null, titulo_dado, current_timestamp());
end//
delimiter ;

delimiter //
create procedure status_videos(
    in id_dado int
)
begin
	declare status_velho boolean;
    declare status_novo boolean;
    
    select ativo into status_velho from videos where id = id_dado;

	update videos set
	ativo = if(ativo = 1, 0, 1)
	where id = id_dado;
    
    select ativo into status_novo from videos where id = id_dado;
    
    call criar_auditoria_log("videos", "insert", current_user(), status_velho, status_novo, current_timestamp());
end//
delimiter ;

/*Procedures, functions, cursors, views e indices para a auditoria*/
CREATE OR REPLACE VIEW cobranca_estudios AS 
select produtoras.nome as Produtora, sum(reproducoes.tempo_assistido_segundos) / 60 as Tempo_Assistido_Minutos
from produtoras
inner join videosprodutoras on produtoras.id = videosprodutoras.produtora_id
inner join videos on videosprodutoras.video_id = videos.id
inner join reproducoes on videos.id = reproducoes.video_id 
where reproducoes.data_hora_inicio >= DATE_FORMAT(current_timestamp(), '%Y-%m-01 00:00:00')
group by produtoras.id;

DELIMITER //

-- Faz select dos minutos consumidos de uma produtora especifica, em um intervalo de tempo especificado
CREATE FUNCTION minutos_assistidos_por_produtora(
    p_id_produtora INT,
    p_competencia DATE
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN

    DECLARE v_minutos DECIMAL(10,2);

    SELECT COALESCE(SUM(r.tempo_assistido_segundos) / 60, 0)
    INTO v_minutos
    FROM produtoras
    INNER JOIN videosprodutoras
        ON produtoras.id = videosprodutoras.produtora_id
    INNER JOIN videos 
        ON videosprodutoras.video_id = videos.id
    INNER JOIN reproducoes 
        ON videos.id = reproducoes.video_id
    WHERE produtoras.id = p_id_produtora
      AND reproducoes.data_hora_inicio >= p_competencia
      AND reproducoes.data_hora_inicio < DATE_ADD(p_competencia, INTERVAL 1 MONTH);

    RETURN v_minutos;

END //

DELIMITER ;

-- Usa um cursor para gerar registros de minutos assistindo, utilizando a function minutos_assistidos_por_produtora
DELIMITER //

CREATE PROCEDURE gerar_faturamento_mensal(
    IN p_competencia DATE
)
BEGIN
    DECLARE v_produtora_id INT;
    DECLARE v_minutos DECIMAL(10,2);
    DECLARE v_fim BOOLEAN DEFAULT FALSE;

    DECLARE cursor_produtoras CURSOR FOR
        SELECT id
        FROM produtoras;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_fim = TRUE;

    OPEN cursor_produtoras;

    loop_produtoras: LOOP

        FETCH cursor_produtoras INTO v_produtora_id;

        IF v_fim THEN
            LEAVE loop_produtoras;
        END IF;

        SET v_minutos = minutos_assistidos_por_produtora(v_produtora_id, p_competencia);

        INSERT INTO faturamento_produtoras (produtora_id, competencia, minutos_consumidos)
        VALUES (v_produtora_id, p_competencia, v_minutos)
        ON DUPLICATE KEY UPDATE minutos_consumidos = v_minutos;

    END LOOP;

    CLOSE cursor_produtoras;
END //

DELIMITER ;

create or replace view trafego_regiao as
select assinantes.uf as UF, reproducoes.dispositivo as Dispositivo, count(reproducoes.id) as Quantidade_de_Reproduções
from assinantes
inner join perfis on assinantes.id = perfis.assinante_id
inner join reproducoes on perfis.id = reproducoes.perfil_id
group by UF, Dispositivo;

create or replace view metricas_engajamento_LGPD as
SELECT 
	CONCAT(assinantes.id) AS Id_do_Usuário,
    calcular_idade(assinantes.data_nascimento) AS Idade,
    sec_to_time(sum(reproducoes.tempo_assistido_segundos)) as Tempo_Assistindo,
    count(reproducoes.id) as Número_de_Acessos,
    group_concat(distinct preferencias.preferencia separator ', ') as Preferências
FROM assinantes
inner join perfis on assinantes.id = perfis.assinante_id
inner join reproducoes on perfis.id = reproducoes.perfil_id
inner join preferencias on perfis.id = preferencias.perfil_id
group by assinantes.id, assinantes.data_nascimento
order by sum(reproducoes.tempo_assistido_segundos) desc;

DELIMITER //

CREATE FUNCTION calcular_idade(
    p_data_nascimento DATE
)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_data_nascimento, CURDATE());
END //

DELIMITER ;


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