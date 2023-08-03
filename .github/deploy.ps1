Param(
  [String]$deploymentName = 'deploy',

  [Parameter(Mandatory = $true)]
  [String]$resourceGroup,

  [Parameter(Mandatory = $false)]
  [Switch]$deploy = $false
)

# NOTE: You must have logged in via 'az login' before running this deployment

Write-Host "Creating Parameters"
$parameters = New-Object PSObject -Property @{
  '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
  contentVersion = "1.0.0.0"
}

if (Test-Path ./azuredeploy.parameters.json) 
{
  Remove-Item ./azuredeploy.parameters.json
}

$parameters | ConvertTo-Json -Depth 100 | Out-File ./azuredeploy.parameters.json

Write-Host "Running What-If on bicep"
az deployment group what-if `
  --template-file .\Azure\bicep\azuredeploy.bicep `
  -g $resourceGroup 
  #--parameters '@azuredeploy.parameters.json'

if ($deploy -eq $true) {
  Write-Host "Deploying bicep"
  $output = (az deployment group create `
    --template-file .\.github\bicep\azuredeploy.bicep `
    -g $resourceGroup `
    --name "$($deploymentName)" `
    --mode Incremental)|
    #--parameters '@azuredeploy.parameters.json') |
  ConvertFrom-Json

  $output.properties.outputs.staticSiteSettings.value.PSObject.Properties | ForEach-Object {
    Write-Host "##vso[task.setvariable variable=staticSite$($_.Name);isOutput=true]$($_.Value)"
  }

  $output.properties.outputs.cdnSettings.value.PSObject.Properties | ForEach-Object {
    Write-Host "##vso[task.setvariable variable=cdn$($_.Name);isOutput=true]$($_.Value)"
  }

  if (!$?) {
    Write-Host "Deploying Bicep failed... aborting!"
    exit 1
  }

  Write-Host "Enabling Static Website hosting on storage account (can't be done in template)"
  $staticSiteSettings = $output.properties.outputs.staticSiteSettings.value

  $storageAccountKeys = (az storage account keys list -g $resourceGroup -n $staticSiteSettings.storageAccountName) | ConvertFrom-Json
  az storage blob service-properties update `
      --account-name $staticSiteSettings.storageAccountName `
      --account-key $storageAccountKeys[0].value `
      --static-website `
      --404-document index.html `
      --index-document index.html

  if (!$?) {
      Write-Host "Deploying Bicep failed... aborting!"
      exit 1
  }
}

Write-Host "Done"
