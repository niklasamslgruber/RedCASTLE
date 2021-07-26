import paho.mqtt.client as mqtt
import pandas as pd
import json


class Publisher:

    def __init__(self, host, port, output_topic):
        self.host = host
        self.port = port
        self.output_topic = output_topic
        self.client = mqtt.Client()
        self.client.connect(self.host, self.port, 60)
        self.counter = 0

    def publish(self, payload: dict):
        self.client.publish(self.output_topic, str(payload))
        self.counter += 1


class Subscriber:

    def __init__(self, params, castles):
        self.host = params.host
        self.port = params.port
        self.params = params
        self.castles = castles
        self.client = mqtt.Client()
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.categories = {}
        self.counter = 0

        self.start()

    def on_connect(self, client, userdata, flags, rc):
        for topic in self.params.mqtt_topics:
            client.subscribe(topic)

    # The callback for when a PUBLISH message is received from the server.
    def on_message(self, client, userdata, msg):
        print(msg.topic + " " + str(msg.payload))

        # Insert to CASTLE
        series = self.parse_response(msg.payload)
        self.update_mapping()

        if msg.topic in self.castles:
            self.castles[msg.topic].insert(series)
            self.counter += 1
        else:
            print(f"ERROR: {msg.topic}")

    def start(self):
        self.client.connect(self.host, self.port, 60)
        self.client.loop_forever()

    def disconnect(self):
        self.client.disconnect()

    def parse_response(self, payload) -> pd.Series:
        json_dict = json.loads(payload)
        series = pd.Series(json_dict)
        for key in series.keys():
            if key in self.params.quasi_identifiers and key in self.params.non_categorized_columns:
                if key in self.categories and series[key] not in self.categories[key]:
                    self.categories[key].append(series[key])
                elif key not in self.categories:
                    self.categories[key] = [series[key]]

                series[key] = self.categories[key].index(series[key])

        series["pid"] = series[self.params.pid]
        del series[self.params.pid]

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
