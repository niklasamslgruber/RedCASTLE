import math
import pandas as pd
from typing import List


def test_with_sample():
    dict = {
        "job": ["TGT1", "PGT1", "PPRT1", "TGT", "PPRT", "PGT"],
        "age": [49, 40, 44, 48, 45, 43],
        "pin": [132042, 132021, 132024, 132046, 132045, 132027],
        "equivalenceClass": [1, 0, 0, 1, 1, 0]
        }

    frame = pd.DataFrame(dict)

    stats = Statistics(quasi_identifiers=["job", "age", "pin"], equivalence_class_column="equivalenceClass")
    frame = stats.categorize_columns(frame, ["pin", "job"])

    print(f'Generalized Information Loss: {round(stats.generalized_information_loss(frame, ["job", "age", "pin"]), 4)}')

    print(f'Discernibility Metric: {stats.discernibility_metric(frame, 3)}')

    print(f'Average Equivalence Class Size Metric: {stats.average_class_size(frame, 3)}')


class Statistics:
    """
       Data Metrics for k-Anonymity
       (source: https://www.ijser.org/researchpaper/Data-Utility-Metrics-for-k-anonymization-Algorithms.pdf)
       """

    def __init__(self, quasi_identifiers: List[str], equivalence_class_column: str):
        self.k = 1
        self.quasi_identifiers: List[str] = quasi_identifiers
        self.equivalence_class_column: str = equivalence_class_column


    def discernibility_metric(self, dataframe: pd.DataFrame, k: int) -> float:
        """ Calculates the degree of indistinguishability of records """
        metric = 0

        for value in set(dataframe[self.equivalence_class_column]):
            eq_class_size = len(dataframe[dataframe[self.equivalence_class_column] == value])
            if eq_class_size >= k:
                metric += math.pow(eq_class_size, 2)
            else:
                metric += len(dataframe) * eq_class_size

        return metric

    def average_class_size(self, dataframe: pd.DataFrame, k: int) -> float:
        """ Calcuates how well the equivalence classes approach the best case where each record is generalized in an equivalence class of size k"""
        return len(dataframe) / (len(set(dataframe[self.equivalence_class_column])) * k)

    def generalized_information_loss(self, frame: pd.DataFrame, quasi_identifiers: List[str]) -> float:
        """ Calculates the amount of information loss when generalizing specific identifiers"""

        information_loss = 0
        for index, row in frame.iterrows():
            for key in quasi_identifiers:
                category = row[self.equivalence_class_column]
                uij = frame[frame[self.equivalence_class_column] == category][key].max()
                lij = frame[frame[self.equivalence_class_column] == category][key].min()
                ui = frame[key].max() + (0 if key == "age" else 1)
                li = frame[key].min() + (0 if key == "age" else 1)
                information_loss += ((uij - lij) / (ui - li))

        factor = 1 / (len(quasi_identifiers) * len(frame))
        result = factor * information_loss
        return result

    """ Helper """

    def categorize_columns(self, dataframe: pd.DataFrame, columnNames: [str]) -> pd.DataFrame:
        categorized_column = dataframe[columnNames].apply(lambda col: pd.Categorical(col).codes)
        categorized_column += 1
        dataframe[columnNames] = categorized_column
        return dataframe
