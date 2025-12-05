
targetScope = 'resourceGroup'

param name string
param location string
param vnetId string
param subnetName string
param wafMode string = 'Prevention'
param wafPolicyName string
param tags object = {}

var subnetId = '${vnetId}/subnets/${subnetName}'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${name}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2022-09-01' = {
  name: wafPolicyName
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: wafMode
      requestBodyCheck: true
    }
    customRules: []
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

resource appGw 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'gwipconfig'
        properties: {
          subnet: { id: subnetId }
        }
      }
    ]
    frontendIPConfigurations: [
      { 
        name: 'feip' 
        properties: { 
          publicIPAddress: { id: publicIp.id }
        } 
      }
    ]
    frontendPorts: [
      { name: 'port-80', properties: { port: 80 } }
      { name: 'port-443', properties: { port: 443 } }
    ]
    sslCertificates: []
    backendAddressPools: [
      {
        name: 'defaultpool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaultsettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'listener-80'
        properties: {
          frontendIPConfiguration: { id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, 'feip') }
          frontendPort: { id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, 'port-80') }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule-80'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: { id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, 'listener-80') }
          backendAddressPool: { id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'defaultpool') }
          backendHttpSettings: { id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'defaultsettings') }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: wafMode
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}

output appGatewayId string = appGw.id
output publicIpAddress string = publicIp.properties.ipAddress
