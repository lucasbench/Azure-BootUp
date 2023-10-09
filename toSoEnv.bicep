//define params
@description('VM size')
param vmSize string = 'Standard_B1s'
param location string = resourceGroup().location
@description('VM name Prefix')
param vmName string = 'toso-vm'
@description('Number of VMs')
param vmCount int = 2
@description('Admin username')
param adminUsername string
@description('Admin password')
@secure()
param adminPassword string
@description('Virtual network name')
param vnetName string = 'toso-vnet1'

//defines vars
var nics = 'toso-nic'
var subnetName = 'subnet'
var subnet0Name = 'subnet0'
var subnet1Name = 'subnet1'

//define resources to loop through
resource vmName_resource 'Microsoft.Compute/virtualMachines@2023-07-01' = [for i in range(0, vmCount): {
  name: '${vmName}${i}'
  location: location
  properties: {
    osProfile: {
      computerName: '${vmName}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: resourceId('Microsoft.Network/networkInterfaces', '${nics}${i}')
        }
      ]
    }
  }
  dependsOn: [
    vnet
  ]
}]
//create a Vnet and subnets
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.40.0.0/22'
      ]
    }
    subnets: [
      {
        name: subnet0Name
        properties: {
          addressPrefix: '10.40.0.0/24'
        }
      }
      {
        name: subnet1Name
        properties: {
          addressPrefix: '10.40.1.0/24'
        }
      }
    ]
  }
}
//create nics
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = [for i in range(0, vmCount): {
  name: '${nics}${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, '${subnetName}${i}')
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}]


//Deploy
//New-AzResourceGroup -Name ToSoRG -Location "east US"
//New-AzResourceGroupDeployment -ResourceGroupName ToSoRG -TemplateFile ./toSoEnv.bicep -adminUsername "tinto"
