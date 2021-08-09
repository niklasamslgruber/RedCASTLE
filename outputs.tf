output "cloud-server-public-ip" {
  value = google_compute_instance.node_red_cloud.network_interface.0.access_config.0.nat_ip
}

output "mqtt-broker-public-ip" {
  value = google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip
}

output "emulator-public-ip" {
  value = google_compute_instance.emulator_cloud.network_interface.0.access_config.0.nat_ip
}

