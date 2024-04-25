param (
  [Parameter()]
  [String]$LoggingResourceGroup = "$($env:LOGGING_RESOURCE_GROUP)",

  [Parameter()]
  [String]$TemplateFile = "config\custom-modules\logging\logging.bicep",

  [Parameter()]
  [String]$TemplateParameterFile = "config\custom-parameters\logging.parameters.all.json",

  [Parameter()]
  [Boolean]$WhatIfEnabled = [System.Convert]::ToBoolean($($env:IS_PULL_REQUEST))

  [Parameter()]
  [String] $ManagementSubscriptionId = "9ef9a127-7a6e-452e-b18d-d2e2e89ffa92" #use existing Workspace under Dev-Box subscription
)

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'alz-LoggingDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = $LoggingResourceGroup
  TemplateFile          = $TemplateFile
  TemplateParameterFile = $TemplateParameterFile
  WhatIf                = $WhatIfEnabled
  Verbose               = $true
}

Select-AzSubscription -SubscriptionId $ManagementSubscriptionId

New-AzResourceGroupDeployment @inputObject
