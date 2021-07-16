#!/bin/bash

# Setup Mosquito Server and start NODE-RED
mosquitto & node-red --safe -u /k-anonymity-env flow.json
