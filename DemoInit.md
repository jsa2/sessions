
Init clean EAST for the demos 

```sh

az account clear

fld=east-$RANDOM
git clone https://github.com/jsa2/east $fld
rm .git -rf
npm install

```