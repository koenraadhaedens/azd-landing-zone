@description('Name of the Key Vault')
param keyVaultName string

@description('SQL connection string')
@secure()
param sqlConnectionString string

@description('SQL admin password')
@secure()
param sqlAdminPassword string

@description('VM admin password')
@secure()
param vmAdminPassword string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource sqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-admin-password'
  properties: {
    value: sqlAdminPassword
  }
}

resource vmPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'vm-admin-password'
  properties: {
    value: vmAdminPassword
  }
}

resource sqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-connection-string'
  properties: {
    value: sqlConnectionString
  }
}
