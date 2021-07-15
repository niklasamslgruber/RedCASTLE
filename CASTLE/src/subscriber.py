import paho.mqtt.client as mqtt
from castle import CASTLE
import pandas as pd
import json


class Publisher:

    def __init__(self, host, port, output_topic):
        self.host = host
        self.port = port
        self.output_topic = output_topic
        self.client = mqtt.Client()
        self.client.connect(self.host, self.port, 60)

    def publish(self, payload: dict):
        self.client.publish(self.output_topic, payload)


class Subscriber:

    def __init__(self, host: str, port: int, castle: CASTLE):
        self.host = host
        self.port = port
        self.castle = castle
        self.client = mqtt.Client()
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.categories = {}

        self.start()

    def on_connect(self, client, userdata, flags, rc):
        for topic in self.castle.params.mqtt_topics:
            client.subscribe(topic)

    # The callback for when a PUBLISH message is received from the server.
    def on_message(self, client, userdata, msg):
        print(msg.topic + " " + str(msg.payload))

        # Insert to CASTLE
        series = self.parse_response(msg.payload)
        self.update_mapping()
        self.castle.insert(series)

    def start(self):
        self.client.connect(self.host, self.port, 60)
        self.client.loop_forever()

    def disconnect(self):
        self.client.disconnect()

    def parse_response(self, payload) -> pd.Series:
        json_dict = json.loads(payload)
        series = pd.Series(json_dict)
        for key in series.keys():
            if key in self.castle.headers:
                if key in self.categories and series[key] not in self.categories[key]:
                    self.categories[key].append(series[key])
                elif key not in self.categories:
                    self.categories[key] = [series[key]]

                series[key] = self.categories[key].index(series[key])

        series["pid"] = series[self.castle.params.pid]
        del series[self.castle.params.pid]

        return series

    def update_mapping(self):
        mapping_file = self.categories.copy()
        for mapping in mapping_file.keys():
            new_dict = {}
            for index, item in enumerate(mapping_file[mapping]):
                new_dict[index] = item

            mapping_file[mapping] = new_dict

        with open('mapping.json', 'w') as fp:
            json.dump(mapping_file, fp, indent=4)


if __name__ == '__main__':
    sub = Subscriber("localhost", 1883)
