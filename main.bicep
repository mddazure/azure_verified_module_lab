param location string = 'swedencentral'
param rgname string = 'rg2'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgname
  location: location
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'vnet'
  scope: rg
  
  params: {
    name: 'vnet'
    addressPrefixes: [
      '10.0.0.0/16'
    ] 
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: 'vmsubnet0'
      }
      {
        addressPrefix: '10.0.1.0/24'
        name: 'vmsubnet1'
      }
      {
        addressPrefix: '10.0.254.0/24'
        name: 'AzureBastionSubnet'
      }
      {
        addressPrefix: '10.0.255.0/24'
        name: 'GatewaySubnet'
      }
    ]
  }
}

/*module vnetgw 'br/public:avm/res/network/virtual-network-gateway:0.1.3' = {
  scope: rg
  name: 'vnetgw'
  params: {
    publicIpZones: [1,2,3]
    gatewayType:  'Vpn'
    name: 'vnetgw'
    skuName: 'VpnGw1AZ'
    vNetResourceId: virtualNetwork.outputs.resourceId
  }
}*/

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
          subnetresourceid: virtualNetwork.outputs.subnetResourceIds[0]
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
          subnetresourceid: virtualNetwork.outputs.subnetResourceIds[1]
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
          subnetresourceid: virtualNetwork.outputs.subnetResourceIds[0]
          }
        ]
        nicSuffix: '-nic-01'
      }
      {
        ipconfigurations: [
          {
          name: 'ipconfig2'
          subnetresourceid: virtualNetwork.outputs.subnetResourceIds[1]
          loadBalancerBackendAddressPools:[
            {
              id: lb.outputs.backendpools[0].id
            }
          ]
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
    extensionCustomScriptProtectedSetting: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)' 
    }
  }
}

/*module bastion 'br/public:avm/res/network/bastion-host:0.2.1' = {
  scope: rg
  name: 'bastion'
  params: {
    name: 'bastion'
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    skuName: 'Standard'
    enableIpConnect: true
    enableShareableLink: true
  }
}*/

module prefix 'br/public:avm/res/network/public-ip-prefix:0.3.0' = {
  scope: rg
  name: 'prefix'
  params: {
    name: 'prefix'
    prefixLength: 30
  }
}

module lbfep 'br/public:avm/res/network/public-ip-address:0.4.1' = {
  scope: rg
  name: 'lbfep'
  params: {
    name: 'lbfep'
    publicIpPrefixResourceId: prefix.outputs.resourceId
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
        name: 'publicipconfig1'
        publicIPAddressId: lbfep.outputs.resourceId
      }
    ]
    backendAddressPools: [
      {
        name: 'bep1'
        loadbalancerBackendAddresses: [
        ]

      }
    ]
  }
}
