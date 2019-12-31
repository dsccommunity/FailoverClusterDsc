<#PSScriptInfo

.VERSION 1.0.0

.GUID 13e4f173-8edb-4172-ab2c-b6ca8234cbae

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS DSCConfiguration

.LICENSEURI https://github.com/dsccommunity/xFailOverCluster/blob/master/LICENSE

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
        This example shows how to remove two failover over cluster disk resources from
        the failover cluster.

    .NOTES
        This example assumes the failover cluster is already present.
#>

Configuration xClusterDisk_RemoveClusterDiskConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterDisk 'AddClusterDisk-SQL2017-DATA'
        {
            Number = 1
            Ensure = 'Absent'
            Label  = 'SQL2016-DATA'
        }

        xClusterDisk 'AddClusterDisk-SQL2017-LOG'
        {
            Number = 2
            Ensure = 'Absent'
            Label  = 'SQL2016-LOG'
        }
    }
}
