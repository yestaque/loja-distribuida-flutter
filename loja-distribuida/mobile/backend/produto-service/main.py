from fastapi import FastAPI


app = FastAPI(
    title="Produto Service"
)


produtos = [

    {
        "id":1,
        "nome":"Notebook",
        "preco":3500
    },

    {
        "id":2,
        "nome":"Celular",
        "preco":2000
    }

]


@app.get("/")
def home():

    return {
        "service":"produto-service",
        "status":"online"
    }



@app.get("/produtos")
def listar_produtos():

    return produtos



@app.post("/produtos")
def criar_produto(produto:dict):

    produtos.append(produto)

    return {
        "mensagem":"Produto criado",
        "produto":produto
    }