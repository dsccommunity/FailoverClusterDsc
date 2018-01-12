Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xClusterProperty'

<#
    .SYNOPSIS
        Configures cluster properties.

    .PARAMETER AddEvictDelay
        Specifies how many seconds after a node is evicted that the failover cluster service will wait before adding a new node.

    .PARAMETER ClusterLogLevel
        Controls the level of cluster logging.

    .PARAMETER ClusterLogSize
        Controls the maximum size of the cluster log files on each of the nodes.

    .PARAMETER CrossSiteDelay
        Controls the time interval, in milliseconds, that the cluster network driver waits between sending Cluster Service heartbeats across sites.

    .PARAMETER CrossSiteThreshold
        Controls how many Cluster Service heartbeats can be missed across sites before it determines that Cluster Service has stopped responding.

    .PARAMETER CrossSubnetDelay
        Controls the time interval, in milliseconds, that the cluster network driver waits between sending Cluster Service heartbeats across subnets.

    .PARAMETER CrossSubnetThreshold
        Controls how many Cluster Service heartbeats can be missed across subnets before it determines that Cluster Service has stopped responding.

    .PARAMETER DatabaseReadWriteMode
        Specifies the read/write mode for the cluster database.

    .PARAMETER DefaultNetworkRole
        Specifies the role that the cluster automatically assigns to any newly discovered or created network.

    .PARAMETER Description
        Stores administrative comments about the cluster. The following table summarizes the attributes of the Description property.

    .PARAMETER DrainOnShutdown
        Specifies whether to enable Node Drain for a cluster.

    .PARAMETER DynamicQuorum
        Enables the cluster to change the required number of nodes that need to participate in quorum when nodes shut down or crash.

    .PARAMETER NetftIPSecEnabled
        Specifies whether Internet Protocol Security (IPSec) encryption is enabled for inter-node cluster communication.

    .PARAMETER PreferredSite
        Specifies the preferred site for a site-aware cluster.

    .PARAMETER QuarantineDuration
        Specifies the quarantine duration for a node, in seconds.

    .PARAMETER QuarantineThreshold
        Specifies the quarantine threshold for a node, in minutes.

    .PARAMETER ShutdownTimeoutInMinutes
        Specifies how many minutes after a system shutdown is initiated that the failover cluster service will wait for resources to go offline.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose "Checking cluster properties"

    $ClusterProperties = Get-ClusterPropertyList

    $Cluster = Get-Cluster -Name $Name

    $ReturnValue = @{
    Name = $Name
    }

    foreach ($ClusterProperty in $ClusterProperties)
    {
        $ReturnValue.Add($ClusterProperty, $Cluster.$ClusterProperty)
    }

    $ReturnValue = foreach ($Item in $ReturnValue.GetEnumerator() | Sort-Object Name)
    {
        $Item
    }

    return $ReturnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $false)]
        $SameSubnetDelay,

        [Parameter(Mandatory = $false)]
        $SameSubnetThreshold,

        [Parameter(Mandatory = $false)]
        $CrossSubnetDelay,

        [Parameter(Mandatory = $false)]
        $CrossSubnetThreshold
    )

    Write-Verbose "Checking cluster thresholds"

    $Params = $PSBoundParameters
    $Params.Remove("Name") | Out-Null
    $Params.Remove("Verbose") | Out-Null

    foreach ($Param in $Params.GetEnumerator())
    {
        if ($Param.Value -ne "")
        {
            Write-Verbose "Setting cluster property $($Param.Key) to $([uint32]($Param.Value))"
            (Get-Cluster -Name $Name).$($Param.Key) = [uint32]($Param.Value)
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $false)]
        [Uint32]
        $SameSubnetDelay,

        [Parameter(Mandatory = $false)]
        [Uint32]
        $SameSubnetThreshold,

        [Parameter(Mandatory = $false)]
        [Uint32]
        $CrossSubnetDelay,

        [Parameter(Mandatory = $false)]
        [Uint32]
        $CrossSubnetThreshold
    )

    Write-Verbose "Checking cluster thresholds"

    $result = $true
    $Params = $PSBoundParameters
    $Params.Remove("Name") | Out-Null
    $Params.Remove("Result") | Out-Null
    $Params.Remove("Verbose") | Out-Null

    $Cluster = Get-Cluster -Name $Name

    foreach ($Param in $Params.GetEnumerator())
    {
        if ($Param.Value -ne "")
        {
            if($Cluster.$($Param.Key) -ne [uint32]($Param.Value))
            {
                Write-Debug "Cluster property $($Param.Key) is not eqaul to $([uint32]($Param.Value))"
                $result = $false
            }
        }
    }

    $result
}


Export-ModuleMember -Function *-TargetResource
