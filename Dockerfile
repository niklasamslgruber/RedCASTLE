# Use Ubuntu version 20.04 as base image
FROM ubuntu:20.04

# Node-RED project as working directory
WORKDIR /k-anonymity-env
COPY . /k-anonymity-env

# Install basic packages for Ubuntu
RUN apt update
RUN apt install -y software-properties-common
RUN apt install -y curl
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash
RUN apt install -y nodejs
RUN npm install -g --unsafe-perm node-red
RUN npm install node-red-dashboard

# Install Mosquito
RUN apt-add-repository ppa:mosquitto-dev/mosquitto-ppa
RUN apt update
RUN apt install -y mosquitto

# Install Python and CASTLE dependencies
RUN apt install -y  python3-pip
RUN pip3 install pandas
RUN pip3 install numpy
RUN pip3 install zmq
RUN pip3 install matplotlib

EXPOSE 1883
EXPOSE 1880

# Run the application
ENTRYPOINT ["sh", "setup.sh"]
