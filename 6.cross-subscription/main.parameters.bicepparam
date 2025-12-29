using 'main.bicep'

// VNet peering configuration - comma-separated list of spoke VNet IDs to peer with Management DevOps Pool
param paramvnetPeeringsVNetIDs = ''

// Service IDs for private endpoints - comma-separated list of Azure service resource IDs for THIS environment
param paramserviceIds = ''

// Management DevOps Pool VNet ID - the source VNet for peering and private endpoints
param manageddevopspoolVnetID = ''

// Enable DevBox storage private endpoints for dev environment
param enableDevBoxStorageEndpoints = true

// Enable DevBox SQL replica private endpoints
param enableDevBoxSqlReplicaEndpoints = true

// Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{server-name},...
param replicaSqlServerResourceId = '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-storage-spoke-dev-ukw/providers/Microsoft.Sql/servers/rspsqlserverdevreplica'

// Format: rspsqlserverdevreplica...
param replicaSqlServerName = 'rspsqlserverdevreplica'

// Secondary region VNet IDs (comma-separated) to peer with DevBox VNet
param devBoxSecondaryVNetIds = '/subscriptions/b83b4631-b51b-4961-86a1-295f539c826b/resourceGroups/rg-rsp-networking-spoke-dev-ukw/providers/Microsoft.Network/virtualNetworks/vnet-rsp-networking-dev-ukw-spoke' //This is temporary and would be passed via variable groups

// Environment name
param environment = 'dev'

// DevBox storage private endpoints configuration
param storageSubscriptionId = ''
param storageResourceGroupName = 'rg-rsp-storage-spoke-dev-uks'
param devboxSubscriptionId = ''
param devboxResourceGroupName = 'rg-rsp-devcenter'
param devboxVNetName = 'vnet-dbox-rsp-uksouth'
param devboxPrivateEndpointSubnetName = 'sn-devpools'

// DW Function App private endpoint deployment flag
param deployDwPrivateEndpoints = false

// DW Function App resource ID
param dwFunctionAppId = ''

// DW Function App subscription ID (where the private endpoint should be created)
param dwFunctionAppSubscriptionId = ''

// DW networking configuration
param dwNetworkingResourceGroup = ''
param dwVnetName = ''
param dwPrivateEndpointSubnetName = ''
param dwEnvironment = ''
