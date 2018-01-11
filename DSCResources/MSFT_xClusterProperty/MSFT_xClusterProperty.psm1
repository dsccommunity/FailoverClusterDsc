$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xClusterProperty'

<#
    .SYNOPSIS
        Returns the current state of the failover cluster network resource.

    .PARAMETER Address
        The address for the cluster network in the format '10.0.0.0'.

    .PARAMETER AddressMask
        The address mask for the cluster network in the format '255.255.255.0'.
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

    $ClusterProperties = "AddEvictDelay","SameSubnetDelay","SameSubnetThreshold","AutoBalancerLevel"

    $Cluster = Get-Cluster -Name $Name

    $returnValue = @{
    Name = $Name
    }

    foreach ($ClusterProperty in $ClusterProperties)
    {
        $returnValue.Add($ClusterProperty, $Cluster.$ClusterProperty)
    }

    $returnValue
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
