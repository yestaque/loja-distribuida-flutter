import pika


connection = pika.BlockingConnection(

    pika.ConnectionParameters(
        "localhost"
    )

)


channel = connection.channel()


channel.queue_declare(
    queue="pedidos"
)


channel.basic_publish(

    exchange="",

    routing_key="pedidos",

    body="Novo pedido criado"

)


print("Mensagem enviada")


connection.close()