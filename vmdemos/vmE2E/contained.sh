
git clone https://github.com/jsa2/sessions -b ug vmdemos
rm east* -rf 

# Generate RSA key pair
mkdir tempkeys

ssh-keygen -t rsa -b 4096 -C "tempkey" -f "tempkeys/tempkey" -N ""
chmod 700 tempkeys
chmod 600 tempkeys/*

az account set --subscription "microsoft azure sponsorship"

RAN=$RANDOM
vm="diagSettingsModify$RAN"
location=westeurope
kvName="diagSettingsModify$RAN"
pw=$(cat /proc/sys/kernel/random/uuid)"\+1\!Sda"
MY_IP_ADDRESS=$(curl -s ifconfig.me)/32
vmRg=rg-$vm
rg=$vmRg
storageAcc=storage$(head /dev/urandom | tr -dc a-z | head -c10)


az group create -n $vmRg \
-l $location \
--tags="svc=honeypot"

az keyvault create -n $kvName -g $rg -o tsv --query "id" --no-wait

wsid=$(az monitor log-analytics workspace create --location $location -g $rg  -n laws${RAN} -o tsv --query "id")

kvId=$(az keyvault show -n $kvName -g $rg -o tsv --query "id")

az monitor diagnostic-settings create --resource $kvId --name "Key vault logs"  --workspace $wsid --logs '[{"category": "AuditEvent","enabled": true}]' 



# az monitor diagnostic-settings create --resource $kvId --name "Key vault logs"  --workspace hublaws --logs '[{"category": "AuditEvent","enabled": true}]' 


nsg=$(az network nsg create --name tempNSG --resource-group $vmRg --location $location)
nsgId=$( echo $nsg | jq -r '.NewNSG.id' )
scope=$( echo $nsg | jq -r '.NewNSG.id' | cut -d "/" -f2,3,4,5)
az network nsg rule create --name "allow-my-ip" --nsg-name tempNSG --resource-group $vmRg --priority 100 --source-address-prefixes $MY_IP_ADDRESS --destination-address-prefixes '*' --access Allow --protocol "*" --direction Inbound --destination-port-ranges '*'


storage=$(az storage account create -n $storageAcc  -g $vmRg --kind storageV2 -l $location -t Account --sku Standard_LRS)
storagePath=https://management.azure.com$( echo $storage | jq -r '.id' )"/listKeys?api-version=2022-09-01"


vmOut=$(az vm create --resource-group $vmRg \
--name $vm \
--nsg $nsgId \
--image Ubuntu2204 \
--nic-delete-option delete \
--os-disk-delete-option delete \
--public-ip-sku basic \
--admin-username azureuser \
--ssh-key-values tempkeys/tempkey.pub
)

echo $vmOut
# Enable Managed Identity and required permissions for key vault and monitor
identity=$(az vm identity assign -g  $vmRg  -n $vm --role "Storage Account Contributor" --scope $scope -o tsv --query "systemAssignedIdentity")

# Reboot to force token renewal
# ssh -i tempkeys/tempkey azureuser@$ip 'sudo reboot now -f'
# Metadata about the VM and identity

ip=$(echo $vmOut | jq -r '.publicIpAddress');echo $ip

ssh -i tempkeys/tempkey azureuser@$ip 'sudo apt update -y; sudo apt install jq -y'

# Assign Azure AD OAuth2 Permissions

GraphAppId=00000003-0000-0000-c000-000000000000
graphspn=$(az rest --method get --url "https://graph.microsoft.com/v1.0/servicePrincipals?\$search=\"appId:$GraphAppId\"""&\$select=displayName,id" --resource "https://graph.microsoft.com" --headers "ConsistencyLevel=eventual" -o tsv --query 'value' |cut -f2)

# Add permissions to tenant Creator

az rest --method post --url "https://graph.microsoft.com/v1.0/servicePrincipals/$identity/appRoleAssignments" --resource "https://graph.microsoft.com" \
--body "{\"principalId\": \"$identity\",\"resourceId\": \"$graphspn\",\"appRoleId\": \"7ab1d382-f21e-4acd-a863-ba3e13f7da61\"}" 


# Assign AAD Role to the SPN
az rest --method post --url "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments" --resource "https://graph.microsoft.com" \
--body "{\"principalId\": \"$identity\",\"roleDefinitionId\": \"cf1c38e5-3621-4004-a7cb-879624dced7c\", \"directoryScopeId\": \"\/\" }" 





secretvalue=$(openssl rand -base64 21)

az keyvault set-policy --name $kvName --object-id $identity --secret-permissions get -g $rg

az keyvault secret set --name vmsecret --vault-name $kvName --value $secretvalue



# Read AKV

ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true  | jq .access_token  | sed 's/\"//g'); curl -s 'https://$kvName.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01' -H \"Authorization: Bearer \$at\" | jq ."

# List Storage Account Keys

ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -H Metadata:true  | jq .access_token  | sed 's/\"//g'); curl -s -d "{}" '$storagePath' -H \"Authorization: Bearer \$at\" | jq ."


# audit with east

fld=east-$RANDOM
git clone https://github.com/jsa2/east $fld 

##  review composite_AzureKeyVault_ReviewCallers VM_ManagedIdentity
echo "node ./plugins/main.js --batch=10 --nativescope=true --namespace=resourceGroups/rg-honeyP,$vmRg --composites --clearTokens --SkipStorageThrottling"


#WSL or other Linux distro
G=$(az group list --tag 'svc=honeypot' --query "[].{name:name}" -o tsv) 

for res in $G
do
 echo "az group delete --id $res"
 az group delete --name $res --no-wait -y
done

rm tempkeys -rf
