@description('Name of the private endpoint')
param privateEndpointName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Virtual Network ID')
param vnetId string

@description('Subnet name for the private endpoint')
param subnetName string

@description('Resource ID of the target resource for private endpoint')
param targetResourceId string

@description('Group ID for the private endpoint (e.g., sites, sqlServer, vault)')
param groupId string

@description('Private DNS Zone ID')
param privateDnsZoneId string

@description('Tags to apply to resources')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: '${vnetId}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
  tags: tags
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(groupId, '.', '-')
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateIpAddress string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
