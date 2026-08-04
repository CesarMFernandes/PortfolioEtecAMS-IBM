CREATE DATABASE vendamais_db;
USE vendamais_db;

CREATE TABLE vendedores (
    codigo_vendedor INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    salario_fixo DECIMAL(10,2) NOT NULL
);

CREATE TABLE produtos (
    codigo INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco_venda DECIMAL(10,2) NOT NULL,
    saldo_estoque INT NOT NULL DEFAULT 0
);

CREATE TABLE pedidos (
    numero_pedido INT AUTO_INCREMENT PRIMARY KEY,
    data_pedido DATE NOT NULL,
    codigo_vendedor INT NOT NULL,
    FOREIGN KEY (codigo_vendedor) REFERENCES vendedores(codigo_vendedor)
);

CREATE TABLE itens_pedido (
    numero_pedido INT NOT NULL,
    codigo_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (numero_pedido, codigo_produto),
    FOREIGN KEY (numero_pedido) REFERENCES pedidos(numero_pedido),
    FOREIGN KEY (codigo_produto) REFERENCES produtos(codigo)
);

-- Massa de Dados
INSERT INTO vendedores (nome, salario_fixo) VALUES
('Carlos Souza', 2500.00),
('Mariana Lima', 3200.00),
('Fernanda Alves', 2800.00);

INSERT INTO produtos (nome, preco_venda, saldo_estoque) VALUES
('Notebook', 2999.90, 10),
('Monitor', 899.90, 15),
('Teclado', 149.90, 30),
('Mouse', 79.90, 40),
('Impressora', 1299.90, 8);

INSERT INTO pedidos (data_pedido, codigo_vendedor) VALUES
('2026-04-01', 1),
('2026-04-02', 2),
('2026-04-03', 1),
('2026-04-04', 3),
('2026-04-05', 2);

INSERT INTO itens_pedido (numero_pedido, codigo_produto, quantidade, preco_unitario) VALUES
(1, 1, 1, 2999.90),
(1, 3, 2, 149.90),
(2, 2, 1, 899.90),
(3, 4, 5, 79.90),
(4, 5, 1, 1299.90),
(5, 1, 1, 2999.90);

-- Criação de procedures
delimiter //
create procedure AtualizarEstoque(
	in codigo_produto int,
    in qtd int
)
begin
	update produtos set saldo_estoque = saldo_estoque - qtd where codigo = codigo_produto;
end//
delimiter ;

delimiter //
create procedure RegistrarVenda(
	in id_vendedor int,
    in codigo_produto int,
    in qtd int
)
begin
    DECLARE preco DECIMAL(10,2);

    SELECT preco_venda INTO preco 
    FROM produtos 
    WHERE codigo = codigo_produto;
    
    set preco = preco * qtd;
	
	insert into pedidos(data_pedido, codigo_vendedor)
    values(now(), id_vendedor);
    
    insert into itens_pedido(numero_pedido, codigo_produto, quantidade, preco_unitario)
    values(last_insert_id(), codigo_produto, qtd, preco);
    
    call AtualizarEstoque(codigo_produto, qtd);
end//
delimiter ;

delimiter //
create procedure ObterTotalPedidosVendedor(
	in id_vendedor int,
    out total int
)
begin
    select count(*) into total 
    from pedidos 
    where codigo_vendedor = id_vendedor;
end//
delimiter ;

delimiter //
create procedure AplicarAumentoSalario(
	inout salario decimal(10, 2),
    in percentual decimal(5, 2)
)
begin
	set salario = salario * (1 + (percentual/100));
end//
delimiter ;

-- Execução de procedures
select * from produtos where codigo = 1; -- 10 antes da call, 9 depois
call AtualizarEstoque(1, 1);
-- Pois apenas um grant de update poderia permitir um usuário a atualizar parâmetros indesejados

select * from produtos where codigo = 2; -- 15 antes da call, 13 depois
select * from pedidos; -- Último registro com data atual e código vendedor 3
select * from itens_pedido; -- Último registro codigo_produto 2, quantidade 2 e preco_unitario 1799.80
call RegistrarVenda(3, 2, 2);

call ObterTotalPedidosVendedor(1, @total);
select @total; -- retorna 2

SET @salario = (SELECT salario_fixo FROM vendedores WHERE codigo_vendedor = 2);
CALL AplicarAumentoSalario(@salario, 10);
SELECT @salario; -- 3200 antes da call, 3520 depois
UPDATE vendedores SET salario_fixo = @salario WHERE codigo_vendedor = 2;
select * from vendedores where codigo_vendedor = 2;
-- A diferença entre out e inout é que out é um parâmetro criado dentro da procedure e retornado, enquando inout é um parâmetro trazido da aplicação, (geralmente) modificado, e depois retornado