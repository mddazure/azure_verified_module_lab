param location string = 'swedencentral'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-Datacenter'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg'
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

module vnetgw 'br/public:avm/res/network/virtual-network-gateway:0.1.3' = {
  scope: rg
  name: 'vnetgw'
  params: {
    gatewayType:  'Vpn'
    name: 'vnetgw'
    skuName: 'VpnGw1AZ'
    vNetResourceId: virtualNetwork.outputs.resourceId
  }
}

module vm 'br/public:avm/res/compute/virtual-machine:0.5.1' = {
  scope: rg
  name: 'vm1'
  params: {
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
  }
}
