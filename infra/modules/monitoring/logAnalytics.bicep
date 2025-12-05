
targetScope = 'resourceGroup'

param name string
param location string
param retentionInDays int = 30

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    retentionInDays: retentionInDays
    features: {
      legacy: 0
    }
  }
}

output workspaceId string = workspace.id
