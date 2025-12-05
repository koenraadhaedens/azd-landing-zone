targetScope = 'resourceGroup'

param name string
param location string
param vnetId string
param subnetName string
param tags object = {}

// Placeholder for Internal Load Balancer
// TODO: Implement actual ILB resource when needed
// Using parameters to avoid warnings
var ilbName = name
var ilbLocation = location
var ilbVnetId = vnetId
var ilbSubnet = subnetName
var ilbTags = tags

output ilbId string = 'placeholder-ilb-${ilbName}-${ilbLocation}-${ilbSubnet}-${ilbVnetId}-${length(ilbTags)}'
output ilbPrivateIp string = '10.10.2.4'
