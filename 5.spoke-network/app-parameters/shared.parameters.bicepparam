using none

param location = 'uksouth'

param tags = {}


param parSqlAuditRetentionDays = 15

// Azure Front Door Configuration
param parEnableFrontDoor = false
param parFrontDoorWafMode = 'Prevention'
param parEnableFrontDoorRateLimiting = true
param parFrontDoorRateLimitThreshold = 1000
param parEnableFrontDoorCaching = true
param parFrontDoorCacheDuration = 'P1D'
param parEnableFrontDoorHttpsRedirect = true
param parEnableFrontDoorPrivateLinkForIRAS = false
param parEnableFrontDoorPrivateLinkForCMS = true
param parFrontDoorCustomDomains = []
param parEnableFrontDoorIPWhitelisting = false
