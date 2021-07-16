import numpy as np
import pandas as pd
from datetime import datetime
from parameters import Parameters
from castle import CASTLE, Item, Cluster
from visualisations import display_visualisation
from statistics import Statistics
from subscriber import Subscriber, Publisher

publisher = None


def handler(value: pd.Series):
    # Cluster information
    cluster_id = value.parent.identifier
    value.data["createdAt"] = value.timestamp
    value.data["outputAt"] = datetime.now()
    value.data["delay"] = str((value.data["outputAt"] - value.data["createdAt"]).total_seconds())
    value.data["cluster"] = cluster_id.hex
    value.data["outputAt"] = str(value.data["outputAt"])
    value.data["createdAt"] = str(value.data["createdAt"])

    global publisher
    publisher.publish(value.data.to_dict())


def main():
    params = Parameters()
    np.random.seed(params.seed)

    print(f"Starting CASTLE with seed {params.seed}")

    # Init output file
    global output_file
    output_file = params.output_file
    global publisher
    publisher = Publisher(params.host, params.port, params.output_topic)
    stream = CASTLE(handler, params)

    _ = Subscriber(params.host, params.port, stream)



if __name__ == "__main__":
    main()
