<#
.EXAMPLE
    This example shows how to remove two failover over cluster disk resources from
    the failover cluster.

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
            Ensure = 'Absent'
            Label = 'SQL2016-DATA'
        }

        xClusterDisk 'AddClusterDisk-SQL2017-LOG'
        {
            Number = 2
            Ensure = 'Absent'
            Label = 'SQL2016-LOG'
        }
    }
}
