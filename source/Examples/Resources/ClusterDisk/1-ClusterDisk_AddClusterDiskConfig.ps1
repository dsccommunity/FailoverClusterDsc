<#PSScriptInfo

.VERSION 1.0.0

.GUID b5646852-132f-4f84-8057-b8e9e91e29b8

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
        This example shows how to add two failover over cluster disk resources to the
        failover cluster.

    .NOTES
        This example assumes the failover cluster is already present.
#>

Configuration xClusterDisk_AddClusterDiskConfig
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
