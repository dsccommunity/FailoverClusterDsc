<#PSScriptInfo

.VERSION 1.0.0

.GUID 4586c657-ca76-46b4-ba81-1e426cb17acd

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
        This example shows how to add two preferred owners to a failover cluster
        group and cluster resources in the failover cluster.

    .NOTES
        This example assumes the failover cluster is already present.
#>

Configuration xClusterPreferredOwner_AddPreferredOwnerConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterPreferredOwner 'AddOwnersForClusterGroup1'
        {
            Ensure           = 'Present'
            ClusterName      = 'TESTCLU1'
            ClusterGroup     = 'Cluster Group 1'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = @('Resource1', 'Resource2')
        }

        xClusterPreferredOwner 'AddOwnersForClusterGroup2'
        {
            Ensure           = 'Present'
            ClusterName      = 'TESTCLU1'
            ClusterGroup     = 'Cluster Group 2'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = @('Resource3', 'Resource4')
        }
    }
}
