<#
.EXAMPLE
    This example shows how to set the quorum in a failover cluster to use
    fileshare as a witness.

    This example assumes the failover cluster is already present.
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToFileShareWitness'
        {
            IsSingleInstance = 'Yes'
            Type             = 'FileShareWitness'
            Resource         = '\\witness.company.local\witness$'
        }
    }
}
