using none

param location = 'uksouth'

param tags = {}

// logAnalyticsWorkspaceId is now passed securely via Azure DevOps pipeline variables

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
