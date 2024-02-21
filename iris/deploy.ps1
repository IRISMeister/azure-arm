<#
DIR=$(pwd)
target=${DIR##*/}
if [ "$target" = "iris" ]; then
    echo "Use this script from one of the folders underneath"
    exit 1
fi

rg=IRIS-Group
#branch=master
branch=$(git branch | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')

echo "deleting a resource group ${rg}"
az group delete --name $rg --yes
echo "creating a resource group ${rg}"
az group create --name $rg --location "Japan East"

echo "deploying $target"
az deployment group create \
  --name ExampleDeployment \
  --resource-group $rg \
  --template-uri "https://raw.githubusercontent.com/IRISMeister/azure-arm/$branch/iris/$target/azuredeploy.json" \
  --parameters @azuredeploy.parameters.json

az vm list-ip-addresses --resource-group $rg --output table
az network public-ip list --resource-group $rg --output table
#>

$target="standalone"
$rg="IRIS-Group"
$branch="dev"

Write-Host "deleting a resource group ${rg}"
az group delete --name $rg --yes
Write-Host "creating a resource group ${rg}"
az group create --name $rg --location "Japan East"

Write-Host "deploying $target"

Write-Host "https://raw.githubusercontent.com/IRISMeister/azure-arm/$branch/iris/$target/azuredeploy.json"
az deployment group create `
  --name ExampleDeployment `
  --resource-group $rg `
  --template-uri "https://raw.githubusercontent.com/IRISMeister/azure-arm/$branch/iris/$target/azuredeploy.json" `
  --parameters '@azuredeploy.parameters.json'
