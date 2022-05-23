<#PSScriptInfo

.VERSION 1.0.0

.GUID 00a38891-00f6-4a17-9321-9b40ba4bd2b1

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
        This example shows how to change the properties Name, Role and Metric of two
        failover cluster network resources in the failover cluster.

    .NOTES
        This example assumes the failover cluster is already present.
#>

Configuration xClusterNetwork_ChangeClusterNetworkConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterNetwork 'ChangeNetwork-10'
        {
            Address     = '10.0.0.0'
            AddressMask = '255.255.255.0'
            Name        = 'Client1'
            Role        = '3'
            Metric      = '10'
        }

        xClusterNetwork 'ChangeNetwork-192'
        {
            Address     = '192.168.0.0'
            AddressMask = '255.255.255.0'
            Name        = 'Heartbeat'
            Role        = '1'
            Metric      = '200'
        }
    }
}
