create database barbearia;
use barbearia;

create table clientes(
	idCliente int primary key auto_increment,
	nome varchar(50) not null,
    telefone varchar(14) not null,
    email varchar(100) unique not null,
    dataCadastro datetime default current_timestamp
);

create table barbeiros(
	idBarbeiro int primary key auto_increment,
    nome varchar(50) not null,
    cpf varchar(11) unique not null
);

create table categorias(
	idCategoria int primary key auto_increment,
    nome varchar(20) not null
);

create table servicos(
	idServico int primary key auto_increment,
    nome varchar(30) not null,
    preco float not null CHECK (preco >= 0),
    categoria int not null,
    
    FOREIGN KEY (categoria) REFERENCES categorias(idCategoria)
);

create table agendamentos(
	idAgendamento int primary key auto_increment,
    cliente int not null,
	dataMarcada datetime not null,
    precoFinal float,
    
    FOREIGN KEY (cliente) REFERENCES Clientes(idCliente)
);

/*Um agendamento pode incluir múltiplos serviços, e vice-versa*/
create table servicos_agendamentos( 
	id_servicos_agendamentos int primary key auto_increment,
    idServico int not null,
    idAgendamento int not null,
    
    FOREIGN KEY (idServico) REFERENCES servicos(idServico),
    FOREIGN KEY (idAgendamento) REFERENCES agendamentos(idAgendamento)
);

/*Caso necessário, múltiplos barbeiros podem trabalhar em diferentes serviços de um único agendamento*/
create table barbeiros_agendamentos(
	id_barbeiros_agendamentos int primary key auto_increment,
    idBarbeiro int not null,
    idAgendamento int not null,
    
    FOREIGN KEY (idBarbeiro) REFERENCES barbeiros(idBarbeiro),
    FOREIGN KEY (idAgendamento) REFERENCES agendamentos(idAgendamento)
);

insert into clientes
values(null, "Cliente Teste", "+5511968290174", "clienteteste@barber.com", default);
select * from clientes;

insert into barbeiros
values(null, "Barbeiro Teste", "38796048619");
select * from barbeiros;

insert into categorias
values(null, "Categoria Teste");
insert into categorias
values(null, "Categoria Teste 2");
select * from categorias;

insert into servicos
values(null, "Serviço Teste", 39.99, 1);
insert into servicos
values(null, "Serviço Teste 2", 59.99, 2);
select * from servicos;

insert into agendamentos
values(null, 1, "2026-4-20 16:00:00", 80.00);
select * from agendamentos;

insert into servicos_agendamentos
values(null, 1, 1);
insert into servicos_agendamentos
values(null, 2, 1);
select * from servicos_agendamentos;

insert into barbeiros_agendamentos
values(null, 1, 1);
select * from barbeiros_agendamentos;
