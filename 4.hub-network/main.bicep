targetScope = 'subscription'

// ------------------
//    Paramaters
// ------------------

param parConnectivitySubscriptionId string = ''

// @sys.description('The Azure Firewall Threat Intelligence Mode.')
// @allowed([
//   'Alert'
//   'Deny'
//   'Off'
// ])
// param parAzFirewallIntelMode string = 'Alert'

// ------------------
//    Variables
// ------------------

var connectivityResourceGroup = 'rg-hra-connectivity'
// var virtualWanNamePrefix  = 'vwan-rsp'

// @sys.description('Azure Firewall Tier associated with the Firewall to deploy.')
// var azFirewallTier = 'Standard'

@description('Deploy vWan Hub')
module vWanHubdeployment 'modules/vWanHub.bicep' = {
  name: take('vWanHubdeployment-${deployment().name}', 64)
  scope: resourceGroup(parConnectivitySubscriptionId,connectivityResourceGroup)
  params: {
    // parAzFirewallTier: azFirewallTier
    // parAzFirewallIntelMode: parAzFirewallIntelMode
    // parVirtualHubEnabled: false
    // parAzFirewallDnsProxyEnabled: false
    // parVirtualWanNamePrefix: virtualWanNamePrefix
    // parVirtualWanHubName: 'vhub-rsp'
    // parCompanyPrefix: 'rsp'
    // parAzFirewallName: 'fw-vWan-rsp'
    // parAzFirewallPoliciesName: 'azfwpolicy-rsp-uksouth'
    // parTags: {}
  }
}
