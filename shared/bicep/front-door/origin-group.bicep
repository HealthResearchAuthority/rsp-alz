// ------------------
// PARAMETERS
// ------------------

@description('Required. Name of the origin group.')
param name string

@description('Required. The name of the Front Door profile.')
param frontDoorProfileName string


@description('Required. The origins for the origin group.')
param origins array

@description('Optional. Load balancing settings.')
param loadBalancingSettings object = {
  sampleSize: 4
  successfulSamplesRequired: 3
  additionalLatencyInMilliseconds: 50
}

@description('Optional. Session affinity state.')
@allowed([
  'Enabled'
  'Disabled'
])
param sessionAffinityState string = 'Disabled'

@description('Optional. Whether to restore traffic time in minutes.')
param trafficRestorationTimeToHealedOrNewEndpointsInMinutes int = 10

// ------------------
// RESOURCES
// ------------------

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: frontDoorProfileName
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  name: name
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: loadBalancingSettings
    healthProbeSettings: {
      probePath: '/'
      probeProtocol: 'NotSet'
      probeRequestType: 'GET'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: sessionAffinityState
    trafficRestorationTimeToHealedOrNewEndpointsInMinutes: trafficRestorationTimeToHealedOrNewEndpointsInMinutes
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = [for originConfig in origins: {
  name: originConfig.name
  parent: originGroup
  properties: {
    hostName: originConfig.hostName
    httpPort: originConfig.?httpPort ?? 80
    httpsPort: originConfig.?httpsPort ?? 443
    originHostHeader: originConfig.?originHostHeader ?? originConfig.hostName
    priority: originConfig.?priority ?? 1
    weight: originConfig.?weight ?? 1000
    enabledState: (originConfig.?enabled ?? true) ? 'Enabled' : 'Disabled'
    enforceCertificateNameCheck: originConfig.?enforceCertificateNameCheck ?? true
    sharedPrivateLinkResource: originConfig.?privateLinkResourceId != null ? {
      privateLink: {
        id: originConfig.privateLinkResourceId
      }
      privateLinkLocation: originConfig.?privateLinkLocation ?? resourceGroup().location
      requestMessage: originConfig.?privateLinkRequestMessage ?? 'Request access for Front Door'
      groupId: originConfig.?groupId ?? 'sites'
    } : null
  }
}]

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the origin group.')
output resourceId string = originGroup.id

@description('The name of the origin group.')
output name string = originGroup.name

@description('The resource group the origin group was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The origins created.')
output origins array = [for (originConfig, i) in origins: {
  name: origin[i].name
  hostName: origin[i].properties.hostName
  resourceId: origin[i].id
}]