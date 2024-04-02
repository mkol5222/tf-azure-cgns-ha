resource "checkpoint_management_publish" "example" {
  count    = var.publish ? 1 : 0
  triggers = ["${timestamp()}"]

  depends_on = [ checkpoint_management_host.localhost,
  checkpoint_management_network.net_linux ,
  checkpoint_management_dynamic_object.lgwe ,
  checkpoint_management_host.linux1
  ]
}