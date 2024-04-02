resource "checkpoint_management_access_rule" "rule99" {
  layer    = "${checkpoint_management_package.this.name} Network"

  position = {top = "top"}
  name     = "from linux network"

  source = [checkpoint_management_network.net_linux.name ]

  destination        = ["Any"]
  destination_negate = false

  service            = ["Any"]
  service_negate     = false

  action             = "Accept"
  action_settings = {
    enable_identity_captive_portal = false
  }

  track = {
    accounting              = false
    alert                   = "none"
    enable_firewall_session = true
    per_connection          = true
    per_session             = true
    type                    = "Log"
  }
}
