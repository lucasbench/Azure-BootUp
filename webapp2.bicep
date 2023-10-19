@description('Application Name')
@maxLength(30)
param applicationName string = 'to-do-app${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('App Service Plan\'s pricing tier. Details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
param appServicePlanTier string = 'P1V2'

@minValue(1)
@maxValue(3)
@description('App Service Plan\'s instance count')
param appServicePlanInstances int = 1

@description('The URL for the GitHub repository that contains the project to deploy.')
param repositoryUrl string = 'https://github.com/lucasbench/Azure-BootUp'

@description('The branch of the GitHub repository to use.')
param branch string = 'main'


var websiteName = applicationName
var appServicePlanName = applicationName


resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanTier
    capacity: appServicePlanInstances
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2021-01-01' = {
  name: websiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      http20Enabled: true
    }
  }
}

resource srcControls 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${appService.name}/web'
  properties: {
    repoUrl: repositoryUrl
    branch: branch
    isManualIntegration: true
  }
}
