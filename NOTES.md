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

ssh admin@$(terraform output -raw cpman_ip)
mgmt_cli -r true set api-settings accepted-api-calls-from 'All IP addresses' --domain 'System Data'; api restart

# create api user
mgmt_cli -r true add administrator name "api" permissions-profile "read write all" authentication-method "api key"  --domain 'System Data' --format json

# add api-key
# https://sc1.checkpoint.com/documents/latest/APIs/index.html#cli/add-api-key~v1.9.1%20
mgmt_cli -r true add api-key admin-name "api"  --domain 'System Data' --format json



# connect to Linux
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
 terraform apply -replace module.linux1.azurerm_linux_virtual_machine.linuxvm