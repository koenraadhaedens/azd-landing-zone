targetScope = 'resourceGroup'

param name string
param location string

// Placeholder for Azure Bastion
// TODO: Implement actual bastion resource when needed
// Using parameters to avoid warnings
var bastionName = name
var bastionLocation = location

output bastionId string = 'placeholder-bastion-id-${bastionName}-${bastionLocation}'
