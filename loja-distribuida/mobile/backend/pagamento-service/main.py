from fastapi import FastAPI
import pika
import json
import threading


app = FastAPI(
    title="Pagamento Service"
)



def consumir_pedidos():

    connection = pika.BlockingConnection(

    pika.ConnectionParameters(

        host="localhost",

        port=5672,

        credentials=pika.PlainCredentials(
            "admin",
            "admin"
        ),

        heartbeat=600

    )

)


    channel = connection.channel()


    channel.queue_declare(
        queue="pedidos"
    )


    def receber(ch, method, properties, body):

        pedido = json.loads(body)


        print("====================")
        print("Pedido recebido:")
        print(pedido)
        print("====================")


        print("Pagamento aprovado")


        ch.basic_ack(
            delivery_tag=method.delivery_tag
        )



    channel.basic_consume(

        queue="pedidos",

        on_message_callback=receber

    )


    print("Aguardando pedidos...")


    channel.start_consuming()




@app.on_event("startup")
def iniciar():

    thread = threading.Thread(
        target=consumir_pedidos,
        daemon=True
    )

    thread.start()



@app.get("/")
def home():

    return {

        "service":"pagamento-service",

        "status":"online"

    }