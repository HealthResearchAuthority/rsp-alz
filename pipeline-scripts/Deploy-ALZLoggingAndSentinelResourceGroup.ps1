param (
  [Parameter()]
  [String]$Location = "$($env:LOCATION)",

  [Parameter()]
  [String]$TemplateFile = "upstream-releases\$($env:UPSTREAM_RELEASE_VERSION)\infra-as-code\bicep\modules\resourceGroup\resourceGroup.bicep",

  [Parameter()]
  [String]$TemplateParameterFile = "config\custom-parameters\resourceGroupLoggingAndSentinel.parameters.all.json",

  [Parameter()]
  [Boolean]$WhatIfEnabled = [System.Convert]::ToBoolean($($env:IS_PULL_REQUEST)),

  [Parameter()]
  [Boolean] $SubscriptionIds = 'hra-rsp-dev', 'hra-rsp-systemtest-manual', 'hra-rsp-systemtest-automated', 'hra-rsp-system-integration'
)

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'alz-LoggingAndSentinelRGDeploy-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = $Location
  TemplateFile          = $TemplateFile
  TemplateParameterFile = $TemplateParameterFile
  WhatIf                = $WhatIfEnabled
  Verbose               = $true
}

foreach ($ManagementSubscriptionId in $SubscriptionIds)
{
	Select-AzSubscription -SubscriptionId $ManagementSubscriptionId

	New-AzSubscriptionDeployment @inputObject
}

