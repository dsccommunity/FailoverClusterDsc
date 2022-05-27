# Localized resources for xCluster

ConvertFrom-StringData @'
    CombinedIPAndAddressMask = Combined IP address and subnet mask were passed as {0}.
    SplitIPandAddressMask = IP address and subnet mask split as {0} and {1}.
    GetClusterNetworks = Getting all networks added to this cluster.
    FoundClusterNetwork = Found cluster network {0}/{1}.
    GetSubnetfromIPAddressandAddressMask = Getting the subnet of the given IPAddress {0} with subnet mask {1}
    FoundSubnetfromIPAddressandAddressMask = IP address {0} with subnet mask {1} is in subnet {2}.
    NetworkAlreadyInCluster = Subnet {0} for IPAddress {1} network {2} is added to the cluster
    GetClusterResourceExpression =  Getting Cluster DependencyExpression.
    TestDependencyExpression = Testing if {0} is in DependencyExpression {1}.
    SuccessfulTestDependencyExpression = {0} is in DependencyExpression {1}.
    FailedTestDependencyExpression = {0} is not in DependencyExpression {1}.
    RemoveIPAddressResource = Removing IP address {0} with address mask {1} to the cluster parameters
    AddIPAddressResource = Adding IP address {0} with address mask {1} to the cluster parameters
    NonExistantClusterNetwork =  Cluster Network for IP address {0} and address mask {1} is not part of this cluster"
'@
