output "cloud-server-public-ip" {
  value = google_compute_instance.node_red_cloud.network_interface.0.access_config.0.nat_ip
}
