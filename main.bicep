



module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'vnet'
  
  params: {
    name: 'vnet'
    addressPrefixes: [
      '10.0.0.0/24'
    ] 
  }
}
