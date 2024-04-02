```shell

cd /workspaces/tf-azure-cgns-ha/policy

alias tf=terraform 

cat << EOF | tee terraform.tfvars
CPSERVER="4.210.189.93" # management IP
CPAPIKEY="1qXQlEsBsdd2RHn4p1yagw==" # api key for user api
EOF

tf init

tf plan

tf apply -auto-approve
tf apply -auto-approve -var publish=true

```