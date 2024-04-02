resource "checkpoint_management_host" "localhost" {
    name = "localhost"
    ipv4_address = "127.0.0.1"

}

resource "checkpoint_management_host" "linux1" {
    name = "linux1"
    ipv4_address = "10.247.135.4"

}