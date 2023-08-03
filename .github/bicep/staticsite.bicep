@minLength(3)
@maxLength(21)
param appName string

param location string = resourceGroup().location

@description('Resource tags for organizing / cost monitoring')
param tags object

// randomness added to the end of storage account names
var entropy = uniqueString('${subscription().id}${resourceGroup().id}')
var storageAccountName = replace(replace(toLower(take('${appName}${entropy}', 24)), '-', ''), '_', '')

resource staticSiteStorage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

output settings object = {
  storageAccountName: storageAccountName
  hostName: replace(replace(staticSiteStorage.properties.primaryEndpoints.web, 'https://', ''), '/', '')
  url: staticSiteStorage.properties.primaryEndpoints.web
}
