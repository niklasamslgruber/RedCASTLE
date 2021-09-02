output "cloud-server-node-red-public" {
  value = "http://${google_compute_instance.node_red_cloud.network_interface.0.access_config.0.nat_ip}:1880"
}

output "emulator-node-red-public" {
  value = "http://${google_compute_instance.emulator_cloud.network_interface.0.access_config.0.nat_ip}:1880"
}

output "mqtt-broker-mqtt-public" {
  value = "${google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip}:1883"
}

output "mqtt-broker-dashboard-public" {
  value = "http://${google_compute_instance.mqtt_broker_cloud.network_interface.0.access_config.0.nat_ip}:15672"
}



