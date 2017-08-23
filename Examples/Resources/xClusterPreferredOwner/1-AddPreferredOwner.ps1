<#
.EXAMPLE
    This example shows how to add two preferred owners to a failover cluster
    group and cluster resources in the failover cluster.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterPreferredOwner 'AddOwnersForClusterGroup1'
        {
            Ensure           = 'Present'
            ClusterName      = 'TESTCLU1'
            ClusterGroup     = 'Cluster Group 1'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = @('Resource1', 'Resource2')
        }

        xClusterPreferredOwner 'AddOwnersForClusterGroup2'
        {
            Ensure           = 'Present'
            ClusterName      = 'TESTCLU1'
            ClusterGroup     = 'Cluster Group 2'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = @('Resource3', 'Resource4')
        }
    }
}
