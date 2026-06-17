from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base
from passlib.context import CryptContext
from jose import jwt
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


DATABASE_URL = "postgresql://admin:123456@localhost:5432/loja"


engine = create_engine(DATABASE_URL)


Session = sessionmaker(bind=engine)


Base = declarative_base()



pwd = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)



SECRET = "minha_chave_secreta"



class Usuario(Base):

    __tablename__ = "usuarios"


    id = Column(
        Integer,
        primary_key=True
    )


    nome = Column(
        String
    )


    email = Column(
        String,
        unique=True
    )


    senha = Column(
        String
    )



Base.metadata.create_all(engine)




@app.post("/cadastro")
def cadastro(dados:dict):


    db = Session()



    senha_hash = pwd.hash(
        dados["senha"]
    )



    usuario = Usuario(

        nome=dados["nome"],

        email=dados["email"],

        senha=senha_hash

    )



    db.add(usuario)

    db.commit()


    return {

        "mensagem":"Conta criada"

    }





@app.post("/login")
def login(dados:dict):


    db = Session()



    usuario = db.query(
        Usuario
    ).filter(

        Usuario.email == dados["email"]

    ).first()



    if not usuario:

        raise HTTPException(

            status_code=401,

            detail="Email ou senha inválidos"

        )




    senha_ok = pwd.verify(

        dados["senha"],

        usuario.senha

    )



    if not senha_ok:


        raise HTTPException(

            status_code=401,

            detail="Email ou senha inválidos"

        )




    token = jwt.encode(

        {

        "sub":usuario.email

        },

        SECRET,

        algorithm="HS256"

    )



    return {


        "access_token":token,

        "token_type":"bearer"


    }
@app.post("/register")
def register(user: User):

    print("CADASTRO RECEBIDO:", user.email)

    return {
        "msg":"usuário criado"
    }