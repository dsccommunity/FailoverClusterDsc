<#PSScriptInfo

.VERSION 1.0.0

.GUID 593e1540-3778-4260-9389-1deceb419c8c

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
Updated author and copyright notice.

.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core

#>

#Requires -Module xFailOverCluster


<#
    .DESCRIPTION
        This example shows how to add an additional node to the failover cluster.
#>

Configuration JoinAdditionalNodeToFailoverClusterConfig
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ActiveDirectoryAdministratorCredential
    )

    Import-DscResource -ModuleName xFailOverCluster

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

        xWaitForCluster WaitForCluster
        {
            Name             = 'Cluster01'
            RetryIntervalSec = 10
            RetryCount       = 60
            DependsOn        = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
        }

        xCluster JoinSecondNodeToCluster
        {
            Name                          = 'Cluster01'
            StaticIPAddress               = '192.168.100.20/24'
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential
            DependsOn                     = '[xWaitForCluster]WaitForCluster'
        }
    }
}
