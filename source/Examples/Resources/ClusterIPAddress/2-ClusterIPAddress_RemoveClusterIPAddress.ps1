<#PSScriptInfo

.VERSION 1.0.0

.GUID b5646852-132f-4f84-8057-b8e9e91e29b8

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
        This example shows how to add two failover over cluster disk resources to the
        failover cluster.

    .NOTES
        This example assumes the failover cluster is already present.
#>

Configuration ClusterIPAddress_RemoveClusterIPAddress
{
    Import-DscResource -ModuleName FailoverClusterDsc

    Node localhost
    {
        ClusterIPAddress 'RemoveClusterIPAddress_192.168.1.25'
        {
            IPAddress   = '192.168.1.25'
            Ensure      = 'Absent'
            AddressMask = '255.255.255.0'
        }

        ClusterIPAddress 'RemoveClusterIPAddress_10.10.10.25'
        {
            IPAddress   = '10.10.10.25'
            Ensure      = 'Absent'
            AddressMask = '255.255.0.0'
        }
    }
}
