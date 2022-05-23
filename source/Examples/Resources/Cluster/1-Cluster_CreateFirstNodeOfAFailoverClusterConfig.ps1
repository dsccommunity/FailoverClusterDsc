<#PSScriptInfo

.VERSION 1.0.0

.GUID 2a4174f6-aa62-49c8-bee3-a288f70ebcfc

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
        This example shows how to create the failover cluster on the first node.
#>

Configuration Cluster_CreateFirstNodeOfAFailoverClusterConfig
{
    param(
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

        Cluster CreateCluster
        {
            Name                          = 'Cluster01'
            StaticIPAddress               = '192.168.100.20/24'

            <#
                This user must have the permission to create the CNO (Cluster Name Object) in Active Directory,
                unless it is prestaged.
            #>
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential

            DependsOn                     = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
        }
    }
}
