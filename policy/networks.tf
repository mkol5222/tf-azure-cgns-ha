resource "checkpoint_management_network" "net_linux" {
    broadcast    = "allow"
    color        = "black"

    mask_length4 = 24
    name         = "net_linux"
    nat_settings = {
        "auto_rule"   = "true"
        "hide_behind" = "gateway"
        "install_on"  = "All"
        "method"      = "hide"
    }
    subnet4      = "10.247.135.0"
    tags         = []
}