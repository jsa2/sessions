

## Develop new control


**Service deployed**


https://github.com/Azure/reddog-containerapps/blob/main/README.md

### Perform
[Review the ingress setting](https://portal.azure.com/#@thx138.onmicrosoft.com/resource/subscriptions/6193053b-408b-44d0-b20f-4e29b9b67394/resourceGroups/eastReddog/providers/Microsoft.App/containerApps/reddog/ingress)


###  enter breakpoints 
pluginRunner.js

![](20221202131847.png)  

main.js

![](20221202131929.png)  

### Setup launch file
```json
{
    // Use IntelliSense to learn about possible attributes. muutos
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "type": "pwa-node",
            "request": "launch",
            "name": "Launch Program",
            "skipFiles": [
                "<node_internals>/**"
            ],
"program": "${workspaceFolder}/plugins/main.js",
//  "program": "${file}",
            "args":  [
                "--batch=10",   
                //"--tag=svc=aksdev",
                "--nativescope=true",
              /*   "--roleAssignments", */
               // "--checkAad",
               // "--helperTexts",
               "--subInclude=3539c2a2-cd25-48c6-b295-14e59334ef1c",
                "--namespace=reddog",
                //"--notIncludes=44ee6398gb8abb6d0",
                //"--policy",
           /*      "--nx", */
                //"--asb",
                "--scanAuditLogs",
              /*   "--composites", */
               "--clearTokens",
               //"--azdevops=thx138",
               // "--ignorePreCheck",
           //    "--reprocess",
           "--SkipStorageThrottling",
           "--includeRG"
            ]
        }
    ]
  }
```

## Init SubProvider
```sh

name="containerApps_ingressReview"
provider="microsoft.app/containerapps"
node controlTemplateSubProvider.js --name $name --provider $provider

```

## change API version to match that of the request

insert this to the `` {"apiversion":"2022-06-01-preview"} ``

![](20221202131553.png)  

create .skip.json for 'managedenvironments'

``.skip.json`` 
```
["microsoft.app/managedenvironments"]
```

## Add ingress check
```js
const { AzNodeRest } = require("../../../../plugins/nodeSrc/east")
const { returnObjectInit } = require("../../../../plugins/nodeSrc/returnObjectInit")


//AzNodeRest
module.exports = async function (item) {
    
let returnObject = new returnObjectInit (item,__filename.split('/').pop())


returnObject.isHealthy=true


if (item?.properties?.configuration?.ingress?.external == true && !item?.properties?.configuration?.ingress?.ipSecurityRestrictions ) {

    returnObject.isHealthy="review"
}

returnObject.metadata = item?.properties?.configuration?.ingress || {}
//console.log(stashOrig)

return returnObject

}
```


---
