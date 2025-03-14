metadata name = 'ALZ Bicep - Azure vWAN Connectivity Module'
metadata description = 'Module used to set up vWAN Connectivity'

type virtualWanOptionsType = ({
  @sys.description('Switch to enable/disable VPN Gateway deployment on the respective Virtual WAN Hub.')
  parVpnGatewayEnabled: bool

  @sys.description('Switch to enable/disable ExpressRoute Gateway deployment on the respective Virtual WAN Hub.')
  parExpressRouteGatewayEnabled: bool

  @sys.description('Switch to enable/disable Azure Firewall deployment on the respective Virtual WAN Hub.')
  parAzFirewallEnabled: bool

  @sys.description('The IP address range in CIDR notation for the vWAN virtual Hub to use.')
  parVirtualHubAddressPrefix: string

  @sys.description('The Virtual WAN Hub location.')
  parHubLocation: string

  @sys.description('The Virtual WAN Hub routing preference. The allowed values are `ASN`, `VpnGateway`, `ExpressRoute`.')
  parHubRoutingPreference: ('ExpressRoute' | 'VpnGateway' | 'ASN')

  @sys.description('The Virtual WAN Hub capacity. The value should be between 2 to 50.')
  @minValue(2)
  @maxValue(50)
  parVirtualRouterAutoScaleConfiguration: int

  @sys.description('The Virtual WAN Hub routing intent destinations, leave empty if not wanting to enable routing intent. The allowed values are `Internet`, `PrivateTraffic`.')
  parVirtualHubRoutingIntentDestinations: [
  ]

  @sys.description('This parameter is used to specify a custom name for the VPN Gateway.')
  parVpnGatewayCustomName: string?

  @sys.description('This parameter is used to specify a custom name for the ExpressRoute Gateway.')
  parExpressRouteGatewayCustomName: string?

  @sys.description('This parameter is used to specify a custom name for the Azure Firewall.')
  parAzFirewallCustomName: string?

  @sys.description('This parameter is used to specify a custom name for the Virtual WAN Hub.')
  parVirtualWanHubCustomName: string?
})[]

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}

// @sys.description('Region in which the resource group was created.')
// param parLocation string = resourceGroup().location

// @sys.description('Prefix value which will be prepended to all resource names.')
// param parCompanyPrefix string

// @sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parGlobalResourceLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

// @sys.description('Azure Firewall Tier associated with the Firewall to deploy.')
// @allowed([
//   'Basic'
//   'Standard'
//   'Premium'
// ])
// param parAzFirewallTier string

// @sys.description('The Azure Firewall Threat Intelligence Mode.')
// @allowed([
//   'Alert'
//   'Deny'
//   'Off'
// ])
// param parAzFirewallIntelMode string

// @sys.description('Switch to enable/disable Virtual Hub deployment.')
// param parVirtualHubEnabled bool

// @sys.description('Switch to enable/disable Azure Firewall DNS Proxy.')
// param parAzFirewallDnsProxyEnabled bool

// @sys.description('Array of custom DNS servers used by Azure Firewall.')
// param parAzFirewallDnsServers array = []

// param parVirtualWanNamePrefix string 

// @sys.description('Prefix Used for Virtual WAN.')
// param parVirtualWanName string = '${parVirtualWanNamePrefix}-${parLocation}'

// @sys.description('''Resource Lock Configuration for Virtual WAN.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parVirtualWanLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

// @sys.description('Prefix Used for Virtual WAN Hub.')
// param parVirtualWanHubName string

// @sys.description('''Array Used for multiple Virtual WAN Hubs deployment. Each object in the array represents an individual Virtual WAN Hub configuration. Add/remove additional objects in the array to meet the number of Virtual WAN Hubs required.

// - `parVpnGatewayEnabled` - Switch to enable/disable VPN Gateway deployment on the respective Virtual WAN Hub.
// - `parExpressRouteGatewayEnabled` - Switch to enable/disable ExpressRoute Gateway deployment on the respective Virtual WAN Hub.
// - `parAzFirewallEnabled` - Switch to enable/disable Azure Firewall deployment on the respective Virtual WAN Hub.
// - `parVirtualHubAddressPrefix` - The IP address range in CIDR notation for the vWAN virtual Hub to use.
// - `parHubLocation` - The Virtual WAN Hub location.
// - `parHubRoutingPreference` - The Virtual WAN Hub routing preference. The allowed values are `ASN`, `VpnGateway`, `ExpressRoute`.
// - `parVirtualRouterAutoScaleConfiguration` - The Virtual WAN Hub capacity. The value should be between 2 to 50.
// - `parVirtualHubRoutingIntentDestinations` - The Virtual WAN Hub routing intent destinations, leave empty if not wanting to enable routing intent. The allowed values are `Internet`, `PrivateTraffic`.

// ''')
// param parVirtualWanHubs virtualWanOptionsType = [ {
//     parVpnGatewayEnabled: false
//     parExpressRouteGatewayEnabled: false
//     parAzFirewallEnabled: true
//     parVirtualHubAddressPrefix: '10.1.0.0/16'
//     parHubLocation: parLocation
//     parHubRoutingPreference: 'ExpressRoute'
//     parVirtualRouterAutoScaleConfiguration: 2
//     parVirtualHubRoutingIntentDestinations: []
//   }
// ]

// @sys.description('''Resource Lock Configuration for Virtual WAN Hub VPN Gateway.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parVpnGatewayLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

// @sys.description('''Resource Lock Configuration for Virtual WAN Hub ExpressRoute Gateway.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parExpressRouteGatewayLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

// @sys.description('''Resource Lock Configuration for Virtual WAN Hub.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parVirtualWanHubsLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

// @sys.description('VPN Gateway Name.')
// param parVpnGatewayName string = '${parCompanyPrefix}-vpngw'

// @sys.description('ExpressRoute Gateway Name.')
// param parExpressRouteGatewayName string = '${parCompanyPrefix}-ergw'

// @sys.description('Azure Firewall Name.')
// param parAzFirewallName string

// @allowed([
//   '1'
//   '2'
//   '3'
// ])
// @sys.description('Availability Zones to deploy the Azure Firewall across. Region must support Availability Zones to use. If it does not then leave empty.')
// param parAzFirewallAvailabilityZones array = []

// @sys.description('Azure Firewall Policies Name.')
// param parAzFirewallPoliciesName string

// @sys.description('''Resource Lock Configuration for Azure Firewall.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parAzureFirewallLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

// @sys.description('The scale unit for this VPN Gateway.')
// param parVpnGatewayScaleUnit int = 1

// @sys.description('The scale unit for this ExpressRoute Gateway.')
// param parExpressRouteGatewayScaleUnit int = 1

// @sys.description('Switch to enable/disable DDoS Network Protection deployment.')
// param parDdosEnabled bool = false

// @sys.description('DDoS Plan Name.')
// param parDdosPlanName string = '${parCompanyPrefix}-ddos-plan'

// @sys.description('''Resource Lock Configuration for DDoS Plan.

// - `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
// - `notes` - Notes about this lock.

// ''')
// param parDdosLock lockType = {
//   kind: 'None'
//   notes: 'This lock was created by the ALZ Bicep vWAN Connectivity Module.'
// }

@sys.description('Switch to enable/disable Private DNS Zones deployment.')
param parPrivateDnsZonesEnabled bool = false

@sys.description('Resource Group Name for Private DNS Zones.')
param parPrivateDnsZonesResourceGroup string = resourceGroup().name

@sys.description('Array of DNS Zones to provision in Hub Virtual Network.')
param parPrivateDnsZones array = []
// param parPrivateDnsZones array = [
//   'privatelink.${toLower(parLocation)}.azmk8s.io'
//   'privatelink.${toLower(parLocation)}.batch.azure.com'
//   'privatelink.${toLower(parLocation)}.kusto.windows.net'
//   'privatelink.adf.azure.com'
//   'privatelink.afs.azure.net'
//   'privatelink.agentsvc.azure-automation.net'
//   'privatelink.analysis.windows.net'
//   'privatelink.api.azureml.ms'
//   'privatelink.azconfig.io'
//   'privatelink.azure-api.net'
//   'privatelink.azure-automation.net'
//   'privatelink.azurecr.io'
//   'privatelink.azure-devices.net'
//   'privatelink.azure-devices-provisioning.net'
//   'privatelink.azuredatabricks.net'
//   'privatelink.azurehdinsight.net'
//   'privatelink.azurehealthcareapis.com'
//   'privatelink.azurestaticapps.net'
//   'privatelink.azuresynapse.net'
//   'privatelink.azurewebsites.net'
//   'privatelink.batch.azure.com'
//   'privatelink.blob.core.windows.net'
//   'privatelink.cassandra.cosmos.azure.com'
//   'privatelink.cognitiveservices.azure.com'
//   'privatelink.database.windows.net'
//   'privatelink.datafactory.azure.net'
//   'privatelink.dev.azuresynapse.net'
//   'privatelink.dfs.core.windows.net'
//   'privatelink.dicom.azurehealthcareapis.com'
//   'privatelink.digitaltwins.azure.net'
//   'privatelink.directline.botframework.com'
//   'privatelink.documents.azure.com'
//   'privatelink.eventgrid.azure.net'
//   'privatelink.file.core.windows.net'
//   'privatelink.gremlin.cosmos.azure.com'
//   'privatelink.guestconfiguration.azure.com'
//   'privatelink.his.arc.azure.com'
//   'privatelink.kubernetesconfiguration.azure.com'
//   'privatelink.managedhsm.azure.net'
//   'privatelink.mariadb.database.azure.com'
//   'privatelink.media.azure.net'
//   'privatelink.mongo.cosmos.azure.com'
//   'privatelink.monitor.azure.com'
//   'privatelink.mysql.database.azure.com'
//   'privatelink.notebooks.azure.net'
//   'privatelink.ods.opinsights.azure.com'
//   'privatelink.oms.opinsights.azure.com'
//   'privatelink.pbidedicated.windows.net'
//   'privatelink.postgres.database.azure.com'
//   'privatelink.prod.migration.windowsazure.com'
//   'privatelink.purview.azure.com'
//   'privatelink.purviewstudio.azure.com'
//   'privatelink.queue.core.windows.net'
//   'privatelink.redis.cache.windows.net'
//   'privatelink.redisenterprise.cache.azure.net'
//   'privatelink.search.windows.net'
//   'privatelink.service.signalr.net'
//   'privatelink.servicebus.windows.net'
//   'privatelink.siterecovery.windowsazure.com'
//   'privatelink.sql.azuresynapse.net'
//   'privatelink.table.core.windows.net'
//   'privatelink.table.cosmos.azure.com'
//   'privatelink.tip1.powerquery.microsoft.com'
//   'privatelink.token.botframework.com'
//   'privatelink.vaultcore.azure.net'
//   'privatelink.web.core.windows.net'
//   'privatelink.webpubsub.azure.com'
// ]

// @sys.description('Tags you would like to be applied to all resources in this module.')
//param parTags object = {}

// Azure Firewalls in Hubs
// var varAzureFirewallInHubs = filter(parVirtualWanHubs, hub => hub.parAzFirewallEnabled == true)

// Virtual WAN resource
// resource resVwan 'Microsoft.Network/virtualWans@2023-04-01' = {
//   name: parVirtualWanName
//   location: parLocation
//   tags: parTags
//   properties: {
//     allowBranchToBranchTraffic: true
//     allowVnetToVnetTraffic: true
//     disableVpnEncryption: false
//     type: 'Standard'
//   }
// }

// Create a Virtual WAN resource lock if parGlobalResourceLock.kind is not set to None and if parVirtualWanLock.kind is not set to None
// resource resVwanLock 'Microsoft.Authorization/locks@2020-05-01' = if (parGlobalResourceLock.kind != 'None' && parVirtualWanLock.kind != 'None') {
//   scope: resVwan
//   name: parVirtualWanLock.?name ?? '${resVwan.name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parVirtualWanLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parVirtualWanLock.?notes
//   }
// }

// resource resVhub 'Microsoft.Network/virtualHubs@2023-04-01' = [for hub in parVirtualWanHubs: if (parVirtualHubEnabled && !empty(hub.parVirtualHubAddressPrefix)) {
//   name: hub.?parVirtualWanHubCustomName ?? '${parVirtualWanHubName}-${hub.parHubLocation}'
//   location: hub.parHubLocation
//   tags: parTags
//   properties: {
//     addressPrefix: hub.parVirtualHubAddressPrefix
//     sku: 'Standard'
//     virtualWan: {
//       id: resVwan.id
//     }
//     virtualRouterAutoScaleConfiguration: {
//       minCapacity: hub.parVirtualRouterAutoScaleConfiguration
//     }
//     hubRoutingPreference: hub.parHubRoutingPreference
//   }
// }]

// Create a Virtual WAN Hub resource lock for each Virtual WAN Hub in parVirtualWanHubs if parGlobalResourceLock.kind is not set to None and if parVirtualWanHubsLock.kind is not set to None
// resource resVhubLock 'Microsoft.Authorization/locks@2020-05-01' = [for (hub, i) in parVirtualWanHubs: if (parGlobalResourceLock.kind != 'None' && parVirtualWanHubsLock.kind != 'None') {
//   scope: resVhub[i]
//   name: parVirtualWanHubsLock.?name ?? '${resVhub[i].name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parVirtualWanHubsLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parVirtualWanHubsLock.?notes
//   }
// }]

// resource resVhubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2023-04-01' = [for (hub, i) in parVirtualWanHubs: if (parVirtualHubEnabled && hub.parAzFirewallEnabled && empty(hub.parVirtualHubRoutingIntentDestinations)) {
//   parent: resVhub[i]
//   name: 'defaultRouteTable'
//   properties: {
//     labels: [
//       'default'
//     ]
//     routes: [
//       {
//         name: 'default-to-azfw'
//         destinations: [
//           '0.0.0.0/0'
//         ]
//         destinationType: 'CIDR'
//         nextHop: (parVirtualHubEnabled && hub.parAzFirewallEnabled) ? resAzureFirewall[i].id : ''
//         nextHopType: 'ResourceId'
//       }
//     ]
//   }
// }]

// resource resVhubRoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2023-04-01' = [for (hub, i) in parVirtualWanHubs: if (parVirtualHubEnabled && hub.parAzFirewallEnabled && !empty(hub.parVirtualHubRoutingIntentDestinations)) {
//   parent: resVhub[i]
//   name: !empty(hub.?parVirtualWanHubCustomName) ? '${hub.parVirtualWanHubCustomName}-Routing-Intent' : '${parVirtualWanHubName}-${hub.parHubLocation}-Routing-Intent'
//   properties: {
//     routingPolicies: [for destination in hub.parVirtualHubRoutingIntentDestinations: {
//       name: destination == 'Internet' ? 'PublicTraffic' : destination == 'PrivateTraffic' ? 'PrivateTraffic' : 'N/A'
//       destinations: [
//         destination
//       ]
//       nextHop: resAzureFirewall[i].id
//     }]
//   }
// }]

// resource resVpnGateway 'Microsoft.Network/vpnGateways@2023-02-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parVpnGatewayEnabled)) {
//   dependsOn: resVhub
//   name: hub.?parVpnGatewayCustomName ?? '${parVpnGatewayName}-${hub.parHubLocation}'
//   location: hub.parHubLocation
//   tags: parTags
//   properties: {
//     bgpSettings: {
//       asn: 65515
//       bgpPeeringAddress: ''
//       peerWeight: 5
//     }
//     virtualHub: {
//       id: resVhub[i].id
//     }
//     vpnGatewayScaleUnit: parVpnGatewayScaleUnit
//   }
// }]

// Create a Virtual Network Gateway resource lock if gateway.name is not equal to noconfigVpn or noconfigEr and parGlobalResourceLock.kind != 'None' or if parVpnGatewayLock.kind != 'None'
// resource resVpnGatewayLock 'Microsoft.Authorization/locks@2020-05-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parVpnGatewayEnabled) && (parVpnGatewayLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
//   scope: resVpnGateway[i]
//   name: parVpnGatewayLock.?name ?? '${resVpnGateway[i].name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parVpnGatewayLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parVpnGatewayLock.?notes
//   }
// }]

// resource resErGateway 'Microsoft.Network/expressRouteGateways@2023-02-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parExpressRouteGatewayEnabled)) {
//   dependsOn: resVhub
//   name: hub.?parExpressRouteGatewayCustomName ?? '${parExpressRouteGatewayName}-${hub.parHubLocation}'
//   location: hub.parHubLocation
//   tags: parTags
//   properties: {
//     virtualHub: {
//       id: resVhub[i].id
//     }
//     autoScaleConfiguration: {
//       bounds: {
//         min: parExpressRouteGatewayScaleUnit
//       }
//     }
//   }
// }]

// // Create a Virtual Network Gateway resource lock if gateway.name is not equal to noconfigVpn or noconfigEr and parGlobalResourceLock.kind != 'None' or if parVpnGatewayLock.kind != 'None'
// resource resErGatewayLock 'Microsoft.Authorization/locks@2020-05-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parExpressRouteGatewayEnabled) && (parExpressRouteGatewayLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
//   scope: resVpnGateway[i]
//   name: parExpressRouteGatewayLock.?name ?? '${resErGateway[i].name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parExpressRouteGatewayLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parExpressRouteGatewayLock.?notes
//   }
// }]

// resource resFirewallPolicies 'Microsoft.Network/firewallPolicies@2023-02-01' = if (parVirtualHubEnabled && parVirtualWanHubs[0].parAzFirewallEnabled) {
//   name: parAzFirewallPoliciesName
//   location: parLocation
//   tags: parTags
//   properties: (parAzFirewallTier == 'Basic') ? {
//     sku: {
//       tier: parAzFirewallTier
//     }
//     threatIntelMode: 'Alert'
//   } : {
//     dnsSettings: {
//       enableProxy: parAzFirewallDnsProxyEnabled
//       servers: parAzFirewallDnsServers
//     }
//     sku: {
//       tier: parAzFirewallTier
//     }
//     threatIntelMode: parAzFirewallIntelMode
//   }
// }

// resource fwRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = {
//   name: 'string'
//   parent: resFirewallPolicies
//   properties: {
//     priority: 200
//     ruleCollections: [
//       {
//         name: 'string'
//         priority: 101
//         ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
//         action: {
//           type: 'Allow'
//         }
//         rules: [
//           {
//             description: 'string'
//             name: 'fierwalldnsrulecollection'
//             ruleType: 'NetworkRule'
//             // For remaining properties, see FirewallPolicyRule objects
//           }
//         ]
//       }
//     ]
//   }
// }

// Create Azure Firewall Policy resource lock if parAzFirewallEnabled is true and parGlobalResourceLock.kind != 'None' or if parAzureFirewallLock.kind != 'None'
// resource resFirewallPoliciesLock 'Microsoft.Authorization/locks@2020-05-01' = if ((parVirtualHubEnabled && parVirtualWanHubs[0].parAzFirewallEnabled) && (parAzureFirewallLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
//   scope: resFirewallPolicies
//   name: parAzureFirewallLock.?name ?? '${resFirewallPolicies.name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parAzureFirewallLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parAzureFirewallLock.?notes
//   }
// }

// resource resAzureFirewall 'Microsoft.Network/azureFirewalls@2023-02-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parAzFirewallEnabled)) {
//   name: hub.?parAzFirewallCustomName ?? '${parAzFirewallName}-${hub.parHubLocation}'
//   location: hub.parHubLocation
//   tags: parTags
//   zones: (!empty(parAzFirewallAvailabilityZones) ? parAzFirewallAvailabilityZones : null)
//   properties: {
//     hubIPAddresses: {
//       publicIPs: {
//         count: 1
//       }
//     }
//     sku: {
//       name: 'AZFW_Hub'
//       tier: parAzFirewallTier
//     }
//     virtualHub: {
//       id: parVirtualHubEnabled ? resVhub[i].id : ''
//     }
//     firewallPolicy: {
//       id: (parVirtualHubEnabled && hub.parAzFirewallEnabled) ? resFirewallPolicies.id : ''
//     }
//   }
// }]

// Create Azure Firewall resource lock if parAzFirewallEnabled is true and parGlobalResourceLock.kind != 'None' or if parAzureFirewallLock.kind != 'None'
// resource resAzureFirewallLock 'Microsoft.Authorization/locks@2020-05-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parAzFirewallEnabled) && (parAzureFirewallLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
//   scope: resAzureFirewall[i]
//   name: parAzureFirewallLock.?name ?? '${resAzureFirewall[i].name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parAzureFirewallLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parAzureFirewallLock.?notes
//   }
// }]

// DDoS plan is deployed even though not supported to attach to Virtual WAN today as per https://docs.microsoft.com/azure/firewall-manager/overview#known-issues - However, it can still be linked via policy to spoke VNets etc.
// resource resDdosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2023-02-01' = if (parDdosEnabled) {
//   name: parDdosPlanName
//   location: parLocation
//   tags: parTags
// }

// // Create resource lock if parDdosEnabled is true and parGlobalResourceLock.kind != 'None' or if parDdosLock.kind != 'None'
// resource resDDoSProtectionPlanLock 'Microsoft.Authorization/locks@2020-05-01' = if (parDdosEnabled && (parDdosLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
//   scope: resDdosProtectionPlan
//   name: parDdosLock.?name ?? '${resDdosProtectionPlan.name}-lock'
//   properties: {
//     level: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.kind : parDdosLock.kind
//     notes: (parGlobalResourceLock.kind != 'None') ? parGlobalResourceLock.?notes : parDdosLock.?notes
//   }
// }

// Private DNS Zones cannot be linked to the Virtual WAN Hub today however, they can be linked to spokes as they are normal VNets as per https://docs.microsoft.com/azure/virtual-wan/howto-private-link
module privateDNSZones '../../shared/bicep/network/private-dns-zone.bicep' =[ for privateDNSZoneName in parPrivateDnsZones: if (parPrivateDnsZonesEnabled) {
  name: 'deploy-Private-DNS-Zones-${privateDNSZoneName}'
  scope: resourceGroup(parPrivateDnsZonesResourceGroup)
  params: {
    name: privateDNSZoneName
  }
}]

// Output Virtual WAN name and ID
// output outVirtualWanName string = resVwan.name
// output outVirtualWanId string = resVwan.id

// Output Virtual WAN Hub name and ID
// output outVirtualHubName array = [for (hub, i) in parVirtualWanHubs: {
//   virtualhubname: resVhub[i].name
//   virtualhubid: resVhub[i].id
// }]

// output outVirtualHubId array = [for (hub, i) in parVirtualWanHubs: {
//   virtualhubid: resVhub[i].id
// }]

// Output DDoS Plan ID
// output outDdosPlanResourceId string = resDdosProtectionPlan.id

// Output Azure Firewall Private IP's
// output outAzFwPrivateIps array = [for (hub, i) in varAzureFirewallInHubs: {
//   '${parVirtualWanHubName}-${hub.parHubLocation}': reference(resAzureFirewall[i].id, '2023-02-01').hubIPAddresses.privateIPAddress
// }]
