<#PSScriptInfo

.VERSION 1.0.0

.GUID a8915218-1dc2-413e-a999-2f60bf90c023

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS DSCConfiguration

.LICENSEURI https://github.com/dsccommunity/xFailOverCluster/blob/master/LICENSE

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
        This example shows how to set the quorum in a failover cluster to use
        node and cloud majority.

    .NOTES
        This example assumes the failover cluster is already present.

        This example also assumes that the Azure storage account 'myazurestorageaccount'
        is already present.
        An Azure storage account has 2 connection keys. Only one is needed for
        configuration. Here is a link for setting up the high availability with
        cloud witness https://docs.microsoft.com/en-us/windows-server/failover-clustering/deploy-cloud-witness
#>

Configuration xClusterQuorum_SetQuorumToNodeAndCloudMajorityConfig
{
    Import-DscResource -ModuleName xFailOverCluster

    Node localhost
    {
        xClusterQuorum 'SetQuorumToNodeAndCloudMajority'
        {
            IsSingleInstance        = 'Yes'
            Type                    = 'NodeAndCloudMajority'
            Resource                = 'myazurestorageaccount'
            StorageAccountAccessKey = '8gxPaXynG5onrfpuob+M+5wBE7ow01CjdyOw7rj3DbepsK/tt3kr1GOuqJhARCPeyAQmfW8WsTCOGFwAYUVw/Q=='
        }
    }
}
