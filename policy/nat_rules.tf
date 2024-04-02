resource "checkpoint_management_nat_rule" "linux1" {

position = {top = "top"}

        
    enabled                = true
    
    install_on             = []
    method                 = "static"
    name                   = "linux1web"
    original_destination   = "LocalGatewayExternal"
    original_service       = "HTTP_proxy"
    original_source        = "Any"
    package                = "azure-cpha"
    translated_destination = "linux1"
    translated_service     = "http"
    translated_source      = "Original"

}