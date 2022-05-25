<#PSScriptInfo

.VERSION 1.0.0

.GUID 3d207c12-4ac1-4341-9c18-930d11d2a129

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
        This example shows how to remove two preferred owners from a failover cluster
        group and cluster resources in the failover cluster. This will leave any
        preferred owners not specified in the configuration.

    .NOTES
        If there are three preferred owners; Node1, Node2, Node3. This examples will
        still leave Node3 as a preferred owner.

        This example assumes the failover cluster is already present, and the cluster
        groups and cluster resources are present.
#>

Configuration ClusterPreferredOwner_RemovePreferredOwnerConfig
{
    Import-DscResource -ModuleName FailoverClusterDsc

    Node localhost
    {
        ClusterPreferredOwner 'RemoveOwnersForClusterGroup1'
        {
            Ensure           = 'Absent'
            ClusterName      = 'TESTCLU1'
            ClusterGroup     = 'Cluster Group 1'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = @('Resource1', 'Resource2')
        }

        ClusterPreferredOwner 'RemoveOwnersForClusterGroup2'
        {
            Ensure           = 'Absent'
            ClusterName      = 'TESTCLU1'
            ClusterGroup     = 'Cluster Group 2'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = @('Resource3', 'Resource4')
        }
    }
}
