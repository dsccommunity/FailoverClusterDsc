<#PSScriptInfo

.VERSION 1.0.0

.GUID dae94758-1424-4f6c-abb4-2b2ee5f18df4

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS DSCConfiguration

.LICENSEURI https://github.com/dsccommunity/xFailOverCluster/blob/main/LICENSE

.PROJECTURI https://github.com/dsccommunity/xFailOverCluster

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
First version.

.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core

#>

#Requires -Module xFailOverCluster

<#
    .DESCRIPTION
        This example shows how to set the quorum in a failover cluster to use
        node and file share majority.

    .NOTES
       This example assumes the failover cluster is already present.

        This example also assumes that path \\witness.company.local\witness$ is
        already present and has the right permission to be used by the cluster.
        Either the user running the configuration or the Cluster Name Object (CNO)
        should have full control on the share to be able to create the witness
        folder and set the permissions. More than one cluster can use the same
        share. Here is a link for setting up the high availability for the file
        share witness https://blogs.msdn.microsoft.com/clustering/2014/03/31/configuring-a-file-share-witness-on-a-scale-out-file-server/
#>

Configuration xClusterQuorum_SetQuorumToNodeAndFileShareMajorityConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToNodeAndDiskMajority'
        {
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndFileShareMajority'
            Resource         = '\\witness.company.local\witness$'
        }
    }
}
