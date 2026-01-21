param location string = 'eastus2'

// --- 1. Definición de la RED A ---
resource vnetA 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-A'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'subnet-A'
        properties: {
          addressPrefix: '10.1.0.0/24'
          delegations: [
            {
              name: 'delegation-aci'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

// --- 2. Definición de la RED B ---
resource vnetB 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-B'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.2.0.0/16']
    }
    subnets: [
      {
        name: 'subnet-B'
        properties: {
          addressPrefix: '10.2.0.0/24'
          delegations: [
            {
              name: 'delegation-aci'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

// --- 3. Peering ---
resource peeringAtoB 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  parent: vnetA
  name: 'link-to-B'
  properties: {
    remoteVirtualNetwork: {
      id: vnetB.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
  }
}

resource peeringBtoA 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  parent: vnetB
  name: 'link-to-A'
  properties: {
    remoteVirtualNetwork: {
      id: vnetA.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
  }
}

// --- 4. Instancias de contenedor ---
resource aciA 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: 'aci-oficina-A'
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Always'
    subnetIds: [
      { id: vnetA.properties.subnets[0].id }
    ]
    ipAddress: {
      type: 'Private'
      ports: [{ port: 80, protocol: 'TCP' }]
    }
    containers: [
      {
        name: 'alpine-ping'
        properties: {
          image: 'alpine:latest'
          command: ['tail', '-f', '/dev/null']
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
  }
}

resource aciB 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: 'aci-oficina-B'
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Always'
    subnetIds: [
      { id: vnetB.properties.subnets[0].id }
    ]
    ipAddress: {
      type: 'Private'
      ports: [{ port: 80, protocol: 'TCP' }]
    }
    containers: [
      {
        name: 'alpine-ping'
        properties: {
          image: 'alpine:latest'
          command: ['tail', '-f', '/dev/null']
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
  }
}

output ipPrivadaA string = aciA.properties.ipAddress.ip
output ipPrivadaB string = aciB.properties.ipAddress.ip
