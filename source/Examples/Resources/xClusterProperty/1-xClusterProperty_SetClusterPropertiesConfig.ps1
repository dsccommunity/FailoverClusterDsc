<#PSScriptInfo

.VERSION 1.0.0

.GUID c560f191-b9e9-4099-8339-2e085c3452e9

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS DSCConfiguration

.LICENSEURI https://github.com/dsccommunity/xFailOverCluster/blob/master/LICENSE

.PROJECTURI https://github.com/dsccommunity/xFailOverCluster

.ICONURI

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
        This example shows how to set a number of failover cluster properties.

    .NOTES
       This example assumes the failover cluster is already present.
#>

Configuration xClusterProperty_SetClusterPropertiesConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    node localhost
    {
        xClusterProperty SetProperties
        {
            Name = 'Cluster1'
            AddEvictDelay = 60
            ClusterLogSize = 300
            Description = ''
            SameSubnetDelay = 1000
            SameSubnetThreshold = 5
        }
    }
}
