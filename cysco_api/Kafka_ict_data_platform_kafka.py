import os
from confluent_kafka import Consumer, Producer
from Kafka_wifi_serializer import WiFiSerializer



def connect_producer():
    # Create Producer instance
    producer = Producer(
        {
            "bootstrap.servers": os.getenv("PROD_SERVERS"),
            "sasl.mechanisms": "PLAIN",
            "security.protocol": "SASL_SSL",
            "sasl.username": os.getenv("PROD_USER"),
            "sasl.password": os.getenv("PROD_PASSWORD"),
            # 'ssl.ca.location': os.getenv('PROD_SSL'),
        }
    )
    return producer


def connect_consumer(group_id):
    # Create Consumer instance
    consumer = Consumer(
        {
            "bootstrap.servers": os.getenv("PROD_SERVERS"),
            "sasl.mechanisms": "PLAIN",
            "security.protocol": "SASL_SSL",
            "sasl.username": os.getenv("PROD_USER"),
            "sasl.password": os.getenv("PROD_PASSWORD"),
            # 'ssl.ca.location': os.getenv('PROD_SSL'),
            "group.id": group_id,
            "auto.offset.reset": "latest",
        }
    )
    return consumer


def get_wifi_serializer(topics):
    return WiFiSerializer(
        os.getenv("SCHEMA_REGISTRY_URL"),
        os.getenv("SCHEMA_REGISTRY_API_KEY"),
        os.getenv("SCHEMA_REGISTRY_API_SECRET"),
        topics,
    )
