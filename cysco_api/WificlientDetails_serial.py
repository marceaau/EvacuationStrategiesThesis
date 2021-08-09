# Standard library imports
import os
from datetime import datetime
import argparse
import json
import math
import pandas as pd

# Third party imports
from confluent_kafka.error import SerializationError
import psycopg2

# Local application imports
import Kafka_ict_data_platform_kafka as kafka

def ingest(msg, value):
    # print out the value of the kafka message

    y = value
    
    if 'A-31' in y['apName']:
        
        to_add = {'macAddressMonth' : y['macAddressMonth'], 
                  'associationTime' : y['associationTime'], 
                  'firstSeenTime' : y['firstSeenTime'], 
                  'deviceType' : y['deviceType'], 
                  'location' : y['location'], 
                  'apName' : y['apName'], 
                  'updateTime' : y['updateTime']}

        df = pd.DataFrame().append(to_add, ignore_index=True)
        #value.to_csv('my_csv.csv', mode='a', header=False)
        df.to_csv('my_csv.csv', mode='a', header=False, index=False)


    


def deserializing_wifi_consumer(topics):
    # Use unique group_id like PROD_USER, not this one.
    consumer = kafka.connect_consumer(os.getenv("GROUP_ID"))
    # print(consumer.position())
    wifi_serializer = kafka.get_wifi_serializer(topics)

    # Subscribe to topics
    consumer.subscribe(topics)

    # Process messages
    total_count = 0
    while True:
        try:
            msg = consumer.poll(1.0)

            if msg is None:
                # No message available within timeout.
                # Initial message consumption may take up to
                # `session.timeout.ms` for the consumer group to
                # rebalance and start consuming
                print("Waiting for message or event/error in poll()", topics, datetime.now())
                continue
            elif msg.error():
                print("error: {}".format(msg.error()))
            else:
                timestamp_epoch = msg.timestamp()[1] / 1000.0
                timestamp = datetime.fromtimestamp(timestamp_epoch).isoformat()
                #print("timestamp: ", timestamp)
                value = wifi_serializer.deserialize(msg.value(), msg.topic())
                if(msg.topic() == 'WiFiclientDetails_Month'):
                    ingest(msg, value)
                    #print(
                        #f"Consumed record with key {msg.key()} and value {value} from topic {msg.topic()}"
                    #)
        except KeyboardInterrupt:
            break
        except SerializationError as e:
            # Report malformed record, discard results, continue polling
            print("Message deserialization failed {}".format(e))
            pass

    # Leave group and commit final offsets
    consumer.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Consuming WiFi data from Kafka. \
             Don't forget to set the environment variables. See README.md."
    )
    parser.add_argument("topics", help="List of topics")
    args = parser.parse_args()
    topics = args.topics.split(",")
    
    df = pd.DataFrame()

    deserializing_wifi_consumer(topics)
    
    
