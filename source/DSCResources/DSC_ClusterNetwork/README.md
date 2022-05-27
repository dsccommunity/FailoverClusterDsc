# Description

Configures a cluster network in a failover cluster.

This resource is only able to change properties on cluster networks.
To add or remove networks from the cluster, add or remove them from
the cluster members. By adding a new subnet on one of the cluster
nodes, the network will be added to the cluster, and metadata can be
set using the ClusterNetwork module.

## Requirements

* Target machine must be running Windows Server 2008 R2 or later.

## Parameters

### Role

This parameter sets the role of the cluster network. If the cluster network role
is not in desired state it will change to match this role.

The cluster network role can be set to either the value 0, 1 or 3.

0 = Do not allow cluster network communication
1 = Allow cluster network communication only
3 = Allow cluster network communication and client connectivity

See this article for more information about cluster network role values;
[Configuring Windows Failover Cluster Networks](https://blogs.technet.microsoft.com/askcore/2014/02/19/configuring-windows-failover-cluster-networks/)
