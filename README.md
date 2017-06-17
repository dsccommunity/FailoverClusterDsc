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
[![codecov](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/master>)

This is the branch containing the latest release - no contributions should be
made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/6a59vfritv4kbc7d/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xfailovercluster/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xFailOverCluster/branch/dev>)

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
* [**xClusterPreferredOwner**](#xclusterpreferredowner) Configures preferred
owner of a cluster group in a cluster.
* [**xClusterQuorum**](#xclusterquorum) Configures quorum in a cluster.
* [**xWaitForCluster**](#xwaitforcluster) Ensures that a node waits for a remote
cluster is created.

### xCluster

Ensures that a group of machines form a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] Name** _(Key)_: Name of the cluster.
* **[String] StaticIPAddress** _(Required)_: Static IP Address of the cluster.
* **[String] DomainAdministratorCredential** _(Required)_:: Credential used to
create the cluster.

#### Examples

[Cluster example](#cluster-example)

### xClusterDisk

Configures shared disks in a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] Number** _(Key)_: Number of the cluster disk.
* **[String] Ensure** _(Write)_: Define if the cluster disk should be added
(Present) or removed (Absent). Default value is 'Present'.
{ *Present* | Absent }
* **[String] Label** _(Write)_: The disk label inside the Failover Cluster.

#### Examples

None.

### xClusterNetwork

Configures preferred owners of a cluster group in a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] Address** _(Key)_: None.
* **[String] AddressMask** _(Key)_: None.
* **[String] Name** _(Write)_: None.
* **[String] Role** _(Write)_: None. { 0 | 1 | 3 }
* **[String] Metric** _(Write)_: None.

#### Examples

None.

### xClusterPreferredOwner

Configures preferred owners of a cluster group in a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] ClusterGroup** _(Key)_: Name of the cluster group.
* **[String] ClusterName** _(Key)_: Name of the cluster.
* **[String[]] Nodes** _(Required)_: The nodes to set as owners.
* **[String[]] ClusterResources** _(Write)_: The resources to set preferred
owner on.
* **[String] Ensure** _(Write)_: If the preferred owners should be present or
absent. Default value is 'Present'. { *Present* | Absent }

#### Examples

None.

### xClusterQuorum

Configures quorum in a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] IsSingleInstance** _(Key)_: Specifies the resource is a single
instance, the value must be 'Yes'.
* **[String] Type** _(Write)_: Quorum type to use. { NodeMajority |
NodeAndDiskMajority | NodeAndFileShareMajority, DiskOnly }.
* **[String] Resource** _(Write)_: The name of the disk or file share resource
to use as witness. This parameter is optional if the quorum type is set to
NodeMajority.

#### Examples

None.

### xWaitForCluster

Ensures that a node waits for a remote cluster is created.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later.

#### Parameters

* **[String] Name** _(Key)_: Name of the cluster to wait for.
* **[UInt64] RetryIntervalSec** _(Write)_: Interval to check for cluster
existence. Default values is 10 seconds.
* **[UInt32] RetryCount** _(Write)_: Maximum number of retries to check for
cluster existence. Default value is 50 retries.

#### Examples

[Cluster example](#cluster-example)
