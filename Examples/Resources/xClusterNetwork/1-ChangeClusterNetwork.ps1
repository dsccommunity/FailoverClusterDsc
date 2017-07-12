<#
.EXAMPLE
    This example shows how to change the properties Name, Role and Metric of two
    failover cluster network resources in the failover cluster.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterNetwork 'ChangeNetwork-10'
        {
            Address = '10.0.0.0'
            AddressMask = '255.255.255.0'
            Name = 'Client1'
            Role = '3'
            Metric = '10'
        }

        xClusterNetwork 'ChangeNetwork-192'
        {
            Address = '192.168.0.0'
            AddressMask = '255.255.255.0'
            Name = 'Heartbeat'
            Role = '1'
            Metric = '200'
        }
    }
}
