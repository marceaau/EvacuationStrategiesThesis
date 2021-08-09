from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer, AvroDeserializer
from confluent_kafka.serialization import SerializationContext, MessageField
import requests


class WiFiSerializer:

    def __init__(self, schema_registry_url, schema_registry_api_key, 
                 schema_registry_api_secret, topics):
        self.schema_registry_url = schema_registry_url
        self.schema_registry_api_key = schema_registry_api_key
        self.schema_registry_api_secret = schema_registry_api_secret

        self.serializer_dict = {}
        for topic in topics:
            avro_serializer, avro_deserializer, serialization_context = self.init_serializer(topic)
            self.serializer_dict[topic] = {
                "avro_serializer": avro_serializer,
                "avro_deserializer": avro_deserializer,
                "serialization_context": serialization_context
            }


    def init_serializer(self, topic):
        """ Initialize Avro serializer and deserializer for a topic.
        """

        # Get the schema from the Schema Registry.
        r = requests.get(f"{self.schema_registry_url}/subjects/{topic}-value/versions/latest",
                         auth=(self.schema_registry_api_key, self.schema_registry_api_secret))
        schema_str = r.json()['schema']
        
        # Schema Registry client
        conf = {
            'url': self.schema_registry_url,
            'basic.auth.user.info': f"{self.schema_registry_api_key}:{self.schema_registry_api_secret}"
        }
        schema_registry_client = SchemaRegistryClient(conf)

        # Avro serializer
        conf = {
            'auto.register.schemas': False
        }
        avro_serializer = AvroSerializer(schema_registry_client,
                                         schema_str,
                                         conf=conf)

        # Avro deserializer
        avro_deserializer = AvroDeserializer(schema_registry_client,
                                             schema_str)

        serialization_context = SerializationContext(topic, MessageField.VALUE)

        return avro_serializer, avro_deserializer, serialization_context


    def serialize(self, value, topic):
        """Serialize the value using the corresponding schema for the topic.
        """

        avro_serializer = self.serializer_dict[topic]["avro_serializer"]
        serialization_context = self.serializer_dict[topic]["serialization_context"]
        return avro_serializer(value, serialization_context)


    def deserialize(self, value, topic):
        """deserialize the value using the corresponding schema for the topic.
        """

        avro_deserializer = self.serializer_dict[topic]["avro_deserializer"]
        serialization_context = self.serializer_dict[topic]["serialization_context"]
        return avro_deserializer(value, serialization_context)
