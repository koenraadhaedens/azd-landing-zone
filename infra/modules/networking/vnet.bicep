
targetScope = 'resourceGroup'

param vnetName string
param location string
param addressPrefixes array
param subnets array
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for s in subnets: {
      name: s.name
      properties: {
        addressPrefix: s.addressPrefix
        delegations: s.?delegations ?? []
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name

