# Define variables
SUBSCRIPTION="Microsoft Azure Sponsorship"
RESOURCEGROUP="rg-spoof"
LOCATION="westeurope"
PLANNAME="ASP-rgspoof-9fd8"
PLANSKU="P1v2"
SITENAME='faugspoof'
RUNTIME='NODE|16-lts'

# Fetch the current public IP address
MY_IP_ADDRESS=$(curl -s ifconfig.me)/32

# Set the Azure subscription context
az account set --subscription "$SUBSCRIPTION"


# Add an IP restriction to only allow access from the current IP address
az webapp config access-restriction add --resource-group $RESOURCEGROUP --name $SITENAME --rule-name "AllowMyIP" --action Allow --ip-address $MY_IP_ADDRESS --priority 100
