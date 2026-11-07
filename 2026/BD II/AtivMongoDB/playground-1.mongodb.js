// 1. Seleciona ou cria o banco de dados da lanchonete
use ('devburger');

// 2. CREATE: Cadastrando os primeiros lanches, porções e bebidas no cardápio
db.produtos.insertOne({
  nome: "Bug-Buster Burger",
  ingredientes: ["Pão Australiano", "Hambúrguer 200g", "Queijo Cheddar", "Bacon", "Molho Especial"],
  preco: 38.50,
  categoria: "Lanches",
  disponivel: true
});

db.produtos.insertMany([
  {
    nome: "Stack Overflow Fries",
    ingredientes: ["Batata Frita", "Queijo Melted", "Crispy de Bacon"],
    preco: 22.00,
    categoria: "Porções",
    disponivel: true
  },
  {
    nome: "NullPointer Refri",
    tipo: "Cola 350ml",
    preco: 8.00,
    categoria: "Bebidas",
    disponivel: true
  },
  {
    nome: "404 Not Found Salad",
    ingredientes: ["Alface", "Tomate", "Croutons", "Molho Caesar"],
    preco: 18.00,
    categoria: "Saladas",
    disponivel: false
  }
]);

// 3. READ: Consultando itens do cardápio e aplicando projeções e filtros
db.produtos.find();

db.produtos.find({ categoria: "Lanches" });

db.produtos.find({ preco: { $lt: 25.00 } });

db.produtos.find(
  { disponivel: true },
  { nome: 1, preco: 1, _id: 0 }
);

// 4. UPDATE: Atualizando preços, modificando arrays e aplicando promoções
db.produtos.updateOne(
  { nome: "Bug-Buster Burger" },
  {
    $inc: { preco: 3.50 },
    $addToSet: { ingredientes: "Cebola Caramelizada" }
  }
);

db.produtos.updateOne(
  { nome: "404 Not Found Salad" },
  { $set: { disponivel: true } }
);

db.produtos.updateMany(
  { categoria: "Bebidas" },
  { $mul: { preco: 0.90 } }
);

// 5. DELETE: Removendo produtos indisponíveis ou descontinuados
db.produtos.deleteOne({ nome: "Stack Overflow Fries" });

db.produtos.deleteMany({ disponivel: false });

// Etapa 5: Inserção de pedido
db.pedidos.insertOne({
    nomeCliente: "João Silva",
    valorTotal: 45.00,
    status: "Pendente"
});

db.pedidos.updateOne(
    { nomeCliente: "João Silva" },
    { $set: { status: "Entregue" } }
);

db.pedidos.find({
    valorTotal: { $gt: 30.00 }
});

db.pedidos.deleteOne({
    nomeCliente: "João Silva"
});