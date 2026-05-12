create database mercado;
use mercado;

CREATE TABLE vendedores (
    id INT PRIMARY KEY,
    nome_vendedor VARCHAR(50),
    salario_fixo DECIMAL(10,2)
);

CREATE TABLE clientes (
    id INT PRIMARY KEY,
    nome_cliente VARCHAR(50),
    cidade VARCHAR(30),
    uf CHAR(2)
);

CREATE TABLE produtos (
    id INT PRIMARY KEY,
    descricao VARCHAR(50),
    unidade VARCHAR(5), -- Ajustado para suportar 'SACH'
    valor_unitario DECIMAL(10,2)
);

CREATE TABLE pedidos (
    id INT PRIMARY KEY,
    id_cliente INT,
    id_vendedor INT,
    prazo_entrega INT,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id),
    FOREIGN KEY (id_vendedor) REFERENCES vendedores(id)
);

CREATE TABLE itens_pedidos (
    id_pedido INT,
    id_produto INT,
    quantidade INT,
    PRIMARY KEY (id_pedido, id_produto),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id),
    FOREIGN KEY (id_produto) REFERENCES produtos(id)
);

INSERT INTO vendedores (id, nome_vendedor, salario_fixo) VALUES 
(1, 'Carlos', 2500), (2, 'Felipe', 4000), (3, 'Maurício', 3000), (4, 'Ana', 3500),
(5, 'Ricardo', 3200), (6, 'Beatriz', 4100), (7, 'Marcos', 2800), (8, 'Juliana', 3500),
(9, 'Roberto', 2200), (10, 'Fernanda', 5000), (11, 'Paula', 3100), (12, 'Lucas', 2750);

INSERT INTO clientes (id, nome_cliente, cidade, uf) VALUES 
(10, 'Rodolfo', 'Rio de Janeiro', 'RJ'), (20, 'Beth', 'São Paulo', 'SP'), 
(30, 'Lívio', 'São Paulo', 'SP'), (40, 'Susana', 'Rio de Janeiro', 'RJ'),
(50, 'Anderson', 'Curitiba', 'PR'), (60, 'Tatiana', 'Fortaleza', 'CE'),
(70, 'Gustavo', 'Belo Horizonte', 'MG'), (80, 'Carla', 'São Paulo', 'SP'),
(90, 'Henrique', 'Porto Alegre', 'RS'), (100, 'Marta', 'Salvador', 'BA'),
(110, 'Otávio', 'Manaus', 'AM'), (120, 'Renata', 'Rio de Janeiro', 'RJ'),
(130, 'Hugo', 'Vitória', 'ES'), (140, 'Patrícia', 'Campinas', 'SP'),
(150, 'Sérgio', 'Curitiba', 'PR');

INSERT INTO produtos (id, descricao, unidade, valor_unitario) VALUES 
(101, 'Queijo', 'Kg', 10.00), (102, 'Chocolate', 'BAR', 5.00), 
(103, 'Vinho', 'L', 20.00), (104, 'Linha', 'M', 2.00),
(105, 'Azeite', 'L', 25.50), (106, 'Arroz', 'Kg', 5.40), 
(107, 'Feijão', 'Kg', 7.20), (108, 'Macarrão', 'PCT', 3.15),
(109, 'Molho', 'SACH', 2.80), (110, 'Leite', 'L', 4.90),
(111, 'Sabão', 'Kg', 12.00), (112, 'Detergente', 'UN', 1.99);

INSERT INTO pedidos (id, id_cliente, id_vendedor, prazo_entrega) VALUES 
(501, 10, 1, 5), (502, 20, 1, 10), (503, 30, 2, 7), (504, 40, 4, 15),
(505, 50, 5, 15), (506, 60, 6, 20), (507, 70, 7, 5), (508, 80, 8, 10),
(509, 10, 5, 12), (510, 20, 10, 30), (511, 100, 11, 15), (512, 120, 12, 7),
(513, 140, 5, 10), (514, 50, 6, 25);

INSERT INTO itens_pedidos (id_pedido, id_produto, quantidade) VALUES 
(501, 101, 2), (501, 102, 5), (502, 103, 1), (503, 101, 10), (504, 102, 20),
(505, 105, 2), (505, 106, 5), (506, 110, 10), (507, 108, 3), (508, 109, 15),
(509, 101, 1), (509, 105, 2), (510, 103, 5), (511, 106, 20), (512, 107, 10),
(513, 102, 15), (514, 108, 10), (501, 103, 1), (502, 101, 2), (505, 107, 4),
(510, 102, 2), (511, 105, 1);

select pedidos.id, clientes.nome_cliente, vendedores.nome_vendedor, produtos.descricao, itens_pedidos.quantidade

