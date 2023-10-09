//set params (default values) for resources
param location string = resourceGroup().location
//make the storage name length min 3 , max 24 chars
@minLength(3)
@maxLength(24)
//now I can set the storage name
param name string = 'storagetoso1'
//list allowed storages
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
//now I can assign the storage I want
param type string = 'Standard_LRS'

//create a var for the container name
var containerName = 'images'

//create a resource with a symbolic name to Bicep, not the real name (storageAccount)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: type
  }
}
//create a container inside the storage account
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/${containerName}'
}
//output storage ID
output storageID string = storageAccount.id
