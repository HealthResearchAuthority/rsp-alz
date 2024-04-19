targetScope = 'managementGroup'

metadata name = 'ALZ Bicep - Management Groups Module with Scope Escape'
metadata description = 'ALZ Bicep Module to set up Management Group structure, using Scope Escaping feature of ARM to allow deployment not requiring tenant root scope access.'

@sys.description('Prefix used for the management group hierarchy. This management group will be created as part of the deployment.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'mg-rsp'

@sys.description('Optional suffix for the management group hierarchy. This suffix will be appended to management group names/IDs. Include a preceding dash if required. Example: -suffix')
@maxLength(10)
param parTopLevelManagementGroupSuffix string = ''

@sys.description('Display name for top level management group. This name will be applied to the management group prefix defined in parTopLevelManagementGroupPrefix parameter.')
@minLength(2)
param parTopLevelManagementGroupDisplayName string = 'Future IRAS'

@sys.description('Optional parent for Management Group hierarchy, used as intermediate root Management Group parent, if specified. If empty, default, will deploy beneath Tenant Root Management Group.')
param parTopLevelManagementGroupParentId string = ''

// Platform and Child Management Groups
var varPlatformMg = {
  name: '${parTopLevelManagementGroupPrefix}-platform'
  displayName: 'Platform'
}

// Used if parPlatformMgAlzDefaultsEnable == true
var varPlatformMgChildrenAlzDefault = {
  connectivity: {
    displayName: 'Connectivity'
  }
  management: {
    displayName: 'Management'
  }
}

// Workloads & Child Management Groups
var varLandingZoneMg = {
  name: '${parTopLevelManagementGroupPrefix}-workloads'
  displayName: 'Workloads'
}

// Used if parLandingZoneMgAlzDefaultsEnable == true
var varLandingZoneMgChildrenAlzDefault = {
  nonprod: {
    displayName: 'NonProd'
  }
  prod: {
    displayName: 'Prod'
  }
}

// Sandbox Management Group
var varSandboxMg = {
  name: '${parTopLevelManagementGroupPrefix}-sandbox${parTopLevelManagementGroupSuffix}'
  displayName: 'Sandbox'
}

// DevBox Management Group
var varDevelopmentboxMg = {
  name: '${parTopLevelManagementGroupPrefix}-devbox'
  displayName: 'Dev Box'
}

// Level 1
resource resTopLevelMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'mg-future-iras'
  scope: tenant()
  properties: {
    displayName: parTopLevelManagementGroupDisplayName
    details: {
      parent: {
        id: empty(parTopLevelManagementGroupParentId) ? '/providers/Microsoft.Management/managementGroups/${tenant().tenantId}' : contains(toLower(parTopLevelManagementGroupParentId), toLower('/providers/Microsoft.Management/managementGroups/')) ? parTopLevelManagementGroupParentId : '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupParentId}'
      }
    }
  }
}

// Level 2
resource resPlatformMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: varPlatformMg.name
  scope: tenant()
  properties: {
    displayName: varPlatformMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

resource resLandingZonesMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: varLandingZoneMg.name
  scope: tenant()
  properties: {
    displayName: varLandingZoneMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

resource resSandboxMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: varSandboxMg.name
  scope: tenant()
  properties: {
    displayName: varSandboxMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

resource resDevelopmentBoxMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: varDevelopmentboxMg.name
  properties: {
    displayName: varDevelopmentboxMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

// Level 3 - Child Management Groups under Landing Zones MG
resource resLandingZonesChildMgs 'Microsoft.Management/managementGroups@2023-04-01' = [for mg in items(varLandingZoneMgChildrenAlzDefault): if (!empty(varLandingZoneMgChildrenAlzDefault)) {
  name: '${parTopLevelManagementGroupPrefix}-workloads-${mg.key}'
  scope: tenant()
  properties: {
    displayName: mg.value.displayName
    details: {
      parent: {
        id: resLandingZonesMg.id
      }
    }
  }
}]

//Level 3 - Child Management Groups under Platform MG
resource resPlatformChildMgs 'Microsoft.Management/managementGroups@2023-04-01' = [for mg in items(varPlatformMgChildrenAlzDefault): if (!empty(varPlatformMgChildrenAlzDefault)) {
  name: '${parTopLevelManagementGroupPrefix}-platform-${mg.key}'
  scope: tenant()
  properties: {
    displayName: mg.value.displayName
    details: {
      parent: {
        id: resPlatformMg.id
      }
    }
  }
}]

// Output Management Group IDs
output outTopLevelManagementGroupId string = resTopLevelMg.id

output outPlatformManagementGroupId string = resPlatformMg.id
output outPlatformChildrenManagementGroupIds array = [for mg in items(varPlatformMgChildrenAlzDefault): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-platform-${mg.key}']

output outLandingZonesManagementGroupId string = resLandingZonesMg.id
output outLandingZoneChildrenManagementGroupIds array = [for mg in items(varLandingZoneMgChildrenAlzDefault): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-workloads-${mg.key}']

output outSandboxManagementGroupId string = resSandboxMg.id
output outDevelopmentManagementGroupId string = resDevelopmentBoxMg.id

// Output Management Group Names
output outTopLevelManagementGroupName string = resTopLevelMg.name

output outPlatformManagementGroupName string = resPlatformMg.name
output outPlatformChildrenManagementGroupNames array = [for mg in items(varPlatformMgChildrenAlzDefault): mg.value.displayName]

output outLandingZonesManagementGroupName string = resLandingZonesMg.name
output outLandingZoneChildrenManagementGroupNames array = [for mg in items(varLandingZoneMgChildrenAlzDefault): mg.value.displayName]

output outSandboxManagementGroupName string = resSandboxMg.name
output outDevelopmentManagementGroupName string = resDevelopmentBoxMg.name
