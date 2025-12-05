
targetScope = 'resourceGroup'

param name string
param location string
param enabledForDeployment bool = true
param skuName string = 'standard'
param tags object = {}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: enabledForDeployment
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    sku: { family: 'A', name: toUpper(skuName) }
    accessPolicies: [] // Using RBAC
    publicNetworkAccess: 'Enabled'
  }
}

output keyVaultId string = kv.id
