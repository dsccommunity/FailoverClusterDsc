<#
.EXAMPLE
    This example shows how to set a number of failover cluster properties.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    node localhost
    {
        xClusterProperty SetProperties
        {
            AddEvictDelay = 60
            ClusterLogSize = 300
            Description = ''
            Name = 'LITDAG01'
            SameSubnetDelay = 1000
            SameSubnetThreshold = 5
        }
    }
}
