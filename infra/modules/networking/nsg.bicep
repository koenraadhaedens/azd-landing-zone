@description('Name of the Network Security Group')
param nsgName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Security rules for the NSG')
param securityRules array = []

@description('Tags to apply to resources')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
  tags: tags
}

output nsgId string = nsg.id
output nsgName string = nsg.name
