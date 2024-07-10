param location string = 'swedencentral'
param rgname string = 'avm-rg'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'
var clientimagePublisher = 'microsoftwindowsdesktop'
var clientimageOffer = 'windows-11'
var clientimageSku = 'win11-22h2-pro'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgname
  location: location
}

module servervnet 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'servervnet'
  scope: rg
  dependsOn:[
    servernsg
  ]
    params: {
    name: 'servervnet'
    addressPrefixes: [
      '10.0.0.0/16' 
      'abcd:de12:3456::/48'
    ]
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: 'vmsubnet0'
        networkSecurityGroupResourceId: servernsg.outputs.resourceId
      }
      {
        addressPrefix: '10.0.1.0/24'
        name: 'vmsubnet1'
        networkSecurityGroupResourceId: servernsg.outputs.resourceId
      }
      {
        addressPrefix: '10.0.2.0/24'
        name: 'pesubnet'
      }       
      {
        addressPrefix: '10.0.255.0/24'
        name: 'GatewaySubnet'
      }
    ]
  }
}

module clientvnet 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'clientvnet'
  scope: rg
  dependsOn:[
    clientnsg
  ]
  params: {
    name: 'clientvnet'
    addressPrefixes: [
      '172.16.0.0/16' 
      'abcd:de12:7890::/48'
    ]
    subnets: [
      {
        addressPrefix: '172.16.0.0/24'
        name: 'vmsubnet0'
        networkSecurityGroupResourceId: clientnsg.outputs.resourceId
      }
      {
        addressPrefix: '172.16.254.0/24'
        name: 'AzureBastionSubnet'
      }
      {
        addressPrefix: '172.16.255.0/24'
        name: 'GatewaySubnet'
      }
    ]
  }
}
module servernsg 'br/public:avm/res/network/network-security-group:0.3.0' = {
  scope: rg
  name: 'servernsg'
  params: {
    name: 'servernsg'
    securityRules: [
      {
      name: 'AllowHTTPInbound'
      properties: {
        access: 'Allow'
        description: 'Allow HTTP inbound traffic'
        destinationAddressPrefix: '*'
        destinationPortRange: '80'
        direction: 'Inbound'
        priority: 100
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        }
      }
      {
        name: 'AllowRDPInbound'
        properties: {
          access: 'Allow'
          description: 'Allow RDP inbound traffic'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          direction: 'Inbound'
          priority: 150
          protocol: 'Tcp'
          sourceAddressPrefix: '172.16.254.0/24'
          sourcePortRange: '*'
          }
        }
    ]
    }
}

module clientnsg 'br/public:avm/res/network/network-security-group:0.3.0' = {
  scope: rg
  name: 'clientnsg'
  params: {
    name: 'clientnsg'
    securityRules: [
      {
      name: 'AllowRDPInbound'
      properties: {
        access: 'Allow'
        description: 'Allow RDP inbound traffic'
        destinationAddressPrefix: '*'
        destinationPortRange: '3389'
        direction: 'Inbound'
        priority: 100
        protocol: 'Tcp'
        sourceAddressPrefix: '172.16.254.0/24'
        sourcePortRange: '*'
        }
      }
    ]
    }
}
module servervnetgw 'br/public:avm/res/network/virtual-network-gateway:0.1.3' = {
  scope: rg
  name: 'servervnetgw'
  params: {
    publicIpZones: [1,2,3]
    gatewayType:  'Vpn'
    name: 'servervnetgw'
    skuName: 'VpnGw1AZ'
    vNetResourceId: servervnet.outputs.resourceId
  }
}

module clientvnetgw 'br/public:avm/res/network/virtual-network-gateway:0.1.3' = {
  scope: rg
  name: 'clientvnetgw'
  params: {
    publicIpZones: [1,2,3]
    gatewayType:  'Vpn'
    name: 'clientvnetgw'
    skuName: 'VpnGw1AZ'
    vNetResourceId: clientvnet.outputs.resourceId
  }
}
module serverclientconn 'br/public:avm/res/network/connection:0.1.2' = {
  scope: rg
  name: 'serverclientconn'
  params: {
    connectionType: 'Vnet2Vnet'
    name: 'serverclientconn'
    virtualNetworkGateway1: {
      id: servervnetgw.outputs.resourceId
    }
    virtualNetworkGateway2: {
      id: clientvnetgw.outputs.resourceId
    }
    vpnSharedKey: 'AzureA1b'
  }
}
module clientserverconn 'br/public:avm/res/network/connection:0.1.2' = {
  scope: rg
  name: 'clientserverconn'
  params: {
    connectionType: 'Vnet2Vnet'
    name: 'clientserverconn'
    virtualNetworkGateway2: {
      id: servervnetgw.outputs.resourceId
    }
    virtualNetworkGateway1: {
      id: clientvnetgw.outputs.resourceId
    }
    vpnSharedKey: 'AzureA1b'
  }
}
module vm1 'br/public:avm/res/compute/virtual-machine:0.5.1' = {
  scope: rg
  name: 'vm1'
  params: {
    encryptionAtHost: false
    adminUsername: 'marc'
    adminPassword: 'Nienke040598'
    imageReference: {
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSku
      version: 'latest'
    }
    name: 'vm1'
    nicConfigurations: [
      {
        ipconfigurations: [
          {
          name: 'ipconfig1'
          subnetresourceid: '${servervnet.outputs.resourceId}/subnets/vmsubnet0'
          loadBalancerBackendAddressPools:[
            {
              id: lb.outputs.backendpools[0].id
            }

          ]
          }
        ]
        nicSuffix: '-nic-01'
      }
      {
        ipconfigurations: [
          {
          name: 'ipconfig2'
          subnetresourceid: '${servervnet.outputs.resourceId}/subnets/vmsubnet1'
          
          }
        ]
        nicSuffix: '-nic-02'
      }
    ]
      
    
    osDisk: {
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v2'
    zone: 1
    extensionCustomScriptConfig: {
      enabled: true
      fileData: []
    }
    extensionCustomScriptProtectedSetting: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)'
    }
  }
}
module vm2 'br/public:avm/res/compute/virtual-machine:0.5.1' = {
  scope: rg
  name: 'vm2'
  params: {
    encryptionAtHost: false
    adminUsername: 'marc'
    adminPassword: 'Nienke040598'
    imageReference: {
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSku
      version: 'latest'
    }
    name: 'vm2'
    nicConfigurations: [
      {
        ipconfigurations: [
          {
          name: 'ipconfig1'
          subnetresourceid: '${servervnet.outputs.resourceId}/subnets/vmsubnet0'
          loadBalancerBackendAddressPools:[
            {
              id: lb.outputs.backendpools[0].id
            }
          ]
          }
        ]
        nicSuffix: '-nic-01'
      }
      {
        ipconfigurations: [
          {
          name: 'ipconfig2'
          subnetresourceid: '${servervnet.outputs.resourceId}/subnets/vmsubnet1'
          }
        ]
        nicSuffix: '-nic-02'
      }
    ]
      
    
    osDisk: {
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v2'
    zone: 1
    extensionCustomScriptConfig: {
      enabled: true
      fileData:[]
    }
    extensionCustomScriptProtectedSetting: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)' 
    }   
  }
}

module clientvm 'br/public:avm/res/compute/virtual-machine:0.5.1' = {
  scope: rg
  name: 'clientvm'
  params: {
    encryptionAtHost: false
    adminUsername: 'marc'
    adminPassword: 'Nienke040598'
    imageReference: {
      publisher: clientimagePublisher
      offer: clientimageOffer
      sku: clientimageSku
      version: 'latest'
    }
    name: 'clientvm'
    nicConfigurations: [
      {
        ipconfigurations: [
          {
          name: 'ipconfig1'
          subnetresourceid: clientvnet.outputs.subnetResourceIds[0]
          publicIpAddressId: clientpipv4.outputs.resourceId
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
      
    
    osDisk: {
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v2'
    zone: 1  
  }
}
module bastion 'br/public:avm/res/network/bastion-host:0.2.1' = {
  scope: rg
  name: 'bastion'
  params: {
    name: 'bastion'
    virtualNetworkResourceId: clientvnet.outputs.resourceId
    skuName: 'Standard'
    enableIpConnect: true
    enableShareableLink: true
  }
}

module prefixv4 'br/public:avm/res/network/public-ip-prefix:0.3.0' = {
  scope: rg
  name: 'prefixv4'
  params: {
    name: 'prefixv4'
    prefixLength: 30
  }
}

module lbfepv4 'br/public:avm/res/network/public-ip-address:0.4.1' = {
  scope: rg
  name: 'lbfepv4'
  params: {
    name: 'lbfepv4'
    publicIPAddressVersion: 'IPv4'
    publicIpPrefixResourceId: prefixv4.outputs.resourceId
    skuName: 'Standard'
    skuTier: 'Regional'
  }
}

module lbfepv6 'br/public:avm/res/network/public-ip-address:0.4.1' = {
  scope: rg
  name: 'lbfepv6'
  params: {
    name: 'lbfepv6'
    publicIPAddressVersion: 'IPv6'
    skuName: 'Standard'
    skuTier: 'Regional'
  }
}

module clientpipv4 'br/public:avm/res/network/public-ip-address:0.4.1' = {
  scope: rg
  name: 'clientpipv4'
  params: {
    name: 'clientpipv4'
    publicIPAddressVersion: 'IPv4'
    publicIpPrefixResourceId: prefixv4.outputs.resourceId
    skuName: 'Standard'
    skuTier: 'Regional'
  }
}

module lb 'br/public:avm/res/network/load-balancer:0.2.0' = {
  scope: rg
  name: 'lb'
  params: {
    name: 'lb'
    frontendIPConfigurations: [
      {
        name: 'publicipconfigv4'
        publicIPAddressId: lbfepv4.outputs.resourceId
      }
      {
        name: 'publicipconfigv6'
        publicIPAddressId: lbfepv6.outputs.resourceId
      }
    ]
    backendAddressPools: [
      {
        name: 'bep1'
        loadbalancerBackendAddresses: [
        ]
      }
    ]
    probes: [
      {
        intervalInSeconds: 10
        family: 'IPv4'
        name: 'probev4'
        numberOfProbes: 5
        port: 80
        protocol: 'Http'
        requestPath: '/'
      }
    ]
    loadBalancingRules: [
      {
        backendAddressPoolName: 'bep1'
        backendPort: 80
        disableOutboundSnat: true
        enableFloatingIP: false
        enableTcpReset: false
        frontendIPConfigurationName: 'publicipconfigv4'
        frontendPort: 80
        idleTimeoutInMinutes: 5
        loadDistribution: 'Default'
        name: 'publicIPLBRulev4'
        probeName: 'probev4'
        protocol: 'Tcp'
      }
    ]
  }
}
module storageaccount 'br/public:avm/res/storage/storage-account:0.9.1' = {
  scope: rg
  name: 'storageaccount'
  params: {
    name: 'avm${uniqueString(rg.id)}'
    kind: 'StorageV2'
    location: location
    skuName: 'Standard_LRS'
    privateEndpoints:[
      {
        name: 'privateEndpoint1'
        privateDnsZoneResourceIds: [
          privateDNSZone.outputs.resourceId
        ]
        service: 'blob'
        subnetResourceId: '${servervnet.outputs.resourceId}/subnets/pesubnet' 
      }
    ]
  }
}
module privateDNSZone 'br/public:avm/res/network/private-dns-zone:0.3.1' = {
  scope: rg
  name: 'privateDNSZone'
  params: {
    name: 'privatelink.blob.core.windows.net'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: servervnet.outputs.resourceId
      }
      {
        virtualNetworkResourceId: clientvnet.outputs.resourceId
      }
    ]
  }
}
