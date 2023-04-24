@description('Enter the vm username')
param vmUserName string

@description('VM user password')
@secure()
param vmPass string

@description('the base name for the deployment')
@maxLength(13)
param baseName string

@description('The Azure Region')
param location string

@description('The VM SKU. Only allowing 1 SKU')
@allowed([
    'standard_b2s'
    'standard_b1s'
])
param vmSize string = 'standard_b2s'

@description('The IP space for the virtual network in CIDR notation')
param vnetIpRange string 


@description('The IP space for the subnet in CIDR notation')
param subnetIpRange string 

var image = {
  windows: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
}
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'vm${baseName}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'vm${baseName}'
      adminUsername: vmUserName
      adminPassword: vmPass
    }
    storageProfile: {
      imageReference: {
        publisher: image.windows.publisher
        offer: image.windows.offer
        sku: image.windows.sku
        version: image.windows.version
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'nic${baseName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet${baseName}', 'subnet${baseName}')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', 'nsg${baseName}')
    }
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'ip${baseName}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg${baseName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 300
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet${baseName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
       vnetIpRange 
      ]
    }
    subnets: [
      {
        name: 'subnet${baseName}'
        properties: {
          addressPrefix: subnetIpRange
        }
      }
    ]
  }
}
