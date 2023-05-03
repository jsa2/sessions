

az account set --subscription "microsoft azure sponsorship"
rg="rg-honeyP"
vm="eastdemovm9449"
location=westeurope
kvName=eastdemokv
pw=$(cat /proc/sys/kernel/random/uuid)"\+1\!Sda"
MY_IP_ADDRESS=$(curl -s ifconfig.me)/32
vmRg=rg-$vm
storageAcc=storagejedsoxanpp


storage=$(az storage account show -n storagejedsoxanpp)

storagePath=https://management.azure.com$( echo $storage | jq -r '.id' )"/listKeys?api-version=2022-09-01"


vmOut=$(az vm show --resource-group $vmRg --name $vm )

# Reboot to force token renewal
# ssh -i tempkeys/tempkey azureuser@$ip 'sudo reboot now -f'
# Metadata about the VM and identity

ip=$(az vm list-ip-addresses -g $vmRg -n $vm --query " [].virtualMachine.network.publicIpAddresses [*].ipAddress" -o tsv)


ssh -i tempkeys/tempkey azureuser@$ip 'sudo apt update -y; sudo apt install jq -y'


# Read AKV

ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true  | jq .access_token  | sed 's/\"//g'); curl -s 'https://eastdemokv.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01' -H \"Authorization: Bearer \$at\" | jq ."

# List Storage Account Keys

ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -H Metadata:true  | jq .access_token  | sed 's/\"//g'); curl -s -d "{}" '$storagePath' -H \"Authorization: Bearer \$at\" | jq ."


# audit with east

fld=east-$RANDOM
git clone https://github.com/jsa2/east $fld -b preview

##  review composite_AzureKeyVault_ReviewCallers VM_ManagedIdentity
echo "node ./plugins/main.js --batch=10 --nativescope=true --namespace=resourceGroups/rg-honeyP,$vmRg --composites --clearTokens --SkipStorageThrottling"


# access bheast folder at home
echo "node ./plugins/main.js --batch=10 --nativescope=true --namespace=resourceGroups/rg-honeyP,rg-eastdemovm9449 --composites --clearTokens --SkipStorageThrottling --scanAuditLogs=20 --composites --clearTokens --SkipStorageThrottling --checkAad"


#WSL or other Linux distro
G=$(az group list --tag 'svc=honeypot' --query "[].{name:name}" -o tsv) 

for res in $G
do
 echo "az group delete --id $res"
 az group delete --name $res --no-wait -y
done

sudo rm tempkeys -rf
