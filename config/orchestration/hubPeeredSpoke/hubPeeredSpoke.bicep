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

type spokesType = ({
  @description('SubscriptionId for spokeNetworking')
  subscriptionId: string

  @description('Address prefix (CIDR) for spokeNetworking')
  ipRange: string

  @description('managementGroup for subscription placement')
  managementGroup: string

  @description('resourceGroup for container app deployment')
  resourceGroup: string

  @description('managementGroup for subscription placement')
  spokeNetworkName: string

  @description('Subnet information')
  subnets: subnetsType

  @description('Name of NSG')
  nsgName: string

  @description('Name of environment')
  parEnvironment: string
})[]

type subnetsType = ({
  @description('Subnet Name')
  name: string

  @description('Address prefix for Subnet')
  addressPrefix: string

  @description('list of services to connect to from the subnet for private access and not having to go through public IP')
  serviceEndpoints: array

  @description('list of locations of services to connect to from the subnet for private access and not having to go through public IP')
  serviceEndpointsLocation: array

  @description('Policies for service endpoints')
  serviceEndpointPolicies: array
})[]

param lzsecurityRules array = []

// **Parameters**
// Generic Parameters - Used in multiple modules
@sys.description('The region to deploy all resources into.')
param parLocation string = deployment().location

@sys.description('Prefix used for the management group hierarchy.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'mg-rsp'

@sys.description('Prefix used for the "Workloads" management group hierarchy.')
param parWorkloadsManagementGroupPrefix string = '-workloads'

@sys.description('Prefix used for the child "NonProd" under "Workloads" management group hierarchy.')
param parNonProdManagementGroupPrefix string = '-nonprod'

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

@sys.description('Resource Group Lock Configuration.')
param parResourceGroupLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Peered Spoke Orchestration Networking Module.'
}

// Spoke Networking Module Parameters
@sys.description('Existing DDoS Protection plan to utilize. Default: Empty string')
param parDdosProtectionPlanId string = 'rsp-ddos-plan'

// @sys.description('The Resource IDs of the Private DNS Zones to associate with spokes. Default: Empty Array')
// param parPrivateDnsZoneResourceIds array = []

@sys.description('Array of DNS Server IP addresses for VNet. Default: Empty Array')
param parDnsServerIps array = []

@sys.description('IP Address where network traffic should route to. Default: Empty string')
param parNextHopIpAddress string = '' //Hub firewall IP Address

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

//TODO: It does appear that we need to have deployed Hub and know Hub network ID to be able to orchestrate peering between Spokes and Hub. Deployment will need to be in phase. 
// Peering Modules Parameters
@sys.description('Virtual Network ID of Hub Virtual Network, or Azure Virtuel WAN hub ID.')
param parHubVirtualNetworkId string = ''

// VWAN Module Parameters

@sys.description('Optional Virtual Hub Connection Name Prefix.')
param parVirtualHubConnectionPrefix string = 'vhc-spoke-network-'

@sys.description('Enable Internet Security for the Virtual Hub Connection.')
param parEnableInternetSecurity bool = false

// **Variables**
// Customer Usage Attribution Id
// var varCuaid = '8ea6f19a-d698-4c00-9afb-5c92d4766fd2'

// Orchestration Module Variables
var varDeploymentNameWrappers = {
  basePrefix: 'rsp'
  baseSuffixManagementGroup: '${parLocation}-${uniqueString(parLocation, parTopLevelManagementGroupPrefix)}-mg'
  baseSuffixSubscription: '${parLocation}-${uniqueString(parLocation, parTopLevelManagementGroupPrefix)}-sub'
  baseSuffixResourceGroup: '${parLocation}-${uniqueString(parLocation, parTopLevelManagementGroupPrefix)}-rg'
}

var varModuleDeploymentNames = {
  modResourceGroup: take('${varDeploymentNameWrappers.basePrefix}-modResourceGroup-${varDeploymentNameWrappers.baseSuffixSubscription}', 64)
  modSpokeNetworking: take('${varDeploymentNameWrappers.basePrefix}-modSpokeNetworking-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modSpokePeeringToHub: take('${varDeploymentNameWrappers.basePrefix}-modVnetPeering-ToHub-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modSpokePeeringFromHub: take('${varDeploymentNameWrappers.basePrefix}-modVnetPeering-FromHub-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modVnetPeeringVwan: take('${varDeploymentNameWrappers.basePrefix}-modVnetPeeringVwan-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
  modPrivateDnsZoneLinkToSpoke: take('${varDeploymentNameWrappers.basePrefix}-modPDnsLinkToSpoke-${varDeploymentNameWrappers.baseSuffixResourceGroup}', 61)
}

var varNextHopIPAddress = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualNetworks/') ? parNextHopIpAddress : '')

var varVirtualHubResourceId = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualHubs/') ? parHubVirtualNetworkId : '')

var varVirtualHubResourceGroup = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualHubs/') ? split(parHubVirtualNetworkId, '/')[4] : '')

var varVirtualHubSubscriptionId = (!empty(parHubVirtualNetworkId) && contains(parHubVirtualNetworkId, '/providers/Microsoft.Network/virtualHubs/') ? split(parHubVirtualNetworkId, '/')[2] : '')

@sys.description('SubscriptionID, vNetName, ipRange and managementGroup for creating Spoke vNet, placing subscription under the right management group')
param parSpokeNetworks spokesType = [
  {
    subscriptionId: 'b83b4631-b51b-4961-86a1-295f539c826b' //Development
    ipRange: '10.1.0.0/16'
    managementGroup: '${parTopLevelManagementGroupPrefix}${parWorkloadsManagementGroupPrefix}${parNonProdManagementGroupPrefix}'
    spokeNetworkName: 'vnet-development-spoke-${parLocation}'
    nsgName: 'rsp-nsg-development'
    resourceGroup:'rg-rsp-container-app-development'
    parEnvironment: 'development'
    subnets: [
        {
          name: 'development-containerapp-subnet'
          addressPrefix: '10.1.0.0/18'
          serviceEndpoints: [
          ]
          serviceEndpointsLocation: [
            'uksouth'
          ]
          serviceEndpointPolicies: []
        }
    ] 
  }
]

//Do we need telemetry ? 
// **Modules**
// Module - Customer Usage Attribution - Telemetry
  // module modCustomerUsageAttribution '../../CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
  //   scope: managementGroup(spoke.managementGroup)
  //   name: 'pid-${varCuaid}-${uniqueString(parLocation, parPeeredVnetSubscriptionId)}'
  //   params: {}
  // }

  // Module - Resource Group
  module modResourceGroup '../../custom-modules/resourceGroup/resourceGroup.bicep' = [for spokenew in parSpokeNetworks: {
    scope: subscription(spokenew.subscriptionId)
    name: varModuleDeploymentNames.modResourceGroup
    params: {
      parLocation: parLocation
      parResourceGroupName: spokenew.resourceGroup
      parTags: parTags
      parTelemetryOptOut: parTelemetryOptOut
      parResourceLockConfig: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock : parResourceGroupLock
    }
  }]

  // Module - Spoke Virtual Network
  module modSpokeNetworking '../../custom-modules/spokeNetworking/spokeNetworking.bicep' = [for spokenew in parSpokeNetworks: {
    scope: resourceGroup(spokenew.subscriptionId, spokenew.resourceGroup)
    name: varModuleDeploymentNames.modSpokeNetworking
    dependsOn: [
      modResourceGroup
    ]
    params: {
      parSpokeNetworkName: spokenew.spokeNetworkName
      parSpokeNetworkAddressPrefix: spokenew.ipRange
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
      parNSGName: spokenew.nsgName
      parNSGRules: lzsecurityRules
      parSubnets: spokenew.subnets
    }
  }]

  //Do we need Private DNS ? 
  // Module - Private DNS Zone Virtual Network Link to Spoke
  // module modPrivateDnsZoneLinkToSpoke '../../modules/privateDnsZoneLinks/privateDnsZoneLinks.bicep' = [for zone in parPrivateDnsZoneResourceIds: if (!empty(parPrivateDnsZoneResourceIds)) {
  //   scope: resourceGroup(split(zone, '/')[2], split(zone, '/')[4])
  //   name: take('${varModuleDeploymentNames.modPrivateDnsZoneLinkToSpoke}-${uniqueString(zone)}', 64)
  //   params: {
  //     parPrivateDnsZoneResourceId: zone
  //     parSpokeVirtualNetworkResourceId: modSpokeNetworking.outputs.outSpokeVirtualNetworkId
  //     parResourceLockConfig: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock : parPrivateDnsZoneVirtualNetworkLinkLock
  //   }
  // }]

  //ToDo:Review
  // Module -  Spoke to Azure Virtual WAN Hub peering.
  module modhubVirtualNetworkConnection '../../custom-modules/vnetPeeringVwan/hubVirtualNetworkConnection.bicep' = [for i in range(0, length(parSpokeNetworks)): if (!empty(varVirtualHubResourceId)) {
    scope: resourceGroup(varVirtualHubSubscriptionId, varVirtualHubResourceGroup)
    name: '${varModuleDeploymentNames.modVnetPeeringVwan}${i}'
    params: {
      parVirtualWanHubResourceId: varVirtualHubResourceId
      parRemoteVirtualNetworkResourceId: modSpokeNetworking[i].outputs.outSpokeVirtualNetworkId
      parVirtualHubConnectionPrefix: parVirtualHubConnectionPrefix
      parVirtualHubConnectionSuffix: modSpokeNetworking[i].outputs.outSpokeVirtualNetworkName
      parEnableInternetSecurity: parEnableInternetSecurity
    }
  }]

  output outSpokeVirtualNetworkNames array = [for i in range(0, length(parSpokeNetworks)): {
    Name: modSpokeNetworking[i].outputs.outSpokeVirtualNetworkName
  }]

  output outSpokeVirtualNetworkIds array = [for i in range(0, length(parSpokeNetworks)): {
    id: modSpokeNetworking[i].outputs.outSpokeVirtualNetworkId
  }]

  output outlanamespokenetwork array = [for i in range(0, length(parSpokeNetworks)): {
    Name: modSpokeNetworking[i].outputs.outlaName
  }]


  // output outSpokeSubnetNames array = [for i in range(0, length(parSpokeNetworks)): {
  //   Name: modSpokeNetworking[i].outputs.outSpokeSubnetName
  // }]

  // output outSpokeSubnetIds array = [for i in range(0, length(parSpokeNetworks)): {
  //   Id: modSpokeNetworking[i].outputs.outSpokeSubnetId
  // }]
