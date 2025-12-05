
targetScope = 'resourceGroup'

// Simplified diagnostic settings - individual resources should define their own diagnostic settings
// This is a placeholder module for the diagnostic configuration
param workspaceResourceId string

output diagnosticSettingsConfig object = {
  workspaceId: workspaceResourceId
  logs: [
    { category: 'AuditEvent', enabled: true }
    { category: 'VMProtectionAlerts', enabled: true }
  ]
  metrics: [
    { category: 'AllMetrics', enabled: true }
  ]
}
