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
    inline = [
      #"sudo apt update && sudo apt upgrade -y",
      #"sudo apt install git python3-pip python3-zmq apt-transport-https ca-certificates gnupg -y",
      #"pip3 install --upgrade pip",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo docker run -d -ti -p 1883:1883 -p 1880:1880 niklasamslgruber/node-red-castle"
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
  name = "cloud-network-internal-allow-internet-${random_id.id.hex}"
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
