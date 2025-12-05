
targetScope = 'subscription'

param location string
param environment string
param workload string
param uniquenessSeed string

// region in short form (e.g., westeurope -> weu). You can hardcode or map.

// Normalize input
var locLower = toLower(location)

// Preferred short codes for common Azure regions.
// Extend this map as you need; keys are the ARM/az locations (e.g., 'westeurope', 'eastus2').
var regionMap = {
  // Europe
  westeurope: 'weu'
  northeurope: 'neu'
  swedencentral: 'sec'
  swedensouth: 'ses'
  uksouth: 'uks'
  ukwest: 'ukw'
  francecentral: 'frc'
  francesouth: 'frs'
  germanywestcentral: 'gwc'
  germanynorth: 'gen'
  norwayeast: 'noe'
  norwaywest: 'now'
  switzerlandnorth: 'swn'
  switzerlandwest: 'sww'
  polandcentral: 'plc'
  italynorth: 'itn'
  spaincentral: 'spc'

  // Americas
  eastus: 'eus'
  eastus2: 'eu2'
  westus: 'wus'
  westus2: 'wu2'
  westus3: 'wu3'
  centralus: 'cus'
  southcentralus: 'scu'
  northcentralus: 'ncu'
  canadacentral: 'cac'
  canadaeast: 'cae'
  brazilsouth: 'brs'
  brazilsoutheast: 'brse'

  // Asia Pacific
  southeastasia: 'sea'
  eastasia: 'eas'
  japaneast: 'jpe'
  japanwest: 'jpw'
  australiaeast: 'aue'
  australiasoutheast: 'ause'
  australiacentral: 'auc'
  australiacentral2: 'auc2'
  koreacentral: 'krc'
  koreasouth: 'krs'
  southindia: 'sin'
  centralindia: 'cin'
  westindia: 'win'

  // Middle East & Africa
  uaenorth: 'uan'
  uaecentral: 'uac'
  qatarcentral: 'qac'
  southafricanorth: 'san'
  southafricawest: 'saw'

  // Global sovereign (examples; keep if you use them)
  global: 'glb'
}

// Fallback: derive a short code from the given location string.
// - Split on spaces or hyphens (handles 'West Europe' or 'west-europe')
// - Take up to 3 chars from each token
// - Join tokens together, lowercased
var tokens = [for t in split(replace(locLower, '-', ' '), ' '): length(t) > 0 ? substring(t, 0, min(3, length(t))) : '']

// Filter out empty tokens using filter function
var filteredTokens = filter(tokens, t => length(t) > 0)

// Final short code: prefer map value, else fallback from tokens
var regionShort = contains(regionMap, locLower) ? regionMap[locLower]! : join(filteredTokens, '')


// Base tags (extend as needed)
var defaultTags = {
  environment: environment
  workload: workload
  location: location
}

output defaultTags object = defaultTags

// Resource group names
output rgPlatformName string = 'rg-platform-${workload}-${environment}-${regionShort}'
output rgHubName string      = 'rg-hub-${workload}-${environment}-${regionShort}'
output rgAppName string      = 'rg-app-${workload}-${environment}-${regionShort}'

// Monitoring
output laName string         = 'la-${workload}-${environment}-${regionShort}${uniquenessSeed}'

// Hub
output hubVnetName string    = 'vnet-hub-${environment}-${regionShort}'
output firewallName string   = 'afw-hub-${environment}-${regionShort}'
output bastionName string    = 'bas-hub-${environment}-${regionShort}'

// Spoke/application
output appVnetName string    = 'vnet-${workload}-${environment}-${regionShort}'
output kvName string         = 'kv-${workload}-${environment}-${regionShort}${uniquenessSeed}'
output appGwName string      = 'agw-${workload}-${environment}-${regionShort}'
output wafPolicyName string  = 'waf-${workload}-${environment}-${regionShort}'
output ilbName string        = 'ilb-${workload}-${environment}-${regionShort}'
output vmssFrontendName string = 'vmss-fe-${workload}-${environment}-${regionShort}'
output vmssBackendName string  = 'vmss-be-${workload}-${environment}-${regionShort}'
output peeringAppToHub string  = 'peer-${workload}-hub-${environment}-${regionShort}'
output peeringHubToApp string  = 'peer-hub-${workload}-${environment}-${regionShort}'

// 3-tier application resources
output webAppName string = 'app-${workload}-${environment}-${regionShort}${uniquenessSeed}'
output appServicePlanName string = 'asp-${workload}-${environment}-${regionShort}'
output apiVmName string = 'vm-api-${workload}-${environment}-${regionShort}'
output sqlServerName string = 'sql-${workload}-${environment}-${regionShort}${uniquenessSeed}'
output sqlDatabaseName string = 'sqldb-${workload}-${environment}'
output webAppManagedIdentityName string = 'mi-webapp-${workload}-${environment}-${regionShort}'
output apiVmManagedIdentityName string = 'mi-api-${workload}-${environment}-${regionShort}'
output webAppPrivateEndpointName string = 'pe-webapp-${workload}-${environment}-${regionShort}'
output sqlPrivateEndpointName string = 'pe-sql-${workload}-${environment}-${regionShort}'
output kvPrivateEndpointName string = 'pe-kv-${workload}-${environment}-${regionShort}'
output privateDnsZoneWebApp string = 'privatelink.azurewebsites.net'
output privateDnsZoneSql string = 'privatelink${az.environment().suffixes.sqlServerHostname}'
output privateDnsZoneKeyVault string = 'privatelink${az.environment().suffixes.keyvaultDns}'
output networkSecurityGroupApiName string = 'nsg-api-${workload}-${environment}-${regionShort}'
