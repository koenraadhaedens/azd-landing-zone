
targetScope = 'resourceGroup'

param sourceVnetId string
param remoteVnetId string
param peeringName string
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource srcPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: '${split(sourceVnetId, '/')[8]}/${peeringName}'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowForwardedTraffic: allowForwardedTraffic
    allowVirtualNetworkAccess: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}
