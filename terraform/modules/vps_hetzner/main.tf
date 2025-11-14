resource "hcloud_server" "main" {
  name        = var.server_name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = var.ssh_keys
  user_data   = var.user_data

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    role        = "application"
  }

  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "hcloud_server_network" "main" {
  server_id  = hcloud_server.main.id
  network_id = var.network_id
  ip         = var.private_ip
}

# Creazione automatica del volume per LUKS
resource "hcloud_volume" "luks_volume" {
  name      = "${var.server_name}-luks-volume"
  size      = var.luks_volume_size
  server_id = hcloud_server.main.id
  location  = var.location
  format    = "ext4"
}
