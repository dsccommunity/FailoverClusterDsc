# xFailOverCluster

The **xFailOverCluster** module contains DSC resources for deployment and configuration of Failover Clustering.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/6a59vfritv4kbc7d/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xfailovercluster/branch/master)

This is the branch containing the latest release - no contributions should be made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/6a59vfritv4kbc7d/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xfailovercluster/branch/dev)

This is the development branch to which contributions should be proposed by contributors as pull requests. This development branch will periodically be merged to the master branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**xCluster**](#xcluster) Ensures that a group of machines form a cluster.
* [**xClusterQuorum**](#xclusterquorum) Configures quorum in a cluster.
* [**xClusterDisk**](#xclusterdisk) Configures shared disks in a cluster.
* [**xWaitForCluster**](#xwaitforcluster) Ensures that a node waits for a remote cluster is created.

### xCluster

Ensures that a group of machines form a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later

#### Parameters

* **Name**: Name of the cluster
* **StaticIPAddress**: Static IP Address of the cluster
* **DomainAdministratorCredential**: Credential used to create the cluster

#### Examples

[Cluster example](#clusterexample)

### xClusterQuorum

Configures quorum in a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later

#### Parameters

* **IsSingleInstance** Always set to `Yes` to prevent multiple quorum settings per cluster.
* **Type** Quorum type to use: *NodeMajority*, *NodeAndDiskMajority*, *NodeAndFileShareMajority*, *DiskOnly*
* **Resource** The name of the disk or file share resource to use as witness. Is optional with *NodeMajority* type.

#### Examples

None.

### xClusterDisk

Configures shared disks in a cluster.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later

#### Parameters

* **Number**: Number of the cluster disk
* **Ensure**: Define if the cluster disk should be added (Present) or removed (Absent)
* **Label**: The disk label inside the Failover Cluster

#### Examples

None.

### xWaitForCluster

Ensures that a node waits for a remote cluster is created.

#### Requirements

* Target machine must be running Windows Server 2008 R2 or later

#### Parameters

* **Name**: Name of the cluster to wait for
* **RetryIntervalSec**: Interval to check for cluster existence
* **RetryCount**: Maximum number of retries to check for cluster existance
* **Credential**: Credential used to join or leave domain

#### Examples

[Cluster example](#clusterexample)

## xFailOverCluster Examples

### Cluster example

In this example, we will create a failover cluster from two VMs.
We will assume that a Domain Controller already exists, and that both VMs are already domain joined.
Furthermore, the example assumes that your certificates are installed such that DSC can appropriately handle secrets such as the Domain Administrator Credential.
Finally, the xCluster module must also be installed on the VMs, as specified above.
For an example of an end to end scenario, check out the SQL HA Group blog post on the PowerShell Team Blog.

```powershell
Configuration ClusterDemo
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PsCredential]
        $domainAdminCredential
    )

    Node $AllNodes.Where{$_.Role -eq 'PrimaryClusterNode' }.NodeName
    {
        WindowsFeature FailoverFeature
        {
            Ensure = 'Present'
            Name   = 'Failover-clustering'
        }

        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-PowerShell'

            DependsOn = '[WindowsFeature]FailoverFeature'
        }

        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-CmdInterface'

            DependsOn = '[WindowsFeature]RSATClusteringPowerShell'
        }

        xCluster ensureCreated
        {
            Name = $Node.ClusterName
            StaticIPAddress = $Node.ClusterIPAddress
            DomainAdministratorCredential = $domainAdminCredential

           DependsOn = “[WindowsFeature]RSATClusteringCmdInterface”
       }

    }

    Node $AllNodes.Where{ $_.Role -eq 'ReplicaServerNode' }.NodeName
    {
        WindowsFeature FailoverFeature
        {
            Ensure = 'Present'
            Name      = 'Failover-clustering'
        }

        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-PowerShell'

            DependsOn = '[WindowsFeature]FailoverFeature'
        }

        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = 'Present'
            Name   = 'RSAT-Clustering-CmdInterface'

            DependsOn = '[WindowsFeature]RSATClusteringPowerShell'
        }

        xWaitForCluster waitForCluster
        {
            Name = $Node.ClusterName
            RetryIntervalSec = 10
            RetryCount = 60

            DependsOn = '[WindowsFeature]RSATClusteringCmdInterface'
        }

        xCluster joinCluster
        {
            Name = $Node.ClusterName
            StaticIPAddress = $Node.ClusterIPAddress
            DomainAdministratorCredential = $domainAdminCredential

            DependsOn = '[xWaitForCluster]waitForCluster'
        }
    }
}

$ConfigData = @{
    AllNodes = @(

        @{
            NodeName= '*'

            CertificateFile = 'C:\keys\Dscdemo.cer'                 # use your own certificate
            Thumbprint = "E513EEFCB763E6954C52BA66A1A81231BF3F551E" # assume both machines have the same certificate to hold private key
                                                                    # replace the value of thumbprint with your own.

            ClusterName = 'Cluster'
            ClusterIPAddress = '192.168.100.20/24'    # replace the ip address of your own.
        },

         # Node01
        @{
            NodeName= 'Node01'   # rename to actual machine name of VM
            Role = 'PrimaryClusterNode'
         },

         # Node02
         @{
            NodeName= 'Node02'   # rename to actual machine name of VM
            Role = 'ReplicaServerNode'
         }
    )
}

$domainAdminCred = Get-Credential -UserName 'ClusterDemo\Administrator' -Message 'Enter password for private domain Administrator'

ClusterDemo -ConfigurationData $ConfigData -domainAdminCred $domainAdminCredential
```
