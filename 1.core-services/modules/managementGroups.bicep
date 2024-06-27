targetScope = 'managementGroup'

metadata name = 'ALZ Bicep - Management Groups Module with Scope Escape'
metadata description = 'ALZ Bicep Module to set up Management Group structure, using Scope Escaping feature of ARM to allow deployment not requiring tenant root scope access.'

@sys.description('Prefix used for the management group hierarchy. This management group will be created as part of the deployment.')
@maxLength(10)
param parTopLevelManagementGroupPrefix string = ''

@sys.description('Optional parent for Management Group hierarchy, used as intermediate root Management Group parent, if specified. If empty, default, will deploy beneath Tenant Root Management Group.')
param parTopLevelManagementGroupParentId string

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

var varLandingZoneNonProdMgChildrenAlzDefault = {
  development: {
    displayName: 'Development'
  }
}

// DevBox Management Group
var varDevelopmentboxMg = {
  name: '${parTopLevelManagementGroupPrefix}-devbox'
  displayName: 'Dev Box'
}

// Level 2
resource resPlatformMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: varPlatformMg.name
  scope: tenant()
  properties: {
    displayName: varPlatformMg.displayName
    details: {
      parent: {
        //id: '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupParentId}'
        //id: tenantResourceId('Microsoft.Management/managementGroups','mg-future-iras')
        id: tenantResourceId('Microsoft.Management/managementGroups',parTopLevelManagementGroupParentId)
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
        id: tenantResourceId('Microsoft.Management/managementGroups',parTopLevelManagementGroupParentId)
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
        id: tenantResourceId('Microsoft.Management/managementGroups',parTopLevelManagementGroupParentId)
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

resource nonprodtargetManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: '${parTopLevelManagementGroupPrefix}-workloads-nonprod'
}

//Level 4 - Child Management Groups under NonProd
resource resLandingZoneNonProdChildMgs 'Microsoft.Management/managementGroups@2023-04-01' = [for mg in items(varLandingZoneNonProdMgChildrenAlzDefault): if (!empty(varLandingZoneNonProdMgChildrenAlzDefault)) {
  name: '${parTopLevelManagementGroupPrefix}-workloads-nonprod-${mg.key}'
  scope: tenant()
  properties: {
    displayName: mg.value.displayName
    details: {
      parent: {
        id: nonprodtargetManagementGroup.id
      }
    }
  }
}]

// Output Management Group IDs
//output outTopLevelManagementGroupId string = resTopLevelMg.id

output outPlatformManagementGroupId string = resPlatformMg.id
output outPlatformChildrenManagementGroupIds array = [for mg in items(varPlatformMgChildrenAlzDefault): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-platform-${mg.key}']

output outLandingZonesManagementGroupId string = resLandingZonesMg.id
output outLandingZoneChildrenManagementGroupIds array = [for mg in items(varLandingZoneMgChildrenAlzDefault): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-workloads-${mg.key}']
output outLandingZoneNonProdChildrenManagementGroupIds array = [for mg in items(varLandingZoneNonProdMgChildrenAlzDefault): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-workloads-nonprod-${mg.key}']

//output outSandboxManagementGroupId string = resSandboxMg.id
output outDevelopmentManagementGroupId string = resDevelopmentBoxMg.id

// Output Management Group Names
//output outTopLevelManagementGroupName string = resTopLevelMg.name

output outPlatformManagementGroupName string = resPlatformMg.name
output outPlatformChildrenManagementGroupNames array = [for mg in items(varPlatformMgChildrenAlzDefault): mg.value.displayName]

output outLandingZonesManagementGroupName string = resLandingZonesMg.name
output outLandingZoneChildrenManagementGroupNames array = [for mg in items(varLandingZoneMgChildrenAlzDefault): mg.value.displayName]
output outLandingZoneNonProdChildrenManagementGroupNames array = [for mg in items(varLandingZoneNonProdMgChildrenAlzDefault): mg.value.displayName]

//output outSandboxManagementGroupName string = resSandboxMg.name
output outDevelopmentManagementGroupName string = resDevelopmentBoxMg.name
