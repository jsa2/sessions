#!/bin/bash

# Check if the storage account name argument is provided
if [ -z "$1" ]; then
    echo "Error: Storage account name argument is missing."
    exit 1
fi

storage_account_name="$1"

# Download and install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Set the NVM_DIR environment variable
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js version 16
nvm install 16

# Set Node.js version 16 as the default
nvm alias default 16

# Clone the repository
git clone https://github.com/jsa2/sessions/ --branch Azure_security_ug
cd sessions

# Install npm dependencies
npm install

# Run the script with the provided storage account name argument
node writeToBlob.js "$storage_account_name"
