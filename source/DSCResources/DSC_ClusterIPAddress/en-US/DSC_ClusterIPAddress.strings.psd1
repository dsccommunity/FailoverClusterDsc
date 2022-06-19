# Localized resources for xCluster

ConvertFrom-StringData @'
    GetClusterNetworks = Getting all networks added to this cluster.
    FoundClusterNetwork = Found cluster network with address {0} and address mask {1}.
    GetSubnetfromIPAddressandAddressMask = Getting the subnet of the given IPAddress {0} with subnet mask {1}.
    FoundSubnetfromIPAddressandAddressMask = IP address {0} with subnet mask {1} is in subnet {2}.
    NetworkAlreadyInCluster = Subnet {0} for IPAddress {1} network {2} is added to the cluster.
    AddIPAddressResource = Adding IP address {0} with address mask {1} to the cluster parameters.
    NonExistantClusterNetwork =  Cluster Network for IP address {0} and address mask {1} is not part of this cluster".
    CreateNewIPResource = Created new IP resource with IP address {0} and owner group {1}.
    SetDependencyExpression = Set cluster resource dependency to {0}.
    GetTargetResourceMessage = Getting target resource state for IP address {0} and address mask {1}.
    SetTargetResourceMessage = Setting target resource state for IP address {0} and address mask {1} and ensure {2}.
    TestTargetResourceMessage = Testing target resource state for IP address {0} and address mask {1} and ensure {2}.
    FoundIPResource = Found IP address resource matching IP address {0}.
    FoundIPAddressResource = Found IP address resource with IP address {0}, address mask {1} in network ${2}.
    NewDependencyExpression = Created new dependency expression {0}.
'@
