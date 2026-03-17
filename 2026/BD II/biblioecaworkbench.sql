create database biblioteca;
use biblioteca;

create table usuarios(
	id int auto_increment primary key,
    nome varchar(100) not null,
    email varchar(100) not null unique
);

create table autores(
	id int auto_increment primary key,
    nome varchar(100) not null
);

create table categorias(
	id int auto_increment primary key,
    nome varchar(100) not null
);

create table emprestimo(
	id int auto_increment primary key,
    id_usuario int not null,
    data_saida date not null,
    data_prevista date not null,
    data_entrega date,
    constraint fk_emprestimo_usuario foreign key(id_usuario) references usuarios(id)
);

create table livros(
	id int auto_increment primary key,
    titulo varchar(150) not null,
    isbn varchar(20) unique
);

create table emprestimo_livros(
	id_livro int not null,
    id_emprestimo int not null,
    primary key(id_livro, id_emprestimo),
    foreign key(id_livro) references livros(id),
    foreign key(id_emprestimo) references emprestimo(id),
);