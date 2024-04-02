output "linux_key" {
  value     = module.linux.ssh_key
  sensitive = true
}

output "linux_ssh_config" {
  value = module.linux.ssh_config
}

data "azurerm_public_ip" "cpman" {
  name                = "checkpoint-mgmt-terraform"
  resource_group_name = "checkpoint-mgmt-terraform"
}

output "cpman_ip" {
  value = data.azurerm_public_ip.cpman.ip_address
}