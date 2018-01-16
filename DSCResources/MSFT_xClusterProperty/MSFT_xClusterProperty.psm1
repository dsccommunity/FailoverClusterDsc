Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xClusterProperty'

<#
    .SYNOPSIS
        Configures cluster properties.

    .PARAMETER Name
        Specifies the cluster name
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.CheckingClusterProperties)

    $ClusterProperties = Get-ClusterPropertyList

    $Cluster = Get-Cluster -Name $Name
    $ReturnValue = @{
    Name = $Name
    }

    foreach ($ClusterProperty in $ClusterProperties)
    {
        $ReturnValue.Add($ClusterProperty, $Cluster.$ClusterProperty)
    }

    return $ReturnValue
}

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

    .PARAMETER Name
        Specifies the cluster name

    .PARAMETER NetftIPSecEnabled
        Specifies whether Internet Protocol Security (IPSec) encryption is enabled for inter-node cluster communication.

    .PARAMETER PreferredSite
        Specifies the preferred site for a site-aware cluster.

    .PARAMETER QuarantineDuration
        Specifies the quarantine duration for a node, in seconds.

    .PARAMETER QuarantineThreshold
        Specifies the quarantine threshold for a node, in minutes.

    .PARAMETER SameSubnetDelay
        Controls the delay, in milliseconds, between netft heartbeats.

    .PARAMETER SameSubnetThreshold
        Controls how many heartbeats can be missed on the same subnet before the route is declared as unreachable.

    .PARAMETER ShutdownTimeoutInMinutes
        Specifies how many minutes after a system shutdown is initiated that the failover cluster service will wait for resources to go offline.
#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Uint32]
        $AddEvictDelay,

        [Parameter()]
        [Uint32]
        $ClusterLogLevel,

        [Parameter()]
        [Uint32]
        $ClusterLogSize,

        [Parameter()]
        [Uint32]
        $CrossSiteDelay,

        [Parameter()]
        [Uint32]
        $CrossSiteThreshold,

        [Parameter()]
        [Uint32]
        $CrossSubnetDelay,

        [Parameter()]
        [Uint32]
        $CrossSubnetThreshold,

        [Parameter()]
        [Uint32]
        $DatabaseReadWriteMode,

        [Parameter()]
        [Uint32]
        $DefaultNetworkRole,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [Uint32]
        $DrainOnShutdown,

        [Parameter()]
        [Uint32]
        $DynamicQuorum,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [Uint32]
        $NetftIPSecEnabled,

        [Parameter()]
        [String]
        $PreferredSite,

        [Parameter()]
        [Uint32]
        $QuarantineDuration,

        [Parameter()]
        [Uint32]
        $QuarantineThreshold,

        [Parameter()]
        [Uint32]
        $SameSubnetDelay,

        [Parameter()]
        [Uint32]
        $SameSubnetThreshold,

        [Parameter()]
        [Uint32]
        $ShutdownTimeoutInMinutes
    )

    Write-Verbose -Message ($script:localizedData.SettingClusterProperties)

    $Params = $PSBoundParameters
    $Params.Remove("Name") | Out-Null
    $Params.Remove("Verbose") | Out-Null

    foreach ($Param in $Params.GetEnumerator())
    {
        $VerboseValue = "`"$($Param.Value)`""
        Write-Verbose -Message ($script:localizedData.SettingClusterProperty -f $($Param.Key), $VerboseValue)
        (Get-Cluster -Name $Name).$($Param.Key) = ($Param.Value)
    }
}

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

    .PARAMETER Name
        Specifies the cluster name

    .PARAMETER NetftIPSecEnabled
        Specifies whether Internet Protocol Security (IPSec) encryption is enabled for inter-node cluster communication.

    .PARAMETER PreferredSite
        Specifies the preferred site for a site-aware cluster.

    .PARAMETER QuarantineDuration
        Specifies the quarantine duration for a node, in seconds.

    .PARAMETER QuarantineThreshold
        Specifies the quarantine threshold for a node, in minutes.

    .PARAMETER SameSubnetDelay
        Controls the delay, in milliseconds, between netft heartbeats.

    .PARAMETER SameSubnetThreshold
        Controls how many heartbeats can be missed on the same subnet before the route is declared as unreachable.

    .PARAMETER ShutdownTimeoutInMinutes
        Specifies how many minutes after a system shutdown is initiated that the failover cluster service will wait for resources to go offline.
#>

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [Uint32]
        $AddEvictDelay,

        [Parameter()]
        [Uint32]
        $ClusterLogLevel,

        [Parameter()]
        [Uint32]
        $ClusterLogSize,

        [Parameter()]
        [Uint32]
        $CrossSiteDelay,

        [Parameter()]
        [Uint32]
        $CrossSiteThreshold,

        [Parameter()]
        [Uint32]
        $CrossSubnetDelay,

        [Parameter()]
        [Uint32]
        $CrossSubnetThreshold,

        [Parameter()]
        [Uint32]
        $DatabaseReadWriteMode,

        [Parameter()]
        [Uint32]
        $DefaultNetworkRole,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [Uint32]
        $DrainOnShutdown,

        [Parameter()]
        [Uint32]
        $DynamicQuorum,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [Uint32]
        $NetftIPSecEnabled,

        [Parameter()]
        [String]
        $PreferredSite,

        [Parameter()]
        [Uint32]
        $QuarantineDuration,

        [Parameter()]
        [Uint32]
        $QuarantineThreshold,

        [Parameter()]
        [Uint32]
        $SameSubnetDelay,

        [Parameter()]
        [Uint32]
        $SameSubnetThreshold,

        [Parameter()]
        [Uint32]
        $ShutdownTimeoutInMinutes
    )

    Write-Verbose -Message ($script:localizedData.CheckingClusterProperties)

    $Params = $PSBoundParameters
    $Params.Remove("Name") | Out-Null
    $Params.Remove("Result") | Out-Null
    $Params.Remove("Verbose") | Out-Null
    $Params.Remove("Debug") | Out-Null

    $Cluster = Get-Cluster -Name $Name

    $result = $true

    foreach ($Param in $Params.GetEnumerator())
    {
        if($Cluster.$($Param.Key) -ne ($Param.Value))
        {
            $VerboseValue = "`"$($Param.Value)`""
            Write-Debug -Message ($script:localizedData.IncorrectClusterProperty -f $($Param.Key), $VerboseValue)
            $result = $false
        }
    }

    $result
}


Export-ModuleMember -Function *-TargetResource
