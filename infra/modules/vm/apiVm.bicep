@description('Name of the Virtual Machine')
param vmName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Administrator username for the VM')
param adminUsername string = 'azureuser'

@description('Administrator password for the VM')
@secure()
param adminPassword string

@description('Virtual Machine size')
param vmSize string = 'Standard_D2s_v6'

@description('Virtual Network ID')
param vnetId string

@description('Subnet name for the VM')
param subnetName string

@description('Network Security Group resource ID')
param nsgId string

@description('Managed Identity resource ID for the VM')
param managedIdentityId string

@description('Tags to apply to resources')
param tags object = {}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  tags: tags
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 128
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: tags
}

// Install Azure CLI and configure the VM
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'CustomScript'
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'apt-get update && apt-get install -y curl && curl -sL https://aka.ms/InstallAzureCLIDeb | bash && apt-get install -y dotnet-sdk-8.0'
    }
  }
}

output vmId string = vm.id
output vmName string = vm.name
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
output networkInterfaceId string = networkInterface.id
