param (
  [Parameter()]
  [String]$Location = "$($env:LOCATION)",

  [Parameter()]
  [String]$MGForPolicies = "$($env:WORKLOADS_MG_ID)",

  [Parameter()]
  [String]$TemplateFile = "config\custom-modules\policy\definitions\customPolicyDefinitions.bicep",

  [Parameter()]
  [String]$TemplateParameterFile = "config\custom-parameters\customPolicyDefinitions.parameters.all.json",

  [Parameter()]
  [Boolean]$WhatIfEnabled = [System.Convert]::ToBoolean($($env:IS_PULL_REQUEST))
)

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'alz-PolicyDefsDeployment-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = $Location
  ManagementGroupId     = $MGForPolicies
  TemplateFile          = $TemplateFile
  TemplateParameterFile = $TemplateParameterFile
  WhatIf                = $WhatIfEnabled
  Verbose               = $true
}

New-AzManagementGroupDeployment @inputObject
