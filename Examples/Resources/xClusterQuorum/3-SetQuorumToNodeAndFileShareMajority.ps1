<#
.EXAMPLE
    This example shows how to set the quorum in a failover cluster to use
    node and file share majority.

    This example assumes the failover cluster is already present.

    This example also assumes that path \\witness.company.local\witness$ is already
    present and has the right permission to be used by the cluster.
    Either the user running the configuration or the Cluster Name Object (CNO)
    should have full control on the share to be able to create the witness folder
    and set the permissions. More than one cluster can use the same share.
    Here is a link for setting up the high availability for the file share witness
    https://blogs.msdn.microsoft.com/clustering/2014/03/31/configuring-a-file-share-witness-on-a-scale-out-file-server/
#>

Configuration Example
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToNodeAndDiskMajority'
        {
            IsSingleInstance = 'Yes'
            Type = 'NodeAndFileShareMajority'
            Resource = '\\witness.company.local\witness$'
        }
    }
}
