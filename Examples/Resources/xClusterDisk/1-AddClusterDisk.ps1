<#
.EXAMPLE
    This example shows how to add two failover over cluster disk resources to the
    failover cluster.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterDisk 'AddClusterDisk-SQL2017-DATA'
        {
            Number = 1
            Ensure = 'Present'
            Label  = 'SQL2016-DATA'
        }

        xClusterDisk 'AddClusterDisk-SQL2017-LOG'
        {
            Number = 2
            Ensure = 'Present'
            Label  = 'SQL2016-LOG'
        }
    }
}
