## Relationship between objects

This demo will demonstrate VM, it's identity, it's relation to key vault, and logs that are produced on the key vault after the demo



```

Init clean EAST for the demos 

az account clear

folder=BHEU$RANDOM
git clone https://github.com/jsa2/EAST -b preview $folder
cd $folder
npm install

```

Replace composite from EAST folder


```sh
# Assign identity to VM 
az account set --subscription "microsoft azure sponsorship"
rg="rg-honeyP"
vm="eastdemovm"
location=westeurope
kvName=eastdemokv

secretvalue=$(openssl rand -base64 21)

identity=$(az vm identity assign -g $rg -n $vm --role Reader --scope "subscriptions/3539c2a2-cd25-48c6-b295-14e59334ef1c/resourceGroups/rg-honeyP" -o tsv --query "systemAssignedIdentity")

az keyvault set-policy --name $kvName --object-id $identity --secret-permissions get -g $rg

az keyvault secret set --name vmsecret --vault-name $kvName --value $secretvalue

```

**In vm**
```sh
ssh joosua@bheu.westeurope.cloudapp.azure.com

at=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true  | jq .access_token  | sed 's/\"//g')

https://eastdemokv.vault.azure.net/secrets/vmsecret/

curl -s 'https://eastdemokv.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01' -H "Authorization: Bearer $at" | jq .

```

**in east**

```

node ./plugins/main.js --batch=10 --nativescope=true --namespace=resourceGroups/rg-honeyP --composites --clearTokens --SkipStorageThrottling 

``` 

Review controls

- VM_ManagedIdentity
  - linkedKeyVaults
- composite_AzureKeyVault_ReviewCallers
  - callers

# Clean

```sh

az vm identity remove -g $rg -n $vm

az keyvault delete-policy --name $kvName --object-id $identity

```


# Bonus

Show case a scenario that maps AAD role, API permissions, Azure RBAC and keyvault roles in single result

`` node ./plugins/main.js --batch=10 --nativescope=true --namespace=RG-FN-22114 --composites --clearTokens --SkipStorageThrottling --checkAad=true `` 