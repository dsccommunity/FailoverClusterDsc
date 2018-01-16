# xFailOverCluster

The **xFailOverCluster** module contains DSC resources for deployment and
configuration of Failover Clustering.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/6a59vfritv4kbc7d/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xfailovercluster/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/master)

This is the branch containing the latest release - no contributions should be
made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/6a59vfritv4kbc7d/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xfailovercluster/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/dev)

This is the development branch to which contributions should be proposed by
contributors as pull requests. This development branch will periodically be
merged to the master branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**xCluster**](#xcluster) Ensures that a group of machines form a cluster.
* [**xClusterDisk**](#xclusterdisk) Configures shared disks in a cluster.
* [**xClusterNetwork**](#xclusternetwork) Configures as cluster network in a failover
  cluster.
* [**xClusterPreferredOwner**](#xclusterpreferredowner) Configures preferred
  owner of a cluster group in a cluster.
* [**xClusterProperty**](#xclusterproperty) Configures cluster properties on a
  failover cluster.
* [**xClusterQuorum**](#xclusterquorum) Configures quorum in a cluster.
* [**xWaitForCluster**](#xwaitforcluster) Ensures that a node waits for a remote
  cluster is created.

### xCluster

Used to configure a failover cluster. If the cluster does not exist, it will be
created in the domain and the static IP address will be assigned to the cluster.
When the cluster exist (either it was created or already existed), it will add
the target node ($env:COMPUTERNAME) to the cluster.

#### Requirements for xCluster

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xCluster

* **`[String]` Name** _(Key)_: Name of the failover cluster.
* **`[String]` StaticIPAddress** _(Write)_: The static IP address of the failover
  cluster. If this is not specified then the IP address will be assigned from a
  DHCP.
* **`[String[]]` IgnoreNetwork** _(Write)_: One or more networks to ignore when
  creating the cluster. Only networks using Static IP can be ignored, networks
  that are assigned an IP address through DHCP cannot be ignored, and are added
  for cluster communication. To remove networks assigned an IP address through DHCP
  use the resource xClusterNetwork to change the role of the network. This parameter
  is only used during the creation of the cluster and is not monitored after.
* **`[String]` DomainAdministratorCredential** _(Required)_: Credential used to
  create the failover cluster in Active Directory.

#### Examples for xCluster

* [Create first node of a failover cluster](/Examples/Resources/xCluster/1-CreateFirstNodeOfAFailoverCluster.ps1)
* [Join additional node to a failover cluster](/Examples/Resources/xCluster/2-JoinAdditionalNodeToFailoverCluster.ps1)
* [Create failover cluster with two nodes](/Examples/Resources/xCluster/3-CreateFailoverClusterWithTwoNodes.ps1)
* [Create first node of a failover cluster with DHCP](/Examples/Resources/xCluster/4-CreateFirstNodeOfAFailoverClusterWithDHCP.ps1)
* [Join additional node to a failover cluster with DHCP](/Examples/Resources/xCluster/5-JoinAdditionalNodeToFailoverClusterWithDHCP.ps1)
* [Create failover cluster and ignoring a network](/Examples/Resources/xCluster/4-CreateFailoverClusterAndIgnoreANetwork.ps1)

### xClusterDisk

Configures shared disks in a cluster.

#### Requirements for xClusterDisk

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xClusterDisk

* **`[String]` Number** _(Key)_: The disk number of the cluster disk.
* **`[String]` Ensure** _(Write)_: Define if the cluster disk should be added
  (Present) or removed (Absent). Default value is 'Present'.
  { *Present* | Absent }
* **`[String]` Label** _(Write)_: The disk label that should be assigned to the
  disk on the Failover Cluster disk resource.

#### Examples for xClusterDisk

* [Add a cluster disk to the failover cluster](/Examples/Resources/xClusterDisk/1-AddClusterDisk.ps1)
* [Remove a cluster disk from the failover cluster](/Examples/Resources/xClusterDisk/2-RemoveClusterDisk.ps1)

### xClusterNetwork

Configures a cluster network in a failover cluster.

This resource is only able to change properties on cluster networks.  To add or remove networks from the cluster, add or remove them from the cluster members.  By adding a new subnet on one of the cluster nodes, the network will be added to the cluster, and metadata can be set using the xClusterNetwork module.

#### Requirements for xClusterNetwork

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xClusterNetwork

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

#### Examples for xClusterNetwork

* [Change properties of two cluster network resources in the failover cluster](/Examples/Resources/xClusterNetwork/1-ChangeClusterNetwork.ps1)

### xClusterPreferredOwner

Configures preferred owners of a cluster group and cluster resources in a failover
cluster.

#### Requirements for xClusterPreferredOwner

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xClusterPreferredOwner

* **`[String]` ClusterGroup** _(Key)_: Name of the cluster group.
* **`[String]` ClusterName** _(Key)_: Name of the cluster.
* **`[String[]]` Nodes** _(Required)_: The nodes to set as owners.
* **`[String[]]` ClusterResources** _(Write)_: The resources to set preferred
  owners on.
* **`[String]` Ensure** _(Write)_: If the preferred owners should be present or
  absent. Default value is 'Present'. { *Present* | Absent }

#### Examples for xClusterPreferredOwner

* [Add preferred owners to a cluster group and cluster resources](/Examples/Resources/xClusterDisk/1-AddPreferredOwner.ps1)
* [Remove preferred owners from a cluster group and cluster resources](/Examples/Resources/xClusterDisk/2-RemovePreferredOwner.ps1)

### xClusterProperty

Configures properties of a failover cluster.

#### Requirements for xClusterProperty

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xClusterProperty

* **`[String]` Name** _(Key)_: Name of the cluster.
* **`[Uint32]` AddEvictDelay** _(Write)_: Specifies how many seconds after a
  node is evicted that the failover cluster service will wait before adding a
  new node.
* **`[Uint32]` ClusterLogLevel** _(Write)_: Controls the level of cluster
  logging.
* **`[Uint32]` ClusterLogSize** _(Write)_: Controls the maximum size of the
  cluster log files on each of the nodes.
* **`[Uint32]` CrossSiteDelay** _(Write)_: Controls the time interval, in
  milliseconds, that the cluster network driver waits between sending Cluster
  Service heartbeats across sites.
* **`[Uint32]` CrossSiteThreshold** _(Write)_: Controls how many Cluster
  Service heartbeats can be missed across sites before it determines that
  Cluster Service has stopped responding.
* **`[Uint32]` CrossSubnetDelay** _(Write)_: Controls the time interval, in
  milliseconds, that the cluster network driver waits between sending Cluster
  Service heartbeats across subnets.
* **`[Uint32]` CrossSubnetThreshold** _(Write)_: Controls how many Cluster
  Service heartbeats can be missed across subnets before it determines that
  Cluster Service has stopped responding.
* **`[Uint32]` DatabaseReadWriteMode** _(Write)_: Specifies the read/write mode
  for the cluster database.
* **`[Uint32]` DefaultNetworkRole** _(Write)_: Specifies the role that the
  cluster automatically assigns to any newly discovered or created network.
* **`[String]` Description** _(Write)_: Stores administrative comments about
  the cluster. The following table summarizes the attributes of the Description
  property.
* **`[Uint32]` DrainOnShutdown** _(Write)_: Specifies whether to enable Node
  Drain for a cluster.
* **`[Uint32]` DynamicQuorum** _(Write)_: Enables the cluster to change the
  required number of nodes that need to participate in quorum when nodes shut
  down or crash.
* **`[Uint32]` NetftIPSecEnabled** _(Write)_: Specifies whether Internet
  Protocol Security (IPSec) encryption is enabled for inter-node cluster
  communication.
* **`[String]` PreferredSite** _(Write)_: Specifies the preferred site for a
  site-aware cluster.
* **`[Uint32]` QuarantineDuration** _(Write)_: Specifies the quarantine
  duration for a node, in seconds.
* **`[Uint32]` QuarantineThreshold** _(Write)_: Specifies the quarantine
  threshold for a node, in minutes.
* **`[Uint32]` SameSubnetDelay** _(Write)_: Controls the delay, in milliseconds,
  between netft heartbeats.
* **`[Uint32]` SameSubnetThreshold** _(Write)_: Controls how many heartbeats can
  be missed on the same subnet before the route is declared as unreachable.
* **`[Uint32]` ShutdownTimeoutInMinutes** _(Write)_: Specifies how many minutes
  after a system shutdown is initiated that the failover cluster service will
  wait for resources to go offline.

#### Examples for xClusterProperty

* [Set failover cluster properties](/Examples/Resources/xClusterProperty/1-SetClusterProperties.ps1)

### xClusterQuorum

Configures quorum in a cluster. For information on how to choose the correct
quorum type, please see the article
[Understanding Quorum Configurations in a Failover Cluster](https://technet.microsoft.com/en-us/library/cc731739(v=ws.11).aspx).

#### Requirements for xClusterQuorum

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xClusterQuorum

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

#### Examples for xClusterQuorum

* [Set quorum to node majority](/Examples/Resources/xClusterQuorum/1-SetQuorumToNodeMajority.ps1)
* [Set quorum to node and disk majority](/Examples/Resources/xClusterQuorum/2-SetQuorumToNodeAndDiskMajority.ps1)
* [Set quorum to node and file share majority](/Examples/Resources/xClusterQuorum/3-SetQuorumToNodeAndFileShareMajority.ps1)
* [Set quorum to disk only](/Examples/Resources/xClusterQuorum/4-SetQuorumToDiskOnly.ps1)
* [Set quorum to node and cloud](/Examples/Resources/xClusterQuorum/5-SetQuorumToNodeAndCloudMajority.1)

### xWaitForCluster

Ensures that a node waits for a remote cluster is created.

#### Requirements for xWaitForCluster

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters for xWaitForCluster

* **`[String]` Name** _(Key)_: Name of the cluster to wait for.
* **`[UInt64]` RetryIntervalSec** _(Write)_: Interval to check for cluster
  existence. Default values is 10 seconds.
* **`[UInt32]` RetryCount** _(Write)_: Maximum number of retries to check for
  cluster existence. Default value is 50 retries.

#### Examples for xWaitForCluster

* [Wait for failover cluster to be present](/Examples/Resources/xWaitForCluster/1-WaitForFailoverClusterToBePresent.ps1)
