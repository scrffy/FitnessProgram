// project name
@minLength(3)
@maxLength(21)
@description('Name of this project')
param projectName string = 'jakebayliss'

@description('Date timestamp of when this deployment was run - defaults to UtcNow()')
param lastDeploymentDate string = utcNow('yyMMddHHmmss')

var tags = {
  project: projectName
  lastDeploymentDate: lastDeploymentDate
}

module staticSite 'staticsite.bicep' = {
  name: '${projectName}-staticsite-${lastDeploymentDate}'
  scope: resourceGroup()
  params: {
    appName: projectName
    tags: tags
  }
}
output staticSiteSettings object = staticSite.outputs.settings

module cdn 'cdn.bicep' = {
  name: '${projectName}-cdn-${lastDeploymentDate}'
  scope: resourceGroup()
  params: {
    appName: projectName
    tags: tags
    primaryEndpointName: staticSite.outputs.settings.storageAccountName
    primaryEndpointHostName: staticSite.outputs.settings.hostName
  }
}
output cdnSettings object = cdn.outputs.settings
