metadata name = 'ALZ Bicep - Spoke Networking module'
metadata description = 'This module creates spoke networking resources'

type lockType = {
  @description('Optional. Specify the name of lock.')
  kind: string

  @description('Optional. Notes about this lock.')
  notes: string?
}

type subnetsType = ({
  @description('Subnet Name')
  name: string

  @description('Address prefix for Subnet')
  addressPrefix: string

  @description('managementGroup for subscription placement')
  managementGroup: string

  @description('list of services to connect to from the subnet for private access and not having to go through public IP')
  serviceEndpoints: array

  @description('list of locations of services to connect to from the subnet for private access and not having to go through public IP')
  serviceEndpointsLocation: array

  @description('Policies for service endpoints')
  serviceEndpointPolicies: array
})[]

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Switch to enable/disable BGP Propagation on route table.')
param parDisableBgpRoutePropagation bool = false

@sys.description('Id of the DdosProtectionPlan which will be applied to the Virtual Network.')
param parDdosProtectionPlanId string = ''

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('The IP address range for all virtual networks to use.')
param parSpokeNetworkAddressPrefix string = ''

@sys.description('The Name of the Spoke Virtual Network.')
param parSpokeNetworkName string = 'vnet-spoke'

@sys.description('The Name of the Network Security Group.')
param parNSGName string = ''

@description('list of network security rules')
param parNSGRules array

@sys.description('''Resource Lock Configuration for Spoke Network

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parSpokeNetworkLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Spoke Networking Module.'
}

@sys.description('Array of DNS Server IP addresses for VNet.')
param parDnsServerIps array = []

@sys.description('IP Address where network traffic should route to leveraged with DNS Proxy.')
param parNextHopIpAddress string = ''

@sys.description('Name of Route table to create for the default route of Hub.')
param parSpokeToHubRouteTableName string = 'rtb-spoke-to-hub'

@sys.description('''Resource Lock Configuration for Spoke Network Route Table.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parSpokeRouteTableLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Spoke Networking Module.'
}

@description('Optional. An Array of subnets to deploy to the Virtual Network.')
param subnets subnetsType = []

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

// Customer Usage Attribution Id
var varCuaid = '0c428583-f2a1-4448-975c-2d6262fd193a'

//If Ddos parameter is true Ddos will be Enabled on the Virtual Network
//If Azure Firewall is enabled and Network DNS Proxy is enabled DNS will be configured to point to AzureFirewall
resource resSpokeVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: parSpokeNetworkName
  location: parLocation
  tags: parTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        parSpokeNetworkAddressPrefix
      ]
    }
    enableDdosProtection: (!empty(parDdosProtectionPlanId) ? true : false)
    ddosProtectionPlan: (!empty(parDdosProtectionPlanId) ? true : false) ? {
      id: parDdosProtectionPlanId
    } : null
    dhcpOptions: (!empty(parDnsServerIps) ? true : false) ? {
      dnsServers: parDnsServerIps
    } : null
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: nsg.id
        }
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
        serviceEndpointPolicies: contains(subnet, 'serviceEndpointPolicies') ? subnet.serviceEndpointPolicies : []
      }
      type: 'Microsoft.Network/virtualNetworks/subnets'
    }]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: parNSGName
  location: parLocation
  properties: {
    securityRules: [for rule in parNSGRules: {
      name: rule.name
      properties: rule.properties
    }]
  }
}

// Create a virtual network resource lock if parGlobalResourceLock.kind != 'None' or if parSpokeNetworkLock.kind != 'None'
resource resSpokeVirtualNetworkLock 'Microsoft.Authorization/locks@2020-05-01' = if (parSpokeNetworkLock.kind != 'None' || parGlobalResourceLock.kind != 'None') {
  scope: resSpokeVirtualNetwork
  properties: {
    level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parSpokeNetworkLock.kind
    notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parSpokeNetworkLock.?notes
  }
}

resource resSpokeToHubRouteTable 'Microsoft.Network/routeTables@2023-02-01' = if (!empty(parNextHopIpAddress)) {
  name: parSpokeToHubRouteTableName
  location: parLocation
  tags: parTags
  properties: {
    routes: [
      {
        name: 'udr-default-to-hub-nva'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: parNextHopIpAddress
        }
      }
    ]
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
  }
}

// Create a Route Table if parAzFirewallEnabled is true and parGlobalResourceLock.kind != 'None' or if parHubRouteTableLock.kind != 'None'
resource resSpokeToHubRouteTableLock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(parNextHopIpAddress) && (parSpokeRouteTableLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
  scope: resSpokeToHubRouteTable
  properties: {
    level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parSpokeRouteTableLock.kind
    notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parSpokeRouteTableLock.?notes
  }
}

// Optional Deployment for Customer Usage Attribution
module modCustomerUsageAttribution '../../custom-modules/CRML/customerUsageAttribution/cuaIdResourceGroup.bicep' = if (!parTelemetryOptOut) {
  name: 'pid-${varCuaid}-${uniqueString(resourceGroup().id)}'
  params: {}
}

output outSpokeVirtualNetworkName string = resSpokeVirtualNetwork.name
output outSpokeVirtualNetworkId string = resSpokeVirtualNetwork.id
