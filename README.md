# FailOverClusterDsc

[![Build Status](https://dev.azure.com/dsccommunity/FailOverClusterDsc/_apis/build/status/dsccommunity.FailOverClusterDsc?branchName=main)](https://dev.azure.com/dsccommunity/FailOverClusterDsc/_build/latest?definitionId=5&branchName=main)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/FailOverClusterDsc/5/main)
[![codecov](https://codecov.io/gh/dsccommunity/FailOverClusterDsc/branch/main/graph/badge.svg)](https://codecov.io/gh/dsccommunity/FailOverClusterDsc)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/FailOverClusterDsc/5/main)](https://dsccommunity.visualstudio.com/FailOverClusterDsc/_test/analytics?definitionId=5&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/FailOverClusterDsc?label=FailOverClusterDsc%20Preview)](https://www.powershellgallery.com/packages/FailOverClusterDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/FailOverClusterDsc?label=FailOverClusterDsc)](https://www.powershellgallery.com/packages/FailOverClusterDsc/)

This module contains DSC resources for deployment and configuration of
Windows Server Failover Cluster

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**Cluster**](#cluster) Ensures that a group of machines form a cluster.
* [**ClusterDisk**](#clusterdisk) Configures shared disks in a cluster.
* [**ClusterNetwork**](#clusternetwork) Configures as cluster network in a failover
  cluster.
* [**ClusterPreferredOwner**](#clusterpreferredowner) Configures preferred
  owner of a cluster group in a cluster.
* [**ClusterProperty**](#clusterproperty) Configures cluster properties on a
  failover cluster.
* [**ClusterQuorum**](#clusterquorum) Configures quorum in a cluster.
* [**WaitForCluster**](#waitforcluster) Ensures that a node waits for a remote
  cluster is created.

### Cluster

Used to configure a failover cluster. If the cluster does not exist, it will be
created in the domain and the static IP address will be assigned to the cluster.
When the cluster exist (either it was created or already existed), it will add
the target node ($env:COMPUTERNAME) to the cluster.

#### Requirements for Cluster

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for Cluster

* **`[String]` Name** _(Key)_: Name of the failover cluster.
* **`[String]` StaticIPAddress** _(Write)_: The static IP address of the failover
  cluster. If this is not specified then the IP address will be assigned from a
  DHCP.
* **`[String[]]` IgnoreNetwork** _(Write)_: One or more networks to ignore when
  creating the cluster. Only networks using Static IP can be ignored, networks
  that are assigned an IP address through DHCP cannot be ignored, and are added
  for cluster communication. To remove networks assigned an IP address through DHCP
  use the resource ClusterNetwork to change the role of the network. This parameter
  is only used during the creation of the cluster and is not monitored after.
* **`[PSCredential]` DomainAdministratorCredential** _(Write)_: Credential used to
  create the failover cluster in Active Directory. If this is not specified then 
  the cluster computer object must have been prestaged as per the
  [documentation](https://docs.microsoft.com/en-us/windows-server/failover-clustering/prestage-cluster-adds).
    * If `PsDscRunAsCredential` is used, then that account must have been granted 
    Full Control over the Cluster Name Object in Active Directory.
    * Otherwise the Computer Account must have been granted Full Control 
    over the Cluster Name Object in Active Directory.


#### Examples for Cluster

* [Create first node of a failover cluster](/source/Examples/Resources/Cluster/1-Cluster_CreateFirstNodeOfAFailoverClusterConfig.ps1)
* [Join additional node to a failover cluster](/source/Examples/Resources/Cluster/2-Cluster_JoinAdditionalNodeToFailoverClusterConfig.ps1)
* [Create failover cluster with two nodes](/source/Examples/Resources/Cluster/3-Cluster_CreateFailoverClusterWithTwoNodesConfig.ps1)
* [Create first node of a failover cluster and ignoring a network subnet](/source/Examples/Resources/Cluster/4-Cluster_CreateFailoverClusterAndIgnoreANetworkConfig.ps1)
* [Create first node of a failover cluster with DHCP](/source/Examples/Resources/Cluster/5-Cluster_CreateFirstNodeOfAFailoverClusterWithDHCPConfig.ps1)
* [Join additional node to a failover cluster with DHCP](/source/Examples/Resources/Cluster/6-Cluster_JoinAdditionalNodeToFailoverClusterWithDHCPConfig.ps1)

### ClusterDisk

Configures shared disks in a cluster.

#### Requirements for ClusterDisk

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for ClusterDisk

* **`[String]` Number** _(Key)_: The disk number of the cluster disk.
* **`[String]` Ensure** _(Write)_: Define if the cluster disk should be added
  (Present) or removed (Absent). Default value is 'Present'.
  { *Present* | Absent }
* **`[String]` Label** _(Write)_: The disk label that should be assigned to the
  disk on the Failover Cluster disk resource.

#### Examples for ClusterDisk

* [Add a cluster disk to the failover cluster](/source/Examples/Resources/ClusterDisk/1-ClusterDisk_AddClusterDiskConfig.ps1)
* [Remove a cluster disk from the failover cluster](/source/Examples/Resources/ClusterDisk/2-ClusterDisk_RemoveClusterDiskConfig.ps1)

### ClusterNetwork

Configures a cluster network in a failover cluster.

This resource is only able to change properties on cluster networks.  To add or remove networks from the cluster, add or remove them from the cluster members.  By adding a new subnet on one of the cluster nodes, the network will be added to the cluster, and metadata can be set using the ClusterNetwork module.

#### Requirements for ClusterNetwork

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for ClusterNetwork

* **`[String]` Address** _(Key)_: The address for the cluster network in the format
  '10.0.0.0'.
* **`[String]` AddressMask** _(Key)_: The address mask for the cluster network in
  the format '255.255.255.0'.
* **`[String]` Name** _(Write)_: The name of the cluster network. If the cluster
  network name is not in desired state it will be renamed to match this name.
* **`[String]` Role** _(Write)_: The role of the cluster network. If the cluster
  network role is not in desired state it will changed to match this role.
  { 0 | 1 | 3 }.
* **`[String]` Metric** _(Write)_: The metric number for the cluster network. If
  the cluster network metric number is not in desired state it will be changed to
  match this metric number.

#### Role parameter

This parameter sets the role of the cluster network. If the cluster network role
is not in desired state it will change to match this role.

The cluster network role can be set to either the value 0, 1 or 3.

0 = Do not allow cluster network communication
1 = Allow cluster network communication only
3 = Allow cluster network communication and client connectivity

See this article for more information about cluster network role values;
[Configuring Windows Failover Cluster Networks](https://blogs.technet.microsoft.com/askcore/2014/02/19/configuring-windows-failover-cluster-networks/)

#### Examples for ClusterNetwork

* [Change properties of two cluster network resources in the failover cluster](/source/Examples/Resources/ClusterNetwork/1-ClusterNetwork_ChangeClusterNetworkConfig.ps1)

### ClusterPreferredOwner

Configures preferred owners of a cluster group and cluster resources in a failover
cluster.

#### Requirements for ClusterPreferredOwner

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for ClusterPreferredOwner

* **`[String]` ClusterGroup** _(Key)_: Name of the cluster group.
* **`[String]` ClusterName** _(Key)_: Name of the cluster.
* **`[String[]]` Nodes** _(Required)_: The nodes to set as owners.
* **`[String[]]` ClusterResources** _(Write)_: The resources to set preferred
  owners on.
* **`[String]` Ensure** _(Write)_: If the preferred owners should be present or
  absent. Default value is 'Present'. { *Present* | Absent }

#### Examples for ClusterPreferredOwner

* [Add preferred owners to a cluster group and cluster resources](/source/Examples/Resources/ClusterPreferredOwner/1-ClusterPreferredOwner_AddPreferredOwnerConfig.ps1)
* [Remove preferred owners from a cluster group and cluster resources](/source/Examples/Resources/ClusterPreferredOwner/2-ClusterPreferredOwner_RemovePreferredOwnerConfig.ps1)

### ClusterProperty

Configures cluster properties on a failover cluster.

#### Requirements for ClusterProperty

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for ClusterProperty

* **`[String]` Name** _(Key)_: Name of the cluster.
* **`[UInt32]` AddEvictDelay** _(Write)_: Specifies how many seconds after a
  node is evicted that the failover cluster service will wait before adding a
  new node.
* **`[UInt32]` BlockCacheSize** _(Write)_: Controls the size of the Cluster
  Shared Volume Memory Cache in MB.
* **`[UInt32]` ClusterLogLevel** _(Write)_: Controls the level of cluster
  logging.
* **`[UInt32]` ClusterLogSize** _(Write)_: Controls the maximum size of the
  cluster log files on each of the nodes.
* **`[UInt32]` CrossSiteDelay** _(Write)_: Controls the time interval, in
  milliseconds, that the cluster network driver waits between sending Cluster
  Service heartbeats across sites.
* **`[UInt32]` CrossSiteThreshold** _(Write)_: Controls how many Cluster
  Service heartbeats can be missed across sites before it determines that
  Cluster Service has stopped responding.
* **`[UInt32]` CrossSubnetDelay** _(Write)_: Controls the time interval, in
  milliseconds, that the cluster network driver waits between sending Cluster
  Service heartbeats across subnets.
* **`[UInt32]` CrossSubnetThreshold** _(Write)_: Controls how many Cluster
  Service heartbeats can be missed across subnets before it determines that
  Cluster Service has stopped responding.
* **`[UInt32]` DatabaseReadWriteMode** _(Write)_: Specifies the read/write mode
  for the cluster database.
* **`[UInt32]` DefaultNetworkRole** _(Write)_: Specifies the role that the
  cluster automatically assigns to any newly discovered or created network.
* **`[String]` Description** _(Write)_: Stores administrative comments about
  the cluster. The following table summarizes the attributes of the Description
  property.
* **`[UInt32]` DrainOnShutdown** _(Write)_: Specifies whether to enable Node
  Drain for a cluster.
* **`[UInt32]` DynamicQuorum** _(Write)_: Enables the cluster to change the
  required number of nodes that need to participate in quorum when nodes shut
  down or crash.
* **`[UInt32]` NetftIPSecEnabled** _(Write)_: Specifies whether Internet
  Protocol Security (IPSec) encryption is enabled for inter-node cluster
  communication.
* **`[String]` PreferredSite** _(Write)_: Specifies the preferred site for a
  site-aware cluster.
* **`[UInt32]` QuarantineDuration** _(Write)_: Specifies the quarantine
  duration for a node, in seconds.
* **`[UInt32]` QuarantineThreshold** _(Write)_: Specifies the quarantine
  threshold for a node, in minutes.
* **`[UInt32]` SameSubnetDelay** _(Write)_: Controls the delay, in milliseconds,
  between netft heartbeats.
* **`[UInt32]` SameSubnetThreshold** _(Write)_: Controls how many heartbeats can
  be missed on the same subnet before the route is declared as unreachable.
* **`[UInt32]` ShutdownTimeoutInMinutes** _(Write)_: Specifies how many minutes
  after a system shutdown is initiated that the failover cluster service will
  wait for resources to go offline.

#### Examples for ClusterProperty

* [Set failover cluster properties](/source/Examples/Resources/ClusterProperty/1-ClusterProperty_SetClusterPropertiesConfig.ps1)

### ClusterQuorum

Configures quorum in a cluster. For information on how to choose the correct
quorum type, please see the article
[Understanding Quorum Configurations in a Failover Cluster](https://technet.microsoft.com/en-us/library/cc731739(v=ws.11).aspx).

#### Requirements for ClusterQuorum

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for ClusterQuorum

* **`[String]` IsSingleInstance** _(Key)_: Specifies the resource is a single
  instance, the value must be 'Yes'.
* **`[String]` Type** _(Write)_: Quorum type to use. { NodeMajority |
  NodeAndDiskMajority | NodeAndFileShareMajority | NodeAndCloudMajority, DiskOnly }.
* **`[String]` Resource** _(Write)_: The name of the disk, file share or Azure
  storage account resource to use as witness. This parameter is optional if the
  quorum type is set to NodeMajority.
* **`[String]` StorageAccountAccessKey** _(Write)_: The access key of the Azure
  storage account to use as witness. This parameter is required if the quorum
  type is set to NodeAndCloudMajority. The key is currently not updated if the
  resource is already set.

#### Examples for ClusterQuorum

* [Set quorum to node majority](/source/Examples/Resources/ClusterQuorum/1-ClusterQuorum_SetQuorumToNodeMajorityConfig.ps1)
* [Set quorum to node and disk majority](/source/Examples/Resources/ClusterQuorum/2-ClusterQuorum_SetQuorumToNodeAndDiskMajorityConfig.ps1)
* [Set quorum to node and file share majority](/source/Examples/Resources/ClusterQuorum/3-ClusterQuorum_SetQuorumToNodeAndFileShareMajorityConfig.ps1)
* [Set quorum to disk only](/source/Examples/Resources/ClusterQuorum/4-ClusterQuorum_SetQuorumToDiskOnlyConfig.ps1)
* [Set quorum to node and cloud](/source/Examples/Resources/ClusterQuorum/5-ClusterQuorum_SetQuorumToNodeAndCloudMajorityConfig.ps1)

### WaitForCluster

Ensures that a node waits for a remote cluster is created.

#### Requirements for WaitForCluster

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for WaitForCluster

* **`[String]` Name** _(Key)_: Name of the cluster to wait for.
* **`[UInt64]` RetryIntervalSec** _(Write)_: Interval to check for cluster
  existence. Default values is 10 seconds.
* **`[UInt32]` RetryCount** _(Write)_: Maximum number of retries to check for
  cluster existence. Default value is 50 retries.

#### Examples for WaitForCluster

* [Wait for failover cluster to be present](/source/Examples/Resources/WaitForCluster/1-WaitForCluster_WaitForFailoverClusterToBePresentConfig.ps1)
