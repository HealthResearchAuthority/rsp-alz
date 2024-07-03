 targetScope = 'resourceGroup'

@description('Azure region where the resources will be deployed in')
param location string = resourceGroup().location

param logAnalyticsWsId string
param resourcesNames object

@description('CIDR of the SPOKE vnet i.e. 192.168.0.0/24')
param vnetSpokeAddressSpace string

@description('CIDR of the subnet that will hold the app services plan')
param subnetSpokeAppSvcAddressPrefix string

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param tags object

@description('Optional S1 is default. Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deploying at least three instances in three Availability Zones. EP* is only for functions')
@allowed([ 'B1','S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ', 'EP1', 'EP2', 'EP3', 'ASE_I1V2_AZ', 'ASE_I2V2_AZ', 'ASE_I3V2_AZ', 'ASE_I1V2', 'ASE_I2V2', 'ASE_I3V2' ])
param webAppPlanSku string

module webApp 'modules/app-service.module.bicep' = {
  name: 'webAppModule-Deployment'
  params: {
    appServicePlanName: resourceNames.aspName
    webAppName: resourceNames.webApp
    //managedIdentityName: resourceNames.appSvcUserAssignedManagedIdentity
    location: location
    logAnalyticsWsId: logAnalyticsWsId
    //subnetIdForVnetInjection: snetAppSvc.id
    tags: tags
    //subnetPrivateEndpointId: snetPe.id
    //virtualNetworkLinks: virtualNetworkLinks   
    //appConfigurationName: resourceNames.appConfig
    sku: webAppPlanSku
    //keyvaultName: keyvault.outputs.keyvaultName
    //deployAppConfig: deployAppConfig
  }
}

//output sampleAppIngress string = webApp.outputs.fqdn
