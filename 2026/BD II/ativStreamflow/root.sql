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

/*Views para a auditoria*/
CREATE OR REPLACE VIEW cobranca_estudios AS 
select produtoras.nome as Produtora, sum(reproducoes.tempo_assistido_segundos) / 60 as Tempo_Assistido_Minutos
from produtoras
inner join videosprodutoras on produtoras.id = videosprodutoras.produtora_id
inner join videos on videosprodutoras.video_id = videos.id
inner join reproducoes on videos.id = reproducoes.video_id 
where reproducoes.data_hora_inicio >= DATE_FORMAT(current_timestamp(), '%Y-%m-01 00:00:00') AND reproducoes.data_hora_inicio < current_timestamp()
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
    assinantes.id, 
    SUBSTRING_INDEX(assinantes.nome, ' ', 1) AS Primeiro_Nome,
    CONCAT('*********',right(assinantes.cpf,2)) AS cpf,
    CONCAT(LEFT(assinantes.email, 1), '***@', SUBSTRING_INDEX(assinantes.email, '@', -1)) AS Email,
    TIMESTAMPDIFF(YEAR, assinantes.data_nascimento, CURDATE()) AS Idade,
    count(reproducoes.id) as Quantidade_de_Visualizações,
    sum(reproducoes.tempo_assistido_segundos) as Tempo_Assistindo,
    count(reproducoes.id) as Número_de_Acessos
FROM assinantes
inner join perfis on assinantes.id = perfis.assinante_id
inner join reproducoes on perfis.id = reproducoes.perfil_id
group by assinantes.id
order by sum(reproducoes.tempo_assistido_segundos) desc;

/*Sistema do app/site da streamflow. Inclui ações do usuário + geração automática de relatórios*/
create user 'app_streamflow'@'localhost' identified by 'SenhaApp#123';

grant select on streamflow.assinantes to 'app_streamflow'@'localhost';
grant insert(nome, cpf, email, data_nascimento, uf) on streamflow.assinantes to 'app_streamflow'@'localhost';
grant update(nome, cpf, email, data_nascimento, uf, saldo, assinatura_ativa) on streamflow.assinantes to 'app_streamflow'@'localhost';

grant select on streamflow.perfis to 'app_streamflow'@'localhost';
grant insert(nome_exibicao, assinante_id) on streamflow.perfis to 'app_streamflow'@'localhost';
grant update(nome_exibicao, ativo) on streamflow.perfis to 'app_streamflow'@'localhost';

grant select on streamflow.videos to 'app_streamflow'@'localhost';
grant select on streamflow.filmes to 'app_streamflow'@'localhost';
grant select on streamflow.series to 'app_streamflow'@'localhost';
grant select on streamflow.temporadas to 'app_streamflow'@'localhost';
grant select on streamflow.episodios to 'app_streamflow'@'localhost';
grant select on streamflow.produtoras to 'app_streamflow'@'localhost';
grant select on streamflow.videosprodutoras to 'app_streamflow'@'localhost';

grant select(id, perfil_id, video_id, data_hora_inicio, concluido) on streamflow.reproducoes to 'app_streamflow'@'localhost'; /*O app precisará do id, id de perfil e id do vídeo para que a sessão atualize o relatório*/
grant insert(ip, dispositivo, perfil_id, video_id) on streamflow.reproducoes to 'app_streamflow'@'localhost';
grant update(tempo_assistido_segundos, concluido) on streamflow.reproducoes to 'app_streamflow'@'localhost';

/*Sistema usado pelos auditores (equipe de marketing e analistas)*/
create user 'auditor_streamflow'@'localhost' identified by 'SenhaAuditor#123';

grant select on cobranca_estudios to 'auditor_streamflow'@'localhost';
grant select on trafego_regiao to 'auditor_streamflow'@'localhost';
grant select on metricas_engajamento_LGPD to 'auditor_streamflow'@'localhost';

/*Sistema usado pelas produtoras para lançar filmes e séries*/
create user 'produtora_streamflow'@'localhost' identified by 'SenhaProdutora#123';

grant select on streamflow.videos to 'produtora_streamflow'@'localhost';
grant insert(titulo, duracao_segundos) on streamflow.videos to 'produtora_streamflow'@'localhost';
grant update(ativo) on streamflow.videos to 'produtora_streamflow'@'localhost';

grant select on streamflow.filmes to 'produtora_streamflow'@'localhost';
grant insert(video_id) on streamflow.filmes to 'produtora_streamflow'@'localhost';

grant select on streamflow.series to 'produtora_streamflow'@'localhost';
grant insert(titulo) on streamflow.series to 'produtora_streamflow'@'localhost';

grant select on streamflow.temporadas to 'produtora_streamflow'@'localhost';
grant insert(titulo, numero, serie_id) on streamflow.temporadas to 'produtora_streamflow'@'localhost';

grant select on streamflow.episodios to 'produtora_streamflow'@'localhost';
grant insert(numero, video_id, temporada_id) on streamflow.episodios to 'produtora_streamflow'@'localhost';

grant select on streamflow.produtoras to 'produtora_streamflow'@'localhost';

grant select on streamflow.videosprodutoras to 'produtora_streamflow'@'localhost';
grant insert on streamflow.videosprodutoras to 'produtora_streamflow'@'localhost';

insert into produtoras(nome, pais)
values
("Paramount", "Estados Unidos"), ("Lord Miller Productions", "Estados Unidos"), ("Amazon MGM Studios", "Estados Unidos"),
("David Production", "Japão");

select * from reproducoes;