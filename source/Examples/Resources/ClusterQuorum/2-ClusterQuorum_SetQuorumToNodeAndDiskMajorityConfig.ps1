<#PSScriptInfo

.VERSION 1.0.0

.GUID 62724b66-2dfb-4107-8052-956c6d341a20

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
        node and disk majority.

    .NOTES
       This example assumes the failover cluster is already present.
#>

Configuration xClusterQuorum_SetQuorumToNodeAndDiskMajorityConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToNodeAndDiskMajority'
        {
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndDiskMajority'
            Resource         = 'Witness Cluster Disk'
        }
    }
}
