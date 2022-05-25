<#PSScriptInfo

.VERSION 1.0.0

.GUID fa169dcd-b3ae-4af4-8c95-085e6ebe234c

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS DSCConfiguration

.LICENSEURI https://github.com/dsccommunity/FailoverClusterDsc/blob/main/LICENSE

.PROJECTURI https://github.com/dsccommunity/FailoverClusterDsc

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
First version.

.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core

#>

#Requires -Module FailoverClusterDsc

<#
    .DESCRIPTION
        This example shows how to set the quorum in a failover cluster to use
        node majority.

    .NOTES
       This example assumes the failover cluster is already present.
#>

Configuration ClusterQuorum_SetQuorumToNodeMajorityConfig
{
    Import-DscResource -ModuleName FailoverClusterDsc

    Node localhost
    {
        ClusterQuorum 'SetQuorumToNodeMajority'
        {
            IsSingleInstance = 'Yes'
            Type             = 'NodeMajority'
        }
    }
}
