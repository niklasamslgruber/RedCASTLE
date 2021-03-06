provider "google" {
  project = "adsp-302713"
  region  = "europe-west3"
  zone    = "europe-west3-a"
}

resource "random_id" "id" {
  byte_length = 4
}


resource "google_compute_instance" "node_red_cloud" {
  name         = "node-red-cloud-server"
  machine_type = "n2-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
  metadata = {
    ssh-keys = "peng:${file("~/.ssh/id_rsa.pub")}"
  }
  
  connection {
    type  = "ssh"
    host  = self.network_interface.0.access_config.0.nat_ip
    user  = "peng"
    port  = 22
#    agent = true
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" { 
#    interpreter = ["/bin/bash" ,"-c"]
    
    #inline = [
    #  "curl -fsSL https://get.docker.com -o get-docker.sh",
    #  "sudo sh get-docker.sh",
    #  "sudo docker run -d -ti -p 1883:1883 -p 1880:1880 niklasamslgruber/node-red-castle"
   #]

  # Run without docker on dev branche
  inline = [
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install git nodejs npm python3-pip screen -y",
      "sudo npm install npm@latest -g",
      "pip3 install --upgrade pip",
      "sudo npm install -g pm2",
      "sudo npm install -g --unsafe-perm node-red",
      "git clone https://github.com/niklasamslgruber/RedCASTLE.git",
      "cd RedCASTLE",
      "git checkout dev_advanced_benchmark", # change branche accordingly to needs
      "chmod +x setup.sh",
      "pip3 install -r requirements.txt",
      # inject broker ip in the redcastle config file 
      # TODO: only work if the config is not changed to something else then localhost
      "sed -i 's/localhost/${google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip}/g' CASTLE/src/config.json",
      # inject broker ip in the flow file directly changing the mqtt node config
      # TODO: only work if the config is not changed to something else then localhost
      "sed -i 's/localhost/${google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip}/g' flow.json",
      "pm2 start /usr/local/bin/node-red -- ~/RedCASTLE/flow.json",
      "sleep 10s",
      # install RedCastle npm dependencies
      "cd ~/.node-red/",
      "sudo npm install node-red-dashboard",
      "sudo npm install node-red-contrib-zeromq",
      "sudo npm install node-red-contrib-msg-speed",
      "pm2 restart node-red",
      "sleep 10s",
      "pm2 logs node-red --nostream --lines 50"
   ]
  }
}

resource "google_compute_instance" "mqtt_broker_cloud" {
  name         = "mqtt-broker-cloud-server"
  machine_type = "n2-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
  metadata = {
    ssh-keys = "peng:${file("~/.ssh/id_rsa.pub")}"
  }
  
  connection {
    type  = "ssh"
    host  = self.network_interface.0.access_config.0.nat_ip
    user  = "peng"
    port  = 22
#    agent = true
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  
  provisioner "file" {
    source      = "scripts/installRabbitMQ.sh"
    destination = "~/installRabbitMQ.sh"
  }

  provisioner "remote-exec" { 
#    interpreter = ["/bin/bash" ,"-c"]
    inline = [
      "sudo apt install libncurses5 -y",
      "chmod +x installRabbitMQ.sh",
      "sudo ./installRabbitMQ.sh",
      "sudo rabbitmq-plugins enable rabbitmq_mqtt",
      "sudo rabbitmq-plugins enable rabbitmq_management",
      "sudo service rabbitmq-server restart",
      # TODO: create correct user with the right credentials  
      "sudo rabbitmqctl add_user peng peng",
      "sudo rabbitmqctl set_user_tags peng administrator",
      "sudo rabbitmqctl set_permissions 'peng' '.*' '.*' '.*'",
      "echo 'Management UI should now be available via http://${self.network_interface.0.access_config.0.nat_ip}:15672'"
   ]
  }  
}


resource "google_compute_instance" "emulator_cloud" {
  name         = "emulator-cloud-server"
  machine_type = "n2-standard-2"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
  metadata = {
    ssh-keys = "peng:${file("~/.ssh/id_rsa.pub")}"
  }
  
  connection {
    type  = "ssh"
    host  = self.network_interface.0.access_config.0.nat_ip
    user  = "peng"
    port  = 22
#    agent = true
    private_key = "${file("~/.ssh/id_rsa")}"
  }


  provisioner "remote-exec" { 
#    interpreter = ["/bin/bash" ,"-c"]
    inline = [
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install git nodejs npm python3-pip screen -y",
      "sudo npm install npm@latest -g",
      "pip3 install --upgrade pip",
      "sudo npm install -g pm2",
      "sudo npm install -g --unsafe-perm node-red",
      "git clone https://github.com/niklasamslgruber/RedCASTLE.git",
      "cd RedCASTLE",
      "git checkout dev_advanced_benchmark", # change branche accordingly to needs
      "chmod +x setup.sh",
      "pip3 install -r requirements.txt",
      # inject broker ip in the redcastle config file 
      # TODO: only work if the config is not changed to something else then localhost
      "sed -i 's/localhost/${google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip}/g' CASTLE/src/config.json",
      # inject broker ip in the flow file directly changing the mqtt node config
      # TODO: only work if the config is not changed to something else then localhost
      "sed -i 's/localhost/${google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip}/g' flow.json",
      "pm2 start /usr/local/bin/node-red -- ~/RedCASTLE/flow.json",
      "sleep 10s",
      # install RedCastle npm dependencies
      "cd ~/.node-red/",
      "sudo npm install node-red-dashboard",
      "sudo npm install node-red-contrib-zeromq",
      "sudo npm install node-red-contrib-msg-speed",
      "pm2 restart node-red",
      "sleep 10s",
      "pm2 logs node-red --nostream --lines 50"
   ]
  }  
}


resource "google_compute_network" "vpc_network" {
  name                    = "cloud-network"
  auto_create_subnetworks = "true"
}

#################################################################
#            Firewall
#################################################################

resource "google_compute_firewall" "allow_ssh" {
  name = "cloud-network-internal-allow-ssh-${random_id.id.hex}"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "allow_internet" {
  name = "cloud-network-internal-allow-http-${random_id.id.hex}"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_node_red" {
  name = "cloud-network-internal-allow-node-red-${random_id.id.hex}"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["1880"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_mqtt" {
  name = "cloud-network-internal-allow-mqtt-${random_id.id.hex}"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["1883"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_rabbitmq" {
  name = "cloud-network-internal-allow-rabbitmq-${random_id.id.hex}"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports = ["15672", "5672", "5671", "4369", "25672"]
  }
  source_ranges = ["0.0.0.0/0"]
}




# Backup MOSQUITTO


#resource "google_compute_instance" "mqtt_broker_cloud" {
#  name         = "mqtt-broker-cloud-server"
#  machine_type = "n2-standard-2"
#
#  boot_disk {
#    initialize_params {
#      image = "debian-cloud/debian-10"
#    }
#  }
#
#  network_interface {
#    # A default network is created for all GCP projects
#    network = google_compute_network.vpc_network.self_link
#    access_config {
#    }
#  }
#  metadata = {
#    ssh-keys = "peng:${file("~/.ssh/id_rsa.pub")}"
#  }
#  
#  connection {
#    type  = "ssh"
#    host  = self.network_interface.0.access_config.0.nat_ip
#    user  = "peng"
#    port  = 22
#    agent = true
#    private_key = "${file("~/.ssh/id_rsa")}"
#  }
  
#  provisioner "file" {
#    source      = "configs/mosquitto.conf"
#    destination = "~/mosquitto.conf"
#  }
#
#  provisioner "remote-exec" { 
#    interpreter = ["/bin/bash" ,"-c"]
#    inline = [
#      #"sudo apt update && sudo apt upgrade -y",
#      #"sudo apt install git python3-pip python3-zmq apt-transport-https ca-certificates gnupg -y",
#      #"pip3 install --upgrade pip",
#      "sudo mkdir -p /etc/mosquitto/conf.d",
#      "sudo mv ~/mosquitto.conf /etc/mosquitto/conf.d/mosquitto.conf",
#      "sudo apt update",
#      "sudo apt install mosquitto mosquitto-clients -y",
#   ]
#  }  
#}