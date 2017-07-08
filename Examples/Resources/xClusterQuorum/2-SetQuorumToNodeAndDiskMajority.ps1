<#
.EXAMPLE
    This example shows how to set the quorum in a failover cluster to use
    node and disk majority.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToNodeAndDiskMajority'
        {
            IsSingleInstance = 'Yes'
            Type = 'NodeAndDiskMajority'
            Resource = 'Witness Cluster Disk'
        }
    }
}
