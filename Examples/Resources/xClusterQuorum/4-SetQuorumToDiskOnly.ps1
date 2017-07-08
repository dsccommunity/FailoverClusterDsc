<#
.EXAMPLE
    This example shows how to set the quorum in a failover cluster to use
    disk only.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToDiskOnly'
        {
            IsSingleInstance = 'Yes'
            Type = 'DiskOnly'
            Resource = 'Witness Cluster Disk'
        }
    }
}
