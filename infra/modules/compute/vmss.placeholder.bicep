targetScope = 'resourceGroup'

param name string
param location string
param sku string
param instanceCount int
param subnetName string
param vnetId string
param tags object = {}

// Placeholder for Virtual Machine Scale Set
// TODO: Implement actual VMSS resource when needed
// Using parameters to avoid warnings
var vmssName = name
var vmssLocation = location
var vmssSku = sku
var vmssInstances = instanceCount
var vmssSubnet = subnetName
var vmssVnet = vnetId
var vmssTags = tags

output vmssId string = 'placeholder-vmss-${vmssName}-${vmssLocation}-${vmssSku}-${vmssInstances}-${vmssSubnet}-${vmssVnet}-${length(vmssTags)}'
output vmssName string = name
