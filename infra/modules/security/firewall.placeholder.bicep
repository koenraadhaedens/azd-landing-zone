targetScope = 'resourceGroup'

param name string
param location string

// Placeholder for Azure Firewall
// TODO: Implement actual firewall resource when needed
// Using parameters to avoid warnings
var firewallName = name
var firewallLocation = location

output firewallId string = 'placeholder-firewall-id-${firewallName}-${firewallLocation}'
output firewallPrivateIp string = '10.0.1.4'
