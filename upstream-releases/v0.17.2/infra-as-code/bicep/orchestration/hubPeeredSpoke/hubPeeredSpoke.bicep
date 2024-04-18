targetScope = 'managementGroup'

metadata name = 'ALZ Bicep - Orchestration - Hub Peered Spoke'
metadata description = 'Orchestration module used to create and configure a spoke network to deliver the Azure Landing Zone Hub & Spoke architecture'

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}

type spokesType = {
  @description('SubscriptionId for spokeNetworking')
  subscriptionId: string

  @description('vNet name for spokeNetworking')
  networkName: string

  @description('Address prefix (CIDR) for spokeNetworking')
  ipRange: string?

  @description('managementGroup for subscription placement')
  managementGroup: string?
}

// **Parameters**
// Generic Parameters - Used in multiple modules
@sys.description('The region to deploy all resources into.')
param parLocation string = deployment().location

@sys.description('Prefix used for the management group hierarchy.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'mg-rsp-'

@sys.description('Prefix used for the "Workloads" management group hierarchy.')
param parWorkloadsManagementGroupPrefix string = 'workloads-'

@sys.description('Prefix used for the child "Prod" under "Workloads" management group hierarchy.')
param parProdManagementGroupPrefix string = 'prod'

@sys.description('Prefix used for the child "NonProd" under "Workloads" management group hierarchy.')
param parNonProdManagementGroupPrefix string = 'nonprod'

@sys.description('Optional suffix for the management group hierarchy. This suffix will be appended to management group names/IDs. Include a preceding dash if required. Example: -suffix')
@maxLength(10)
param parTopLevelManagementGroupSuffix string = ''

//ToDo:
@sys.description('Subscription Id to the Virtual Network Hub object. Default: Empty String')
param parPeeredVnetSubscriptionId string = ''

@sys.description('Array of Tags to be applied to all resources in module. Default: Empty Object')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Peered Spoke Orchestration Networking Module.'
}

// Subscription Module Parameters
@sys.description('The Management Group Id to place the subscription in. Default: Empty String')
param parPeeredVnetSubscriptionMgPlacement string = ''

// Resource Group Module Parameters
@sys.description('Name of Resource Group to be created to contain spoke networking resources like the virtual network.')
param parResourceGroupNameForSpokeNetworking string = 'rg-rsp-spoke-networking'

@sys.description('Resource Group Lock Configuration.')
param parResourceGroupLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Peered Spoke Orchestration Networking Module.'
}

// Spoke Networking Module Parameters
@sys.description('Existing DDoS Protection plan to utilize. Default: Empty string')
param parDdosProtectionPlanId string = ''

@sys.description('The Resource IDs of the Private DNS Zones to associate with spokes. Default: Empty Array')
param parPrivateDnsZoneResourceIds array = []

@sys.description('The Name of the Spoke Virtual Network.')
param parSpokeNetworkName string = 'vnet-spoke-${parLocation}'

@sys.description('CIDR for Spoke Network.')
param parSpokeNetworkAddressPrefix string = '10.11.0.0/16'

@sys.description('Array of DNS Server IP addresses for VNet. Default: Empty Array')
param parDnsServerIps array = []

@sys.description('IP Address where network traffic should route to. Default: Empty string')
param parNextHopIpAddress string = ''

@sys.description('Switch which allows BGP Route Propogation to be disabled on the route table.')
param parDisableBgpRoutePropagation bool = false

@sys.description('Name of Route table to create for the default route of Hub.')
param parSpokeToHubRouteTableName string = 'rtb-spoke-to-hub'

@sys.description('''Resource Lock Configuration for Spoke Network.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parSpokeNetworkLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Peered Spoke Orchestration Networking Module.'
}

@sys.description('''Resource Lock Configuration for Spoke Network Route Table.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parSpokeRouteTableLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Peered Spoke Orchestration Networking Module.'
}

// Private DNS Link Module Parameters
@sys.description('''Resource Lock Configuration for Private DNS Virtual Network Network Links.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parPrivateDnsZoneVirtualNetworkLinkLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Peered Spoke Orchestration Networking Module.'
}

//TODO: It does appear that we need to have deployed Hub and know Hub network ID to be able to orchestrate peering between Spokes and Hub. Deployment will need to be in phase. 
// Peering Modules Parameters
@sys.description('Virtual Network ID of Hub Virtual Network, or Azure Virtuel WAN hub ID.')
param parHubVirtualNetworkId string

@sys.description('Switch to enable/disable forwarded Traffic from outside spoke network.')
param parAllowSpokeForwardedTraffic bool = false

@sys.description('Switch to enable/disable VPN Gateway for the hub network peering.')
param parAllowHubVpnGatewayTransit bool = false

// VWAN Module Parameters

@sys.description('Optional Virtual Hub Connection Name Prefix.')
param parVirtualHubConnectionPrefix string = 'vhc-spoke-network-'

@sys.description('Optional Virtual Hub Connection Name Suffix. Example: -vhc')
param parVirtualHubConnectionSuffix string = ''

@sys.description('Enable Internet Security for the Virtual Hub Connection.')
param parEnableInternetSecurity bool = false

// **Variables**
// Customer Usage Attribution Id
var varCuaid = '8ea6f19a-d698-4c00-9afb-5c92d4766fd2'

// Orchestration Module Variables
var varDeploymentNameWrappers = {
  basePrefix: 'ALZBicep'
  baseSuffixManagementGroup: '${parLocation}-${uniqueString(parLocation, parTopLevelManagementGroupPrefix)}-mg'
  baseSuffixSubscription: '${parLocation}-${uniqueString(parLocation, parTopLevelManagementGroupPrefix)}-sub'
  baseSuffixResourceGroup: '${parLocation}-${uniqueString(parLocation, parTopLevelManagementGroupPrefix)}-rg'
}

var varModuleDeploymentNames = {
  modSubscriptionPlacement: take('${varDeploymentNameWrappers.basePrefix}-modSubscriptionPlacement-${parPeeredVnetSubscriptionMgPlacement}-${varDeploymentNameWrappers.baseSuffixManagementGroup}', 64)
  modResourceGroup: take('${varDeploymentNameWrappers.basePrefix}-modResourceGroup-${varDeploymentNameWrappers.baseSuffixSubscription}', 64)
  modSpokeNetworking: take('${varDeploymentNameWrappers.basePrefix}-modSpokeNetworking-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modSpokePeeringToHub: take('${varDeploymentNameWrappers.basePrefix}-modVnetPeering-ToHub-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modSpokePeeringFromHub: take('${varDeploymentNameWrappers.basePrefix}-modVnetPeering-FromHub-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modVnetPeeringVwan: take('${varDeploymentNameWrappers.basePrefix}-modVnetPeeringVwan-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modPrivateDnsZoneLinkToSpoke: take('${varDeploymentNameWrappers.basePrefix}-modPDnsLinkToSpoke-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
}

var varHubVirtualNetworkName = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualNetworks/') ? split(parHubVirtualNetworkId, '/')[8] : '')

var varHubVirtualNetworkResourceGroup = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualNetworks/') ? split(parHubVirtualNetworkId, '/')[4] : '')

var varHubVirtualNetworkSubscriptionId = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualNetworks/') ? split(parHubVirtualNetworkId, '/')[2] : '')

var varNextHopIPAddress = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualNetworks/') ? parNextHopIpAddress : '')

var varVirtualHubResourceId = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualHubs/') ? parHubVirtualNetworkId : '')

var varVirtualHubResourceGroup = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualHubs/') ? split(parHubVirtualNetworkId, '/')[4] : '')

var varVirtualHubSubscriptionId = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualHubs/') ? split(parHubVirtualNetworkId, '/')[2] : '')

@sys.description('SubscriptionID, vNetName, ipRange and managementGroup for creating Spoke vNet, placing subscription under the right management group')
param parSpokeNetworks spokesType = [
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //Development
    ipRange: '10.1.0.0/17'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parNonProdManagementGroupPrefix}'
  }
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //System Test
    ipRange: '10.2.0.0/17'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parNonProdManagementGroupPrefix}'
  }
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //System Test Automation
    ipRange: '10.3.0.0/17'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parNonProdManagementGroupPrefix}'
  }
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //System Test Integration
    ipRange: '10.4.0.0/17'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parNonProdManagementGroupPrefix}'
  }
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //UAT
    ipRange: '10.5.0.0/17'
    managementGroup: managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parProdManagementGroupPrefix}'
  }
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //Staging
    ipRange: '10.6.0.0/17'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parProdManagementGroupPrefix}'
  }
  {
    subscriptionId: 'xxxxxxxxxxxxxxxxxxx' //Prod
    ipRange: '10.7.0.0/17'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parProdManagementGroupPrefix}'
  }
]

spokes: [for spoke in parSpokeNetworks: {

// **Modules**
// Module - Customer Usage Attribution - Telemetry
  module modCustomerUsageAttribution '../../CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
    scope: managementGroup(spoke.managementGroup)
    name: 'pid-${varCuaid}-${uniqueString(parLocation, parPeeredVnetSubscriptionId)}'
    params: {}
  }

  // Module - Subscription Placement - Management
  module modSubscriptionPlacement '../../modules/subscriptionPlacement/subscriptionPlacement.bicep' = if (!empty(parPeeredVnetSubscriptionMgPlacement)) {
    scope: managementGroup(spoke.managementGroup)
    name: varModuleDeploymentNames.modSubscriptionPlacement
    params: {
      parTargetManagementGroupId: spoke.managementGroup
      parSubscriptionIds: [
        spoke.subscriptionId
      ]
      parTelemetryOptOut: parTelemetryOptOut
    }
  }

  // Module - Resource Group
  module modResourceGroup '../../modules/resourceGroup/resourceGroup.bicep' = {
    scope: subscription(spoke.SubscriptionId)
    name: varModuleDeploymentNames.modResourceGroup
    params: {
      parLocation: parLocation
      parResourceGroupName: parResourceGroupNameForSpokeNetworking
      parTags: parTags
      parTelemetryOptOut: parTelemetryOptOut
      parResourceLockConfig: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock : parResourceGroupLock
    }
  }

  // Module - Spoke Virtual Network
  module modSpokeNetworking '../../modules/spokeNetworking/spokeNetworking.bicep' = {
    scope: resourceGroup(spoke.subscriptionId, parResourceGroupNameForSpokeNetworking)
    name: varModuleDeploymentNames.modSpokeNetworking
    dependsOn: [
      modResourceGroup
    ]
    params: {
      parSpokeNetworkName: parSpokeNetworkName
      parSpokeNetworkAddressPrefix: spoke.ipRange
      parDdosProtectionPlanId: parDdosProtectionPlanId
      parDnsServerIps: parDnsServerIps
      parNextHopIpAddress: varNextHopIPAddress
      parSpokeToHubRouteTableName: parSpokeToHubRouteTableName
      parDisableBgpRoutePropagation: parDisableBgpRoutePropagation
      parTags: parTags
      parTelemetryOptOut: parTelemetryOptOut
      parLocation: parLocation
      parGlobalResourceLock: parGlobalResourceLock
      parSpokeNetworkLock: parSpokeNetworkLock
      parSpokeRouteTableLock: parSpokeRouteTableLock
    }
  }

  // Module - Private DNS Zone Virtual Network Link to Spoke
  module modPrivateDnsZoneLinkToSpoke '../../modules/privateDnsZoneLinks/privateDnsZoneLinks.bicep' = [for zone in parPrivateDnsZoneResourceIds: if (!empty(parPrivateDnsZoneResourceIds)) {
    scope: resourceGroup(split(zone, '/')[2], split(zone, '/')[4])
    name: take('${varModuleDeploymentNames.modPrivateDnsZoneLinkToSpoke}-${uniqueString(zone)}', 64)
    params: {
      parPrivateDnsZoneResourceId: zone
      parSpokeVirtualNetworkResourceId: modSpokeNetworking.outputs.outSpokeVirtualNetworkId
      parResourceLockConfig: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock : parPrivateDnsZoneVirtualNetworkLinkLock
    }
  }]

  //ToDo:Review
  // Module -  Spoke to Azure Virtual WAN Hub peering.
  module modhubVirtualNetworkConnection '../../modules/vnetPeeringVwan/hubVirtualNetworkConnection.bicep' = if (!empty(varVirtualHubResourceId)) {
    scope: resourceGroup(varVirtualHubSubscriptionId, varVirtualHubResourceGroup)
    name: varModuleDeploymentNames.modVnetPeeringVwan
    params: {
      parVirtualWanHubResourceId: varVirtualHubResourceId
      parRemoteVirtualNetworkResourceId: modSpokeNetworking.outputs.outSpokeVirtualNetworkId
      parVirtualHubConnectionPrefix: parVirtualHubConnectionPrefix
      parVirtualHubConnectionSuffix: modSpokeNetworking.outputs.outSpokeVirtualNetworkName
      parEnableInternetSecurity: parEnableInternetSecurity
    }
  }

  output outSpokeVirtualNetworkName string = modSpokeNetworking.outputs.outSpokeVirtualNetworkName
  output outSpokeVirtualNetworkId string = modSpokeNetworking.outputs.outSpokeVirtualNetworkId
}]
