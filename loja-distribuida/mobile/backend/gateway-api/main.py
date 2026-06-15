from fastapi import FastAPI, Header, HTTPException
import httpx
from jose import jwt, JWTError



app = FastAPI()



AUTH_SERVICE = "http://auth-service:8004"

PRODUTO_SERVICE = "http://produto-service:8001"



SECRET = "minha_chave_secreta"



def validar_token(authorization: str):


    if not authorization:

        raise HTTPException(
            status_code=401,
            detail="Token não enviado"
        )



    try:


        token = authorization.replace(
            "Bearer ",
            ""
        )


        payload = jwt.decode(

            token,

            SECRET,

            algorithms=["HS256"]

        )


        return payload



    except JWTError:


        raise HTTPException(

            status_code=401,

            detail="Token inválido"

        )





@app.get("/")
def home():

    return {

        "gateway":"online"

    }





@app.post("/login")
async def login(dados:dict):


    async with httpx.AsyncClient() as client:


        response = await client.post(

            f"{AUTH_SERVICE}/login",

            json=dados

        )


    return response.json()





@app.post("/cadastro")
async def cadastro(dados:dict):


    async with httpx.AsyncClient() as client:


        response = await client.post(

            f"{AUTH_SERVICE}/cadastro",

            json=dados

        )


    return response.json()





@app.get("/produtos")
async def produtos(

    authorization: str = Header(None)

):


    validar_token(
        authorization
    )



    async with httpx.AsyncClient() as client:


        response = await client.get(

            f"{PRODUTO_SERVICE}/produtos"

        )



    return response.json()