@description('Name of the Key Vault')
param keyVaultName string

@description('Web App Managed Identity Principal ID')
param webAppManagedIdentityPrincipalId string

@description('API VM Managed Identity Principal ID')
param apiVmManagedIdentityPrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource kvAccessPolicyWebApp 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webAppManagedIdentityPrincipalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: apiVmManagedIdentityPrincipalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}
