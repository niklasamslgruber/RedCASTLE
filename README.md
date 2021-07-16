k-Anonymity
===========

## What is this?

This is a project work done during the Summer Semester 2021 at the Technical University Berlin in the module Privacy Engineering. The goal is to implement privacy related features in an actual use case to provide value for others in the future. In this Project k-Anonymity is implemented in a streaming data use case in the Node-Red environment. 

The used k-Anonymity Algorithm is [CASTLEGUARD](https://github.com/hallnath1/CASTLEGUARD), which based on the [CASTLE (Continuously Anonymizing STreaming data via adaptive cLustEring)](https://ieeexplore.ieee.org/abstract/document/5374415) by J. Cao, B. Carminati, E. Ferrari and K. Tan. Minor changes where made to the CASTLEGUARD algorithm to adapt it to our use case. 

The used validation use case is a dataset with electric vehicle charging data. The data used is provided by the city of Boulder in Colorado (USA) via their [Open Data Plattform](https://open-data.bouldercolorado.gov/datasets/4368ba17948c459c813734bd78b3a355_0) in a CC0 1.0 Public Domain Dedication licence model. To spice up the dataset, a number of fake persons with specific vehicle models and unique ids are generated and used to enrich the original dataset.

Example Dataset
--------
| Station Name           | Address          | Zip/Postal Code | Start Date & Time | End Date & Time | Total Duration (hh:mm:ss) | Charging Time (hh:mm:ss) | Energy (kWh) | GHG Savings (kg) | Gasoline Savings (gallons) | customer id | allow dynamic charging | car brand | car modell |
|------------------------|------------------|-----------------|-------------------|-----------------|---------------------------|--------------------------|--------------|------------------|----------------------------|-------------|------------------------|-----------|------------|
| BOULDER / JUNCTION ST1 | 2280 Junction Pl | 80301           | 1/1/2018 17:49    | 1/1/2018 19:52  | 2:03:02                   | 2:02:44                  | 6.504        | 2.732            | 0.816                      | 1006        | true                   | Tesla     | Model Y    |
| BOULDER / JUNCTION ST1 | 2280 Junction Pl | 80301           | 1/2/2018 8:52     | 1/2/2018 9:16   | 0:24:34                   | 0:24:19                  | 2.481        | 1.042            | 0.311                      | 1052        | true                   | BMW       | i3         |

--------

Additionally a few functionalities where added to assist further to achieve privacy when working with personal data. Fro this a filter and a reduce function are implemented.

These functions can be configured via a json object. This configuration object has to be added to the message object, not the msg.payload object.

Example configurations for filter and reduce:
--------
Suppressed specific properties:
```json
{
    "suppressed_properties": [
        "ObjectId",
        "Address",
        "City"
    ]
}
```
message object structure for this example: msg.suppressed_properties.suppressed_properties (array[3])


Filter for specfic conditions. Currenty supported are range filtering as well as whitelist and blacklist filtering. A entry has to pass all filter conditions, otherwise the entry is removed from the set. You could also use only one or two of the filter conditions.
```json
{
    "filterCondition": {
        "rangeFilter": {
            "columnName": "ObjectId",
            "minValue": 10000,
            "maxValue": 30000
        },
        "whitelistFilter": {
            "columnName": "ObjectId",
            "whitelistValues": [
                10459,
                22794,
                20286,
                872
            ]
        },
        "blacklistFilter": {
            "columnName": "ObjectId",
            "blacklistValues": [
                22794
            ]
        }
    }
}
```
message object structure for this example: msg.filterCondition.rangeFilter (object) ...

Change or append new properties based on existing properties. 

Add a car_price property based on a given mapping of car_modell names and prices.
```json
{
    "changeStringEqual": {
        "sourceAttributeName": "car_modell",
        "changeAttributeName": "car_price",
        "change": [
            {
                "conditionStringEqual": "e-tron 55",
                "valueForChangeAttributeName": 84459
            },
            {
                "conditionStringEqual": "e-tron 50",
                "valueForChangeAttributeName": 69100
            }
        ]
    }
}
```
message object structure for this example: msg.changeConditions.changeStringEqual (object)

Add a alternative way to interpret the car prices by adding car_price_alt which sets different values depending on if the car_price is in a specific range.
```json
{
    "changeRangeBased": {
        "sourceAttributeName": "car_price",
        "changeAttributeName": "car_price_alt",
        "change": [
            {
                "conditionMin": 40000,
                "conditionMax": 120000,
                "valueForChangeAttributeName": "expensive"
            },
            {
                "conditionMin": 0,
                "conditionMax": 39999,
                "valueForChangeAttributeName": "cheap"
            }
        ]
    }
}
```
message object structure for this example: msg.changeConditions.changeRangeBased (object)