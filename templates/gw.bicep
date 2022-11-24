param location string

param storagePrefix string

param tunnelKey string

param adminUsername string

param adminPassword string

param VnetRange string
param GatewaySubnetRange string
param InsideSubnetRange string
param InsidePrivateIP string
param OutsideSubnetRange string
param OutsidePrivateIP string
param VPNPool string

//public IP prefixes
resource prefixIpV4 'Microsoft.Network/publicIPPrefixes@2020-11-01' = {
  name: 'prefixIpV4'
  location: location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties: {
    prefixLength: 28
    publicIPAddressVersion: 'IPv4'
  }
}



// public IPs from prefixes
resource gwPubIpV4 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'gwPubIpV4'
  location: location
  sku:{
    name: 'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAllocationMethod: 'Static' 
    publicIPAddressVersion: 'IPv4'
    publicIPPrefix: {
      id: prefixIpV4.id
    }
  }
}

// public IPs from prefixes
resource csrPubIpV4 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'csrPubIpV4'
  location: location
  sku:{
    name: 'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAllocationMethod: 'Static' 
    publicIPAddressVersion: 'IPv4'
    publicIPPrefix: {
      id: prefixIpV4.id
    }
  }
}

// VNET
resource VpnVNET 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'VpnVNET'
  location: location
  dependsOn: [
    csrnsg
    CsrRT
  ]
  properties:{
    addressSpace:{
      addressPrefixes:[
        VnetRange       
      ]
    }
    subnets:[
      {
      name: 'InsideSubnet'
      properties:{
        addressPrefix:  InsideSubnetRange
        networkSecurityGroup: {
          id: csrnsg.id
        }
        routeTable: {
          id: CsrRT.id
        }
        
      }
    }     
    {
      name: 'GatewaySubnet'
      properties:{
        addressPrefix: GatewaySubnetRange
      }
    }
    {
      name: 'OutsideSubnet'
      properties:{
        addressPrefix: OutsideSubnetRange
        networkSecurityGroup: {
          id: csrnsg.id
        }
        routeTable: {
          id: CsrRT.id
        }
      }
    }  
    ]
  }
}
//VPN Gateway
resource VPNGW 'Microsoft.Network/virtualNetworkGateways@2021-02-01'= {
  name: 'VPNGW'
  location: location
  dependsOn:[
    VpnVNET
    gwPubIpV4
  ]
  properties:{
    ipConfigurations: [
      {
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','VpnVNET','GatewaySubnet')
          }
        publicIPAddress: {
          id: gwPubIpV4.id
          }
        }
      }
    ]
  
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    enableBgp: false
    enablePrivateIpAddress: true
    activeActive: false
    gatewayDefaultSite: null
    sku:{
      name: 'VpnGw1AZ'
      tier: 'VpnGw1AZ'
    }
    customRoutes:{
      addressPrefixes:[
        '0.0.0.0/1'
        '128.0.0.0/1'
      ]
    }
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          VPNPool
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'Certificate'
      ]
      vpnClientRootCertificates: [
        {
          name: 'P2SRoot'
          properties: {
            publicCertData: 'MIIC5zCCAc+gAwIBAgIQXjxQbTagALtEj8Jsp7oasDANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMjExMjQxNTAxNDZaFw0zMjExMjQxNTExNDVaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2JPuyKcHmW8VfA1lqNablWVXySwiUxJrSbjIuGboNaHlT6cMAUCKPxPhVrZ2R51SwHFSAtOpxiXVbyiU74KPJpGDUEWYG6C0HCzfG2kUGRQLHrIfSoUUIAr1vyYz948MZv0ONjvNeGG/jaC0xOfIz7ZgD4d7amBQjTpvwBY/mt1LJnW6Ab4QfhFKLUQp9zAuTpNj6lfCt/LNcgbbO78OvcA5hSu+7Hek16TPZo9EY7X4kr1VpgLPEuyAZabBWzRm2c6y/plxsO+S1vErn/Z/EW6MgAWnb5k/H6HpnmTfBtRg3WKjZkAGqMISRAU9g6ijYYJHCIR892wKsat72BAHSQIDAQABozEwLzAOBgNVHQ8BAf8EBAMCAgQwHQYDVR0OBBYEFFT2kGUpLWrl1fJgJvi1pk8mrT9TMA0GCSqGSIb3DQEBCwUAA4IBAQBCMGaiGsfEAvQjwfev/6p7Y/7ObP7uy+982XEqyjv334NaeKC7Bp3rPanSA/ISAdF0tJGdPTPiZnKi8PJ1Wdqs13laRUVRPnUxt1sX1TFmnp0mD2AE3ibOduE6xrB5r4v/BXWpdXbbD8nr7m1J6+EVWecdzsboV5bmTss99T5Jutv1AJjSbC1mMELRQkAnZd8eH80FvAl1JPO1vEyYe5uQRCdrHTwTzh64M1gAOMFmFQnIDNi1TDj2KwK+uhG1V7FSCfHfWVheTdhil7bIpvGrZEMfeyut/j8fnRUBhiIgj10JmmYwCTm9Ikgr+d43DGViI3jts2N50Vy9l7YCvGba'
          }
        }
      ] 
    }
  }
}
//LNG
resource csrlng 'Microsoft.Network/localNetworkGateways@2021-03-01' = {
  name: 'csrlng'
  location: location
  properties:{
    gatewayIpAddress:InsidePrivateIP
    localNetworkAddressSpace:{
      addressPrefixes:[
        '0.0.0.0/1'
        '128.0.0.0/1'
      ]
    }
  }
}
//Connection from GW to CSR
resource gwcsr 'Microsoft.Network/connections@2021-03-01' ={
  name:'gwcsr'
  location:location
  properties:{
    virtualNetworkGateway1:{
      properties:{}
      id: VPNGW.id
    }
    localNetworkGateway2:{
      properties:{}
      id:csrlng.id
    }
    connectionType: 'IPsec'
    sharedKey:tunnelKey
    useLocalAzureIpAddress:true
  }
}


//NSG
resource csrnsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'csrnsg'
  location: location
  properties:{
    securityRules: [
      {
        name: 'internet-in-from-vnet'
        properties:{
          priority: 110
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
         }
        }
        {
         name: 'allowSSHin'
         properties:{
         priority: 120
         direction: 'Inbound'
         protocol: 'Tcp'
         access: 'Allow'
         sourceAddressPrefix: '217.122.185.32'
         sourcePortRange: '*'
         destinationAddressPrefix: '*'
         destinationPortRange: '22'
         }
      }
    ]
  }
}
//UDR
resource CsrRT 'Microsoft.Network/routeTables@2021-03-01' = {
  name: 'CsrRT'
  location: location
  properties: {
    disableBgpRoutePropagation:true
    routes:[]
  }
}
//Storage account for boot diagnostics
resource bootst 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${storagePrefix}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  resource blob 'blobServices@2021-04-01' = {
    name: 'default'
  }
}
//CSR
resource insideNic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: 'insideNic'
  location: location
  dependsOn:[
    VpnVNET
  ]
  properties:{
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets','VpnVNET','InsideSubnet')
          }
          privateIPAddress: InsidePrivateIP          
        }
      }
    ]
  }
}
resource outsideNic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: 'outsideNic'
  location: location
  dependsOn: [
    VpnVNET
    csrPubIpV4
  ]
  properties:{
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets','VpnVNET','OutsideSubnet')
          }
          privateIPAddress: OutsidePrivateIP 
          publicIPAddress: {
            id: csrPubIpV4.id
          }
        }
      }
    ]
  }
}
resource csr 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'csr'
  location: location
  plan:{
    name: '16_12_5-byol'
    publisher: 'cisco'
    product: 'cisco-csr-1000v'
  }
  properties: {
    hardwareProfile:{
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile:  {
      imageReference: {
        publisher: 'cisco'
        offer: 'cisco-csr-1000v'
        sku: '16_12_5-byol'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'      
        }
      }
      osProfile:{
        computerName: 'csr'
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: {
          patchSettings: {
            patchMode: 'ImageDefault'
          }
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: bootst.properties.primaryEndpoints.blob
        }
      }
      networkProfile: {
        networkInterfaces: [
        {
          id: insideNic.id
          properties:{
            primary:true
          }
        }
        {
          id: outsideNic.id
          properties:{
            primary:false
          }
        }
      ]
    }
  }
}



