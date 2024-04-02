# Azure CGNS HA upgrade

```shell
# login to Azure
az login
az account list -o table

# working folder
cd /workspaces/tf-azure-cgns-ha

# create Owner SP for your subcription to use with TF
./create-az-sp-for-cp-tf.sh
# save credentials in "Keepass"

# save to (not versioned in GIT) ./terraform.tfvars (it is in .gitignore to prevent secrets leaking)
cat <<EOF | tee ./terraform.tfvars
client_secret = "i1F8Qxxx"
client_id = "3230xx"
tenant_id = "01605c2xx"
subscription_id = "f4ad5xxx"
EOF


# aliast
alias tf=terraform

# build
tf init -upgrade
tf apply -target module.vnet -auto-approve

tf destroy -target module.cpman -auto-approve

# SC1 token! - in case we use Smart-1 Cloud management
tf apply -target module.cpha1 -auto-approve
tf apply -target module.linux -auto-approve

# on cpman

# wait for cpman initialization - e.g. on serial console
#   or on SSH: tail -f /var/log/cloud_config.log
ssh admin@$(terraform output -raw cpman_ip)

# is FTCW done? AFTER run_cmd Executing: config_system
tail -f /var/log/cloud_config.log

# is management ready (API readiness test != FAILED)
watch -d api status

# allow API access
mgmt_cli -r true set api-settings accepted-api-calls-from 'All IP addresses' --domain 'System Data'; api restart
# create api user
mgmt_cli -r true add administrator name "api" permissions-profile "read write all" authentication-method "api key"  --domain 'System Data' --format json

# add api-key
# https://sc1.checkpoint.com/documents/latest/APIs/index.html#cli/add-api-key~v1.9.1%20
mgmt_cli -r true add api-key admin-name "api"  --domain 'System Data' --format json
# public IP?
curl_cli ip.iol.cz/ip/

mgmt_cli -r true add simple-cluster name "cpha"\
    color "pink"\
    version "R81.20"\
    ip-address "10.247.136.6"\
    os-name "Gaia"\
    cluster-mode "cluster-xl-ha"\
    firewall true\
    vpn false\
    interfaces.1.name "eth0"\
    interfaces.1.ip-address "10.247.136.6"\
    interfaces.1.network-mask "255.255.255.240" \
    interfaces.1.interface-type "cluster"\
    interfaces.1.topology "EXTERNAL"\
    interfaces.1.anti-spoofing false \
    interfaces.2.name "eth1"\
    interfaces.2.interface-type "sync"\
    interfaces.2.topology "INTERNAL"\
    interfaces.2.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask"\
    interfaces.2.topology-settings.interface-leads-to-dmz false\
    interfaces.2.anti-spoofing false \
    members.1.name "cpha1"\
    members.1.one-time-password "WelcomeHome1984"\
    members.1.ip-address "10.247.136.4"\
    members.1.interfaces.1.name "eth0"\
    members.1.interfaces.1.ip-address "10.247.136.4"\
    members.1.interfaces.1.network-mask "255.255.255.240"\
    members.1.interfaces.2.name "eth1"\
    members.1.interfaces.2.ip-address "10.247.136.21"\
    members.1.interfaces.2.network-mask "255.255.255.240"\
    members.2.name "cpha2"\
    members.2.one-time-password "WelcomeHome1984"\
    members.2.ip-address "10.247.136.5"\
    members.2.interfaces.1.name "eth0"\
    members.2.interfaces.1.ip-address "10.247.136.5"\
    members.2.interfaces.1.network-mask "255.255.255.240"\
    members.2.interfaces.2.name "eth1"\
    members.2.interfaces.2.ip-address "10.247.136.22"\
    members.2.interfaces.2.network-mask "255.255.255.240"\
    --format json

# now we have CPMAN IP and API KEY - make the note
#    e.g. 4.210.189.93 / 1qXQlEsBsdd2RHn4p1yagw==

# connect to Linux
alias tf=terraform
mkdir -p ~/.ssh
tf output -raw linux_key > ~/.ssh/linux1.key
chmod o= ~/.ssh/linux1.key
chmod g= ~/.ssh/linux1.key
tf output -raw linux_ssh_config
tf output -raw linux_ssh_config | tee -a  ~/.ssh/config
# or OVERWRITE!!!
tf output -raw linux_ssh_config | tee  ~/.ssh/config
# should get Ubuntu machine prompt
ssh linux1
# while true; do ping -c 1 1.1.1.1; curl -s ip.iol.cz/ip/ -m1; echo; sleep 2; done


# remember front end LB rule 80->cpha:8080

# remember NGSs allowing 8080 to members eth0

# remember routing from net-linux via CP!
terraform apply -auto-approve -var route_through_firewall=true


#####
# destroy
# NODE1 active before destroy - wait for VIP move!!!

tf destroy -target module.linux -auto-approve
# NODE1 active before destroy
tf destroy -target module.cpha1 -auto-approve
tf destroy -target module.vnet -auto-approve

# delete SP(s)
az ad sp list --all --show-mine -o table
az ad sp list --display-name CPHAdeployer --query "[].{id:appId}" -o tsv
az ad sp list --display-name CPHAReader --query "[].{id:appId}" -o tsv
az ad sp delete --id $(az ad sp list --display-name CPHAdeployer --query "[].{id:appId}" -o tsv)
az ad sp delete --id $(az ad sp list --display-name CPHAReader --query "[].{id:appId}" -o tsv)
az ad sp list --all --show-mine -o table


---
### replacing Linux - e.g. to reinstall from scratch
tf apply -target module.linux -replace module.linux.azurerm_linux_virtual_machine.linuxvm -a
uto-approve