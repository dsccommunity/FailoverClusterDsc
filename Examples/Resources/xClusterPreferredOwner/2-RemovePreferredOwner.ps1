<#
.EXAMPLE
    This example shows how to remove two preferred owners from a failover cluster
    group and cluster resources in the failover cluster. This will leave any
    preferred owners not specified in the configuration.

    If there are three preferred owners; Node1, Node2, Node3. This examples will
    still leave Node3 as a preferred owner.

    This example assumes the failover cluster is already present, and the cluster
    groups and cluster resources are present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterPreferredOwner 'RemoveOwnersForClusterGroup1'
        {
            Ensure = 'Absent'
            ClusterName = 'TESTCLU1'
            ClusterGroup = 'Cluster Group 1'
            Nodes = @('Node1', 'Node2')
            ClusterResources = @('Resource1','Resource2')
        }

        xClusterPreferredOwner 'RemoveOwnersForClusterGroup2'
        {
            Ensure = 'Absent'
            ClusterName = 'TESTCLU1'
            ClusterGroup = 'Cluster Group 2'
            Nodes = @('Node1', 'Node2')
            ClusterResources = @('Resource3','Resource4')
        }
    }
}
