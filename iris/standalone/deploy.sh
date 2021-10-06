#!/bin/bash 

rg=IRIS-Group
#branch=master
branch=$(git branch | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')

echo "deleting a resource group"
az group delete --name $rg --yes
echo "creating a resource group"
az group create --name $rg --location "Japan East"

az deployment group create \
  --name ExampleDeployment \
  --resource-group $rg \
  --template-uri "https://raw.githubusercontent.com/IRISMeister/azure-arm/$branch/iris/standalone/azuredeploy.json" \
  --parameters @azuredeploy.parameters.json

az vm list-ip-addresses --resource-group $rg --output table
az network public-ip list --resource-group $rg --output table
