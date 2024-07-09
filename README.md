# Azure Verified Modules - Network Deployment in Bicep

[Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) is an effort to create a library of  modules in multiple Infastructure as Code (IaC) languages, following the principles of the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/). 

This lab deploys a simple web application on a pair of load balanced VMs in a VNET. There is also a Storage account with a Private Endpoint, and a client VM in a separate VNET, and a VPN connection between the VNETs. The lab is composed entirely with Azure Verified Modeules in Bicep.

The purpose of this lab is to try, gain experience with and demonstrate the use of AVM modules. Use it as a starting point for further experimentation. 

This is not a reference implementation and it should not be used to as the basis for any production environment.

![images](/azure_verified_module_lab.png)

