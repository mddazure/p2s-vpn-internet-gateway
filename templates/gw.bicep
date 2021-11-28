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
            publicCertData: 'MIIC5zCCAc+gAwIBAgIQZztZYHmjtL5NxRSFqeFj8TANBgkqhkiG9w0BAQsFADAW MRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMTA0MDMxMzEzNDhaFw0yMjA0MDMx MzMzNDhaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEF AAOCAQ8AMIIBCgKCAQEAsrCNfBxfFd3zwEwkUsiQI++7vawcjlgGlRSWxgETkwxW HN/PMz9yZy6mPe2+3x+/fuqOVUCt0tKi0KjBT5LsMKEGby23m6RbRJ9FV8Hvkx2T Y7q0e+6jFRDbNB+Vosx7ta+Rx/IytJ8GEJTq0KHht36XivgtO/HnsLYS0wcUidD9 yo4aYzTGiq6x/Ir9Xn9mkJYnb6t8MDpN9HU22XX9YbINo/WDt8pVKF7oILkeJ81U JbpRHGEaEKrdvp0fA0zqyE/IErUzKK8wdJp8XQeOChwWAkJYLk41iN5xKIyNB/Qk SjeZwerP7ZlsEoYc604q16ms4UYktKqzISn+M2RhxQIDAQABozEwLzAOBgNVHQ8B Af8EBAMCAgQwHQYDVR0OBBYEFIzIo1ejScaSuToAEVq7WertaUfqMA0GCSqGSIb3 DQEBCwUAA4IBAQCyF/PaJGECjqzuIpAUkOpHkogkM8zLapOThwkpT7VXnO0EL0G+ 6FDimGJjMN3oo9bzwdBEMzz+1fIIg+OfTGwERvq3wqybc/81HqMnvFb+nR1hTFT8 yh025HJMlT06VZ0dhgIRpGor0exWomeZINdUvkKWTUchIam813hM7LEHhvWXVk// 7hrOjeD8k+KbGaujOEY4+jLUhvXnXrlzZTRNrA3glQuhm7Gf5zllKDeqIGmn3LG6 OZ9OsDSB9zkP6a5bOP6HaqE7i4TQxlidE7+LiY8YN5VLorHUTER4xivUDUoLAOOe +NC0ov+7QApAibH5AKgoN4SGt5wF9ZtcpdkK'
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
          publicIPAddress: csrPubIpV4         
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



