# Azure Verified Modules - Network Deployment in Bicep

[Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) is an effort to create a library of  modules in multiple Infastructure as Code (IaC) languages, following the principles of the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/). 

The purpose of this lab is to try, gain experience with and demonstrate the use of AVM modules. Use it as a starting point for further experimentation. 

This is not a reference implementation and it should not be used to as the basis for any production environment.

## Lab 

The lab is comprised of:
- A server VNET and a client VNET
- A pair of load balanced Windows Server VMs running a basic web server, in the server VNET
- A Windows 11 client VM in the client VNET
- Azure Bastion in the client VNET
- A Storage Account, with a Private Endpoint in the server VNET and accompanying Private DNS Zone
- VNET Gateways in both VNETs, with a VPN tunnel between them

The point of the lab is not so much in the resources and their functionality, which is straight forward, but in that all of it is deployed using Bicep Azure Verified Modules. The lab's main.bicep file only references AVM modules, it does not contain direct resource deployements or reference custom or local modules.


![images](/azure_verified_module_lab.png)

## Deploy

Log in to Azure Cloud Shell at https://shell.azure.com/ and select Bash.

Ensure Azure CLI and extensions are up to date:
  
      az upgrade --yes
  
If necessary select your target subscription:
  
      az account set --subscription <Name or ID of subscription>

Clone the  GitHub repository: 
      git clone https://github.com/mddazure/azure_verified_module_lab

Change directory:
  
      cd ./azure_verified_module_lab

Deploy the Bicep template:

      az deployment sub create --location swedencentral --template-file main.bicep

Verify that all components in the diagram above have been deployed to the resourcegroup `avm-rg` and are healthy. 