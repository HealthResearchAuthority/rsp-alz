using 'main.bicep'

// VNet peering configuration - comma-separated list of spoke VNet IDs to peer with Management DevOps Pool
param paramvnetPeeringsVNetIDs = ''

// Service IDs for private endpoints - comma-separated list of Azure service resource IDs
param paramserviceIds = ''

// Management DevOps Pool VNet ID - the source VNet for peering and private endpoints
param manageddevopspoolVnetID = ''

// Enable DevBox storage private endpoints for dev environment
param enableDevBoxStorageEndpoints = true

// Environment name
param environment = 'dev'

// DevBox storage private endpoints configuration
param storageSubscriptionId = ''
param storageResourceGroupName = 'rg-rsp-storage-spoke-dev-uks'
param devboxSubscriptionId = ''
param devboxResourceGroupName = 'rg-rsp-devcenter'
param devboxVNetName = 'vnet-dbox-rsp-uksouth'
param devboxPrivateEndpointSubnetName = 'sn-devpools'
