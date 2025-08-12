using 'main.bicep'

// VNet peering configuration - comma-separated list of spoke VNet IDs to peer with Management DevOps Pool
param paramvnetPeeringsVNetIDs = '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-networking-spoke-dev-uks/providers/Microsoft.Network/virtualNetworks/vnet-rsp-networking-dev-uks-spoke'

// Service IDs for private endpoints - comma-separated list of Azure service resource IDs
param paramserviceIds = '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-applications-spoke-dev-uks/providers/Microsoft.ContainerRegistry/registries/acrrspsharingdevuks'

// Management DevOps Pool VNet ID - the source VNet for peering and private endpoints
param manageddevopspoolVnetID = '/subscriptions/8747cd7f-1a06-4fe4-9dbb-24f612b9dd5a/resourceGroups/rg-hra-manageddevopspool/providers/Microsoft.Network/virtualNetworks/vnet-rsp-networking-devopspool'

// Enable DevBox storage private endpoints for dev environment
param enableDevBoxStorageEndpoints = true

// Environment name
param environment = 'dev'

// DevBox storage private endpoints configuration
param storageSubscriptionId = 'b83b4631-b51b-4961-86a1-295f539c826b'
param storageResourceGroupName = 'rg-rsp-storage-spoke-dev-uks'
param devboxSubscriptionId = '9ef9a127-7a6e-452e-b18d-d2e2e89ffa92'
param devboxResourceGroupName = 'rg-rsp-devcenter'
param devboxVNetName = 'vnet-dbox-rsp-uksouth'
param devboxPrivateEndpointSubnetName = 'sn-devpools'