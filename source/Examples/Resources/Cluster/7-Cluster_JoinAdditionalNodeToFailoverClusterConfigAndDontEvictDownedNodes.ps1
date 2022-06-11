<#PSScriptInfo

.VERSION 1.0.0

.GUID 593e1540-3778-4260-9389-1deceb419c8c

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
        This example shows how to add an additional node to the failover cluster without evicting cluster nodes in a down state.
#>

Configuration Cluster_JoinAdditionalNodeToFailoverClusterConfigAndDontEvictDownedNodes
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ActiveDirectoryAdministratorCredential
    )

    Import-DscResource -ModuleName FailoverClusterDsc

    Node localhost
    {
        WindowsFeature AddFailoverFeature
        {
            Ensure = 'Present'
            Name   = 'Failover-clustering'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-PowerShell'
            DependsOn = '[WindowsFeature]AddFailoverFeature'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
        }

        WaitForCluster WaitForCluster
        {
            Name             = 'Cluster01'
            RetryIntervalSec = 10
            RetryCount       = 60
            DependsOn        = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
        }

        Cluster JoinSecondNodeToCluster
        {
            Name                          = 'Cluster01'
            StaticIPAddress               = '192.168.100.20/24'
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential
            KeepDownedNodesInCluster      = $True
            DependsOn                     = '[WaitForCluster]WaitForCluster'
        }
    }
}
