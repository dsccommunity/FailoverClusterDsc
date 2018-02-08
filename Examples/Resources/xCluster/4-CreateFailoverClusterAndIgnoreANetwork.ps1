<#
.EXAMPLE
    This example shows how to create the a failover cluster on the first node and ignoring a network.
#>

Configuration Example
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

        xCluster CreateCluster
        {
            Name                          = 'Cluster01'
            StaticIPAddress               = '192.168.100.20/24'
            IgnoreNetwork                 = @('10.0.2.0/24')

            <#
                This user must have the permission to create the CNO (Cluster Name Object) in Active Directory,
                unless it is prestaged.
            #>
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential

            DependsOn                     = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
        }
    }
}
