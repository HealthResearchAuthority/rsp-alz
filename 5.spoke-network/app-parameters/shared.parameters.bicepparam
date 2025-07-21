using none

param location = 'uksouth'

param tags = {}

param logAnalyticsWorkspaceId = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-operationsmanagement/providers/Microsoft.OperationalInsights/workspaces/hra-rsp-log-analytics'

param parSqlAuditRetentionDays = 15

// Azure Front Door Configuration
param parEnableFrontDoor = false
param parFrontDoorWafMode = 'Prevention'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 1000
param parEnableFrontDoorCaching = true
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLink = false
param parFrontDoorCustomDomains = []
