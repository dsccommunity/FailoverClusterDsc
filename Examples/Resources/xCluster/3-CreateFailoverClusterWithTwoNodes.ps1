<#
.EXAMPLE
    In this example, we will create a failover cluster with two servers.

    Assumptions:
    - We will assume that a Domain Controller already exists, and that both servers are already domain joined.
    - Both servers are using the same certificate, and that the certificate are installed on both servers so
      that LCM (Local Configuration Manager) can appropriately handle secrets such as the Active Directory
      administrator credential.
    - The example also assumes that the CNO (Cluster Name Object) is either prestaged or that the Active Directory
      administrator credential has the appropriate permission to create the CNO (Cluster Name Object).
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName= '*'

            <#
                Replace with the correct path to your own public certificate part of the same certificate
                that are installed on the target nodes.

                NOTE! This is commented so that AppVeyor automatic tests can pass, otherwise it will
                fail on missing certificate.
                Please remove comment from this row to be able to use your certificate.
            #>
            #CertificateFile = 'C:\Certificates\DscDemo.cer'

            <#
                Replace with the thumbprint of certificate that are installed on both the target nodes.
                This must be the private certificate of the same public certificate used in the previous
                parameter CertificateFile.
                For this example it is assumed that both machines have the same certificate installed.
            #>
            Thumbprint = "E513EEFCB763E6954C52BA66A1A81231BF3F551E"

            <#
                Replace with your own CNO (Cluster Name Object) and IP address.

                Please note that if the CNO is prestaged, then the computer object must be disabled for the
                resource xCluster to be able to create the cluster.
                If the CNO is not prestaged, then the credential used in the xCluster resource must have
                the permission in Active Directory to create the CNO (Cluster Name Object).
            #>
            ClusterName = 'Cluster01'
            ClusterIPAddress = '192.168.100.20/24'
        },

        # Node01 - First cluster node.
        @{
            # Replace with the name of the actual target node.
            NodeName= 'Node01'

            # This is used in the configuration to know which resource to compile.
            Role = 'FirstServerNode'
         },

         # Node02 - Second cluster node
         @{
            # Replace with the name of the actual target node.
            NodeName= 'Node02'

            # This is used in the configuration to know which resource to compile.
            Role = 'AdditionalServerNode'
         }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $ActiveDirectoryAdministratorCredential
    )

    Import-DscResource -ModuleName xFailOverCluster

    Node $AllNodes.Where{$_.Role -eq 'FirstServerNode' }.NodeName
    {
        WindowsFeature AddFailoverFeature
        {
            Ensure = 'Present'
            Name = 'Failover-clustering'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-PowerShell'
            DependsOn = '[WindowsFeature]AddFailoverFeature'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
        }

        xCluster CreateCluster
        {
            Name = $Node.ClusterName
            StaticIPAddress = $Node.ClusterIPAddress
            # This user must have the permission to create the CNO (Cluster Name Object) in Active Directory, unless it is prestaged.
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
       }
    }

    Node $AllNodes.Where{ $_.Role -eq 'AdditionalServerNode' }.NodeName
    {
        WindowsFeature AddFailoverFeature
        {
            Ensure = 'Present'
            Name = 'Failover-clustering'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-PowerShell'
            DependsOn = '[WindowsFeature]AddFailoverFeature'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
        }

        xWaitForCluster WaitForCluster
        {
            Name = $Node.ClusterName
            RetryIntervalSec = 10
            RetryCount = 60
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
        }

        xCluster JoinSecondNodeToCluster
        {
            Name = $Node.ClusterName
            StaticIPAddress = $Node.ClusterIPAddress
            DomainAdministratorCredential = $ActiveDirectoryAdministratorCredential
            DependsOn = '[xWaitForCluster]WaitForCluster'
        }
    }
}
