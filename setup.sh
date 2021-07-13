#!/bin/bash

# Setup Mosquito Server and start NODE-RED
/usr/local/sbin/mosquitto -c /usr/local/etc/mosquitto/mosquitto.conf & node-red
