from fastapi import FastAPI
import pika
import json


app = FastAPI()



def enviar_evento(pedido):


    connection = pika.BlockingConnection(

        pika.ConnectionParameters(
            host="localhost"
        )

    )


    channel = connection.channel()



    channel.queue_declare(

        queue="pedidos"

    )



    channel.basic_publish(

        exchange="",

        routing_key="pedidos",

        body=json.dumps(pedido)

    )


    connection.close()



@app.post("/pedido")
def criar_pedido():


    pedido = {


        "id":1,

        "produto":"Notebook",

        "status":"criado"

    }


    enviar_evento(pedido)



    return {


        "mensagem":"Pedido enviado para fila",

        "pedido":pedido

    }