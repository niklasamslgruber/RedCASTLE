import json
import os.path
import numpy as np

class Parameters:
    """The parameters for the CASTLE algorithm."""

    def __init__(self):
        """Initialises the parameters object

        Kwargs:
            args: The CLI arguments for the program

        """
        config_path = "CASTLE/src/config.json"

        if not os.path.exists(config_path):
            quit("Project needs to include a config.json at source")
            return

        with open(config_path) as file:
            config = json.load(file)
            params = config.get("params")
            io = config.get("io")

            self.k = self.required(params.get("k"))
            self.delta = self.required(params.get("delta"))
            self.beta = self.required(params.get("beta"))
            self.mu = self.required(params.get("mu"))
            self.sensitive_attribute = self.required(params.get("sensitive_attribute"))
            self.quasi_identifiers = self.required(params.get("quasi_identifiers"))
            self.pid = self.required(params.get("pid_column"))

            self.seed = self.optional(params.get("seed"), np.random.randint(1e6))
            self.history = self.optional(params.get("history"), False)
            self.graph = self.optional(params.get("graph"), False)

            self.output_file = self.required(io.get("output_file"))
            self.host = self.optional(io.get("host"), "localhost")
            self.port = self.optional(io.get("port"), 1883)
            self.mqtt_topics = self.required(io.get("mqtt_topics_in"))
            self.output_topic = self.required(io.get("mqtt_topic_out"))

    def required(self, config):
        if config is None:
            quit("Missing value in config.json or command line argument")
        else:
            return config

    def optional(self, config, default):
        if config is not None:
            return config
        else:
            return default

    def __str__(self):
        """Returns a string representation of the object
        Returns: A string representation of the internal values

        """
        params = ["{}={}".format(k, v) for k, v in self.__dict__.items()]
        return "Parameters({})".format(", ".join(params))
