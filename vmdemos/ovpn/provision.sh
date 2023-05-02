

rm east* -rf 

az vm image list --publisher OpenVPN --all

az account set --subscription "microsoft azure sponsorship"
rg="rg-honeyP"
vm="ovpnDemo$RANDOM"
location=westeurope
kvName=eastdemokv
pw=$(cat /proc/sys/kernel/random/uuid)"\+1\!Sda"
MY_IP_ADDRESS=$(curl -s ifconfig.me)/32
vmRg=rg-$vm
storageAcc=storage$(head /dev/urandom | tr -dc a-z | head -c10)

az group create -n $vmRg \
-l $location \
--tags="svc=ovpn"


nsg=$(az network nsg create --name tempNSG --resource-group $vmRg --location $location)
nsgId=$( echo $nsg | jq -r '.NewNSG.id' )
scope=$( echo $nsg | jq -r '.NewNSG.id' | cut -d "/" -f2,3,4,5)
az network nsg rule create --name "allow-my-ip" --nsg-name tempNSG --resource-group $vmRg --priority 100 --source-address-prefixes $MY_IP_ADDRESS --destination-address-prefixes '*' --access Allow --protocol "*" --direction Inbound --destination-port-ranges '*'


vmOut=$(az vm create --resource-group $vmRg \
--name $vm \
--nsg $nsgId \
--image "openvpn:openvpnas:openvpnas:2.11.03" \
--admin-username openvpn --admin-password $pw \
--nic-delete-option delete \
--os-disk-delete-option delete \
--public-ip-sku Standard 
)

echo "$vmOut"  > spec.json
echo $pw > pw.txt

# Metadata about the VM and identity

identity=$(echo $vmOut | jq -r '.identity.systemAssignedIdentity')
ip=$(echo $vmOut | jq -r '.publicIpAddress')
echo $pw
ssh openvpn@$ip
EKAikii5odiu


az vm delete --name $vm --resource-group $vmRg  --yes --no-wait  --force-deletion none
az group delete -n $vmRg --no-wait --yes
