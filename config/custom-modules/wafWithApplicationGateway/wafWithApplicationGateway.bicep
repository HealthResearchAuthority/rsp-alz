param location string
param applicationGatewayName string
param tier string
param skuSize string
param capacity int = 2
param subnetName string
param zones array
param publicIpZones array
param publicIpAddressName array
param sku array
param allocationMethod array
param ipAddressVersion array
param autoScaleMaxCapacity int
var wafPolicyName = 'waf-applicationgateway-development'

var vnetId = '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-container-app-development/providers/Microsoft.Network/virtualNetworks/vnet-development-spoke-uksouth'
var publicIPRef = [
  publicIpAddressName_0.id
]
var subnetRef = '${vnetId}/subnets/${subnetName}'

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: applicationGatewayName
  location: location
  zones: zones
  tags: {}
  properties: {
    sku: {
      name: skuSize
      tier: tier
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        properties: {
          publicIPAddress: {
            id: publicIPRef[0]
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'applicationservicebepool'
        properties: {
          backendAddresses: [
            {
              ipAddress: null
              fqdn: 'ca-rsp-applicationservice-dev.politehill-547be9d7.uksouth.azurecontainerapps.io'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'agw-routing-fe-be-applicationservice-besetting-development'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: 'agw-routing-listener-fe-be-applicationservice-development'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_80')
          }
          protocol: 'Http'
          sslCertificate: null
          customErrorConfigurations: []
        }
      }
    ]
    listeners: []
    requestRoutingRules: [
      {
        name: 'agw-routing-fe-be-applicationservice-development'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'agw-routing-listener-fe-be-applicationservice-development')
          }
          priority: 1
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'applicationservicebepool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'agw-routing-fe-be-applicationservice-besetting-development')
          }
        }
      }
    ]
    routingRules: []
    enableHttp2: true
    sslCertificates: []
    probes: []
    autoscaleConfiguration: {
      minCapacity: capacity
      maxCapacity: autoScaleMaxCapacity
    }
    firewallPolicy: {
      id: '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-container-app-development/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/waf-applicationgateway-development'
    }
  }
  dependsOn: [
    waf_applicationgateway_development
  ]
}

resource waf_applicationgateway_development 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-02-01' = {
  name: wafPolicyName
  location: location
  tags: {}
  properties: {
    policySettings: {
      mode: 'Detection'
      state: 'Enabled'
      fileUploadLimitInMb: 100
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
    }
    managedRules: {
      exclusions: []
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: null
        }
      ]
    }
    customRules: []
  }
}

resource publicIpAddressName_0 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIpAddressName[0]
  location: location
  sku: {
    name: sku[0]
  }
  zones: publicIpZones
  properties: {
    publicIPAddressVersion: ipAddressVersion[0]
    publicIPAllocationMethod: allocationMethod[0]
  }
}
