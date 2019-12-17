<#
.EXAMPLE
    This example shows how to set the quorum in a failover cluster to use
    node and cloud majority.

    This example assumes the failover cluster is already present.

    This example also assumes that the Azure storage account 'myazurestorageaccount'
    is already present.
    An Azure storage account has 2 connection keys. Only one is needed for configuration.
    Here is a link for setting up the high availability with cloud witness
    https://docs.microsoft.com/en-us/windows-server/failover-clustering/deploy-cloud-witness
#>

Configuration Example
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
