module "vps_hetzner" {
  source = "../../modules/vps_hetzner"

  server_name    = "prod-app-server"
  server_type    = "cpx21"  # 4 vCPU, 8GB RAM
  image          = "ubuntu-22.04"
  location       = "hel1"   # Helsinki
  ssh_keys       = [var.admin_ssh_key_fingerprint]
  user_data      = templatefile("${path.module}/cloud-init.yml.tpl", {
    vault_addr = var.vault_addr
  })
  environment = "prod"
}

resource "vault_generic_secret" "luks_passphrase" {
  path = "secret/luks/prod/${module.vps_hetzner.server_name}"

  data_json = jsonencode({
    passphrase = random_password.luks.result
  })
}

resource "random_password" "luks" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Output per Ansible
output "server_ip" {
  value = module.vps_hetzner.ipv4_address
}

output "server_id" {
  value = module.vps_hetzner.server_id
}

output "luks_passphrase_path" {
  value = vault_generic_secret.luks_passphrase.path
}

output "vault_token" {
  value     = vault_token.github_actions.client_token
  sensitive = true
}
