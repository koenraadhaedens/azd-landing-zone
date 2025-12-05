targetScope = 'subscription'


@description('Azure region; use AZURE_LOCATION from azd.')
param location string

@description('Environment moniker, fixed to demo per requirement.')
param environment string = 'demo'

@description('Workload application name.')
param workload string = 'helloworld'

@description('Optional suffix or unique seed (e.g., short GUID) to ensure global uniqueness where needed.')
@maxLength(8)
param uniquenessSeed string = ''

@description('Enable hub resources (VNet, peering, optional firewall/bastion).')
param deployHub bool = true

// Normalize input for region short name
var locLower = toLower(location)
var regionMap = {
  westeurope: 'weu'
  eastus: 'eus'
  eastus2: 'eu2'
}
var regionShort = contains(regionMap, locLower) ? regionMap[locLower]! : 'unk'

//Generate resource group names upfront
var rgPlatformName = 'rg-platform-${workload}-${environment}-${regionShort}'
var rgHubName = 'rg-hub-${workload}-${environment}-${regionShort}'
var rgAppName = 'rg-app-${workload}-${environment}-${regionShort}'

// Import naming helpers
module names 'modules/naming/names.bicep' = {
  name: 'name-helper'
  params: {
    location: location
    environment: environment
    workload: workload
    uniquenessSeed: uniquenessSeed
  }
}

// === Landing zone resource groups (subscription level resources) ===
resource rgPlatform 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgPlatformName
  location: location
}

resource rgHub 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgHubName
  location: location
}

resource rgApp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgAppName
  location: location
}

// === Monitoring baseline (Log Analytics + diagnostics) in platform RG ===
module logAnalytics 'modules/monitoring/logAnalytics.bicep' = {
  name: 'la-workspace'
  scope: resourceGroup(rgPlatform.name)
  params: {
    name: names.outputs.laName
    location: location
    retentionInDays: 30
  }
}

module diagSettings 'modules/monitoring/diagnostics.bicep' = {
  name: 'diag-settings'
  scope: resourceGroup(rgPlatform.name)
  params: {
    workspaceResourceId: logAnalytics.outputs.workspaceId
  }
}

// === Hub networking (optional) ===
module hubVnet 'modules/networking/vnet.bicep' = if (deployHub) {
  name: 'hub-vnet'
  scope: resourceGroup(rgHub.name)
  params: {
    vnetName: names.outputs.hubVnetName
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'mgmt'
        addressPrefix: '10.0.10.0/24'
      }
    ]
    tags: names.outputs.defaultTags
  }
}

// (Placeholders – wire up once needed)
module firewall 'modules/security/firewall.placeholder.bicep' = if (deployHub) {
  name: 'hub-firewall'
  scope: resourceGroup(rgHub.name)
  params: {
    name: names.outputs.firewallName
    location: location
  }
}

module bastion 'modules/security/bastion.placeholder.bicep' = if (deployHub) {
  name: 'hub-bastion'
  scope: resourceGroup(rgHub.name)
  params: {
    name: names.outputs.bastionName
    location: location
  }
}

// === Spoke networking for workload ===
module appVnet 'modules/networking/vnet.bicep' = {
  name: 'app-vnet'
  scope: resourceGroup(rgApp.name)
  params: {
    vnetName: names.outputs.appVnetName
    location: location
    addressPrefixes: [
      '10.10.0.0/16'
    ]
    subnets: [
      { name: 'frontend', addressPrefix: '10.10.1.0/24' }
      { name: 'backend', addressPrefix: '10.10.2.0/24' }
      { name: 'privatelink', addressPrefix: '10.10.10.0/24' }
    ]
    tags: names.outputs.defaultTags
  }
}

module peeringToHub 'modules/networking/vnetPeering.bicep' = if (deployHub) {
  name: 'peering-app-to-hub'
  scope: resourceGroup(rgApp.name)
  params: {
    sourceVnetId: appVnet.outputs.vnetId
    remoteVnetId: hubVnet!.outputs.vnetId
    peeringName: names.outputs.peeringAppToHub
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// === Key Vault in app RG ===
module keyVault 'modules/keyvault/keyVault.bicep' = {
  name: 'kv'
  scope: resourceGroup(rgApp.name)
  params: {
    name: names.outputs.kvName
    location: location
    enabledForDeployment: true
    skuName: 'standard'
    tags: names.outputs.defaultTags
  }
}

// === App Gateway + WAF in frontend subnet ===
module appGw 'modules/appgateway/appGwWAF.bicep' = {
  name: 'appgw-waf'
  scope: resourceGroup(rgApp.name)
  params: {
    name: names.outputs.appGwName
    location: location
    vnetId: appVnet.outputs.vnetId
    subnetName: 'frontend'
    wafMode: 'Prevention'
    wafPolicyName: names.outputs.wafPolicyName
    tags: names.outputs.defaultTags
  }
}

// === Compute (placeholders for scale sets + ILB) ===
module ilb 'modules/compute/ilb.placeholder.bicep' = {
  name: 'internal-lb'
  scope: resourceGroup(rgApp.name)
  params: {
    name: names.outputs.ilbName
    location: location
    vnetId: appVnet.outputs.vnetId
    subnetName: 'backend'
    tags: names.outputs.defaultTags
  }
}

module vmssFrontend 'modules/compute/vmss.placeholder.bicep' = {
  name: 'vmss-frontend'
  scope: resourceGroup(rgApp.name)
  params: {
    name: names.outputs.vmssFrontendName
    location: location
    sku: 'Standard_D2s_v5'
    instanceCount: 2
    subnetName: 'frontend'
    vnetId: appVnet.outputs.vnetId
    tags: names.outputs.defaultTags
  }
}

module vmssBackend 'modules/compute/vmss.placeholder.bicep' = {
  name: 'vmss-backend'
  scope: resourceGroup(rgApp.name)
  params: {
    name: names.outputs.vmssBackendName
    location: location
    sku: 'Standard_D2s_v5'
    instanceCount: 2
    subnetName: 'backend'
    vnetId: appVnet.outputs.vnetId
    tags: names.outputs.defaultTags
  }
}
