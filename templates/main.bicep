param rgName string = 'p2s-vpn-gw'

param location string = 'westeurope'

param storagePrefix string = 'bootst'

param tunnelKey string = 'P2S2021'

param adminUsername string = 'AzureAdmin'

param adminPassword string = 'P2SvpnGW-2021'

param VnetRange string = '10.1.0.0/16'
param GatewaySubnetRange string = '10.1.0.0/24'
param InsideSubnetRange string = '10.1.1.0/24'
param InsidePrivateIP string = '10.1.1.4'
param OutsideSubnetRange string = '10.1.2.0/24'
param OutsidePrivateIP string = '10.1.2.4'
param VPNPool string = '172.16.0.0/24'

targetScope = 'subscription'
 
resource vpngwRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module p2svpngw 'gw.bicep' = {
  name: 'p2svpngw'
  scope: vpngwRg
  params:{
    location: location

    storagePrefix: storagePrefix

    tunnelKey: tunnelKey

    adminUsername: adminUsername

    adminPassword: adminPassword

    VnetRange: VnetRange
    GatewaySubnetRange: GatewaySubnetRange
    InsideSubnetRange: InsideSubnetRange
    InsidePrivateIP: InsidePrivateIP
    OutsideSubnetRange: OutsideSubnetRange
    OutsidePrivateIP: OutsidePrivateIP
    VPNPool: VPNPool
  }
}
