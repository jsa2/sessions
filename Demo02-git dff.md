

## Diffing control drifts/changes

![](20221201130059.png)  

### Perform
[access this storage account](https://portal.azure.com/#@thx138.onmicrosoft.com/resource/subscriptions/3539c2a2-cd25-48c6-b295-14e59334ef1c/resourceGroups/rg-faug/providers/Microsoft.Storage/storageAccounts/functionfaugexfil/containersList)

```sh

# Clone new version of EAST
folder=BHEU$RANDOM
git clone https://github.com/jsa2/EAST -b preview $folder
cd $folder
npm install

# rm existing git
rm .git -rf 

git init

rg="rg-faug"
acc="functionfaugexfil"
container="public"
set az account --subscription "3539c2a2-cd25-48c6-b295-14e59334ef1c"

## ensure no previous container exists
az storage container delete -n $container --account-name $acc --auth-mode login

## Create initial scan
node ./plugins/main.js --batch=10 --nativescope=true --subInclude=3539c2a2-cd25-48c6-b295-14e59334ef1c \
--namespace=functionfaugexfil --clearTokens --SkipStorageThrottling 

## commit to git
git add .; git commit -m "sd"

## create public container
az storage container create -n $container  --public-access blob -g $rg --account-name $acc --auth-mode login

node ./plugins/main.js --batch=10 --nativescope=true --subInclude=3539c2a2-cd25-48c6-b295-14e59334ef1c --namespace=functionfaugexfil --clearTokens --SkipStorageThrottling

git add .; git commit -m "sd"

git diff HEAD^1

```

---
