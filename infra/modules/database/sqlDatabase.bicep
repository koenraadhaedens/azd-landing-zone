@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Administrator login name for SQL Server')
param administratorLogin string = 'sqladmin'

@description('Administrator password for SQL Server')
@secure()
param administratorLoginPassword string

@description('SKU for the SQL Database')
param databaseSku object = {
  name: 'S1'
  tier: 'Standard'
}

@description('Managed Identity resource ID for SQL Server')
param managedIdentityId string

@description('Tags to apply to resources')
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
    primaryUserAssignedIdentityId: managedIdentityId
  }
  tags: tags
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: databaseSku
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
  }
  tags: tags
}

// Enable Azure AD authentication only
resource sqlServerAzureADOnlyAuth 'Microsoft.Sql/servers/azureADOnlyAuthentications@2023-08-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    azureADOnlyAuthentication: false // Allow both SQL and Azure AD auth for initial setup
  }
}

// Advanced Threat Protection
resource sqlServerSecurityAlertPolicy 'Microsoft.Sql/servers/securityAlertPolicies@2023-08-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAddresses: []
    emailAccountAdmins: true
    retentionDays: 30
  }
}

// Vulnerability Assessment
resource sqlServerVulnerabilityAssessment 'Microsoft.Sql/servers/vulnerabilityAssessments@2023-08-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    storageContainerPath: ''
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
      emails: []
    }
  }
  dependsOn: [
    sqlServerSecurityAlertPolicy
  ]
}

// Transparent Data Encryption (enabled by default on new databases)
resource sqlDatabaseTDE 'Microsoft.Sql/servers/databases/transparentDataEncryption@2023-08-01-preview' = {
  parent: sqlDatabase
  name: 'current'
  properties: {
    state: 'Enabled'
  }
}

output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseId string = sqlDatabase.id
output sqlDatabaseName string = sqlDatabase.name
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlDatabaseName};Authentication=Active Directory Managed Identity;Encrypt=true;'
