import pandas as pd
import json
import zmq

class Publisher:

    def __init__(self, host, port, output_topic):
        self.host = host
        self.port = port
        self.output_topic = output_topic
        self.context = zmq.Context()
        self.client = self.context.socket(zmq.PUB)
        self.client.bind(f"tcp://127.0.0.1:5557")
        self.counter = 0

    def publish(self, payload: dict):
        multipart_msg = [str(self.output_topic).encode(), str(payload).encode()]
        self.client.send_multipart(multipart_msg)
        self.counter += 1


class Subscriber:

    def __init__(self, params, castles):
        self.host = params.host
        self.port = params.port
        self.params = params
        self.castles = castles
        self.context = zmq.Context()
        self.client = self.context.socket(zmq.SUB)
        self.client.connect(f"tcp://localhost:{self.port}")
        for topic in self.params.mqtt_topics:
            self.client.subscribe(topic)
        self.categories = {}
        self.counter = 0

        while True: 
            topic, msg = self.client.recv_multipart()
            topic = topic.decode()

            # Insert to CASTLE
            series = self.parse_response(msg)
            self.update_mapping()

            if topic in self.castles:
                self.castles[topic].insert(series)
                self.counter += 1
            else:
                print(f"ERROR: {topic}")

    def on_connect(self, client, userdata, flags, rc):
        for topic in self.params.mqtt_topics:
            client.subscribe(topic)

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
