$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
<#
    .SYNOPSIS
        Returns the current state of the failover cluster IP address.

    .PARAMETER IPAddress
        IP address to check the state of.

    .PARAMETER AddressMask
        Address mask of the IP address.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask,

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present'
    )
    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask
    Write-Verbose -Message ($script:localizedData.GetTargetResourceMessage -f $IPAddress, $AddressMask)

    $result = @{
        IPAddress   = $null
        AddressMask = $null
        Ensure      = 'Absent'
    }

    $ipResources = Get-ClusterResource | Where-Object {$_.ResourceType -eq 'IP Address'}

    foreach ( $ipResource in $ipResources )
    {
        $ipResourceDetails = Get-ClusterIPResourceParameters -IPAddressResourceName $ipResource.name

        if ( $ipResourceDetails.Address -eq $IPAddress )
        {
            Write-Verbose -Message ($script:localizedData.FoundIPResource -f $IPAddress)
            $result.IPAddress   = $ipResourceDetails.Address
            $result.AddressMask = $ipResourceDetails.AddressMask
            $result.Ensure      = 'Present'
        }
    }
    $result
}

<#
    .SYNOPSIS
        Sets the state of the failover cluster IP address.

    .PARAMETER IPAddress
        IP address to either add or remove from the Failover Cluster.

    .PARAMETER AddressMask
        Address mask of the IP address to either add or remove from the Failover Cluster.
#>
function Set-TargetResource
{
    param
    (

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',

        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    Write-Verbose -Message ($script:localizedData.SetTargetResourceMessage -f $IPAddress, $AddressMask, $Ensure)
    if ($Ensure -eq 'Present')
    {
        # We've gotten here because the IPAddress given is not in the DependencyExpression for the cluster
        # We need to Check if the network is added to the cluster. If not, we fail. If it is, we can append the IPAddress
        if ( -not $(Test-ClusterNetwork -IPAddress $IPAddress -AddressMask $AddressMask) )
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.NonExistantClusterNetwork -f $IPAddress,$AddressMask) `
                -ArgumentName 'IPAddress'
        }
        else
        {
            $params = @{
                IPAddress   = $IPAddress
                AddressMask  = $AddressMask
                ErrorAction = 'Stop'
            }
            Add-ClusterIPAddressDependency @params
        }
    }
    else
    {
        Remove-ClusterIPAddressDependency -IPAddress $IPAddress -AddressMask $AddressMask
    }
}

<#
    .SYNOPSIS
        Tests the current state of the failover cluster IP address.

    .PARAMETER IPAddress
        IP address to check the state of.

    .PARAMETER AddressMask
        Address mask of the IP address.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',

        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    Write-Verbose -Message ($script:localizedData.TestTargetResourceMessage -f $IPAddress, $AddressMask, $Ensure)

    $ipResource = Get-TargetResource -IPAddress $IPAddress -AddressMask $AddressMask -Ensure $Ensure
    $result = $false

    if ($Ensure -eq 'Present')
    {
        if (-not ([System.String]::IsNullOrEmpty($ipResource.IPAddress)))
        {
            if ($ipResource.AddressMask -eq $AddressMask)
            {
                $result = $true
            }
        }
    }
    else
    {
        <#
            $ipResource will always have some contents, but if IPAddress is null or empty,
            the resource does not exist.
        #>
        if ([System.String]::IsNullOrEmpty($ipResource.IPAddress))
        {
            $result = $true
        }
    }
    $result
}

<#
    .Synopsis
        Given an IP Address and a Subnet Mask, returns the IP Addresses subnet.
    .DESCRIPTION
        Returns an IPAddress object of the subnet mask of the given IPAddress and Subnet.
    .PARAMETER IPAddress
        IP address to add to the Cluster's DependencyExpression
    .PARAMETER AddressMask
        The subnet mask of the IPAddress
    .EXAMPLE
        Get-Subnet -IPAddress 10.235.32.129 -AddressMask 255.255.255.128
#>
function Get-Subnet
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    $subnet = ([IPAddress](([IPAddress]$Ipaddress).Address -band ([IPAddress]$AddressMask).Address)).IPAddressToString
    Write-Verbose -Message ($script:localizedData.FoundSubnetfromIPAddressandAddressMask -f $IPAddress, $AddressMask, $subnet)
    return $subnet
}

<#
    .Synopsis
        Adds an IPAddress as a Dependency to a Windows Cluster
    .DESCRIPTION
        Adds an IP Address resource to a Windows Cluster's Dependecy Expression
    .PARAMETER IPAddress
        IP address to add to the Cluster's DependencyExpression
    .PARAMETER AddressMask
        The subnet mask of the IPAddress
    .PARAMETER ClusterName
        Name of the cluster to add IP Address resource to
    .EXAMPLE
        # Using the default ParameterSet of both IP Address and Subnet
        Add-ClusterIPAddressDependency -IPAddress 10.235.32.137 -AddressMask 255.255.255.128 -Verbose
#>
function Add-ClusterIPAddressDependency
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    #* Get Windows Cluster resource
    $clusterObj = Get-ClusterObject

    $ipResourceName = Add-ClusterIPResource -IPAddress $IPAddress -OwnerGroup $clusterObj.ownerGroup
    $ipResource = Get-ClusterResource -Name $ipResourceName
    Add-ClusterIPParameter -IPAddressResourceName $ipResource.Name -IPAddress $IPAddress -AddressMask $AddressMask

    $ipResources = Get-ClusterIPResource -OwnerGroup $clusterObj.ownerGroup

    $dependencyExpression = New-ClusterIPDependencyExpression -ClusterResource $ipResources.Name

    #Set cluster resources
    $params = @{
        Resource    = $($clusterObj.Name)
        Dependency  = $dependencyExpression
        ErrorAction = 'Stop'
    }
    Write-Verbose -Message ($script:localizedData.SetDependencyExpression -f $dependencyExpression)
    Set-ClusterResourceDependency @params

}


<#
    .Synopsis
        Removes an IPAddress as a Dependency to a Windows Cluster
    .DESCRIPTION
        Removes an IP Address resource to a Windows Cluster's Dependecy Expression
    .PARAMETER IPAddress
        IP address to remove to the Cluster's DependencyExpression
    .PARAMETER AddressMask
        The subnet mask of the IPAddress
    .EXAMPLE
        Remove-ClusterIPAddressDependency -IPAddress 10.235.32.137 -AddressMask 255.255.255.128 -Verbose
#>
function Remove-ClusterIPAddressDependency
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    #* Get Windows Cluster resource
    $clusterObj = Get-ClusterObject

    $ipResource = Get-ClusterIPResourceFromIPAddress -IPAddress $IPAddress

    Remove-ClusterResource -InputObject $ipResource -Force

    # Write new dependency expression
    $ipResources = Get-ClusterIPResource -OwnerGroup $clusterObj.OwnerGroup

    $dependencyExpression = New-ClusterIPDependencyExpression -ClusterResource $ipResources.Name
    $params = @{
        Resource    = $($clusterObj.Name)
        Dependency  = $dependencyExpression
        ErrorAction = 'Stop'
    }
    Write-Verbose -Message ($script:localizedData.SetDependencyExpression -f $dependencyExpression)
    Set-ClusterResourceDependency @params
}

<#
    .Synopsis
        Tests whether a given IPAddress is part of the Cluster's DependencyExpression
    .PARAMETER IPAddress
        IP address to check whether it's in the Cluster's DependencyExpression
    .EXAMPLE
        Example using complete IPAddress and AddressMask default ParameterSet
        Test-ClusterIPAddressDependency -IPAddress 10.235.0.141 -AddressMask 255.255.255.128 -verbose
    .EXAMPLE
        Example using IPAddress from default ParameterSet
        Test-ClusterIPAddressDependency -IPAddress 10.235.0.141 -verbose
#>
function Test-ClusterIPAddressDependency
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    Test-IPAddress -IPAddress $IPAddress

    $dependencyExpression = Get-ClusterResourceDependencyExpression

    Write-Verbose -Message ($script:localizedData.TestDependencyExpression -f $IPAddress, $dependencyExpression)
    if ( $dependencyExpression -match $IPAddress )
    {
        Write-Verbose -Message ($script:localizedData.SuccessfulTestDependencyExpression -f $IPAddress, $dependencyExpression)
        return $True
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.FailedTestDependencyExpression -f $IPAddress, $dependencyExpression)
        return $False
    }
}

<#
    .Synopsis
        Checks whether the ClusterNetwork for a given IPAddress has been added to a Cluster
    .DESCRIPTION
        Given an IPAddress and AddressMask this cmdlet will check if the correct ClusterNetwork has
        been added to the cluster.
    .PARAMETER IPAddress
        IP address to check whether it's subnet is a cluster network already
    .PARAMETER AddressMask
        The subnet mask of the IPAddress
    .EXAMPLE
    Test-ClusterNetwork -IPAddress 10.245.10.32 -AddressMask 255.255.255.0
#>
function Test-ClusterNetwork
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    $clusterNetworks = Get-ClusterNetworkList
    Write-Verbose -Message ($script:localizedData.GetSubnetfromIPAddressandAddressMask -f $IPAddress, $AddressMask)
    $subnet = $(Get-Subnet -IPAddress $IPAddress -AddressMask $AddressMask -ErrorAction Stop)

    foreach ( $network in $clusterNetworks )
    {
        if (( $network.Address -eq $subnet ) -and
            ( $network.AddressMask -eq $AddressMask ))
        {
            Write-Verbose -Message ($script:localizedData.NetworkAlreadyInCluster -f $($network.address), $IPAddress, $subnet)
            return $True
        }
    }

    return $false
}

<#
    .SYNOPSIS
        Returns a list of PSCustomObjects representing the network and subnet mask of all networks in the cluster.
#>
function Get-ClusterNetworkList
{
    [CmdletBinding()]
    param
    (

    )

    Write-Verbose -Message ($script:localizedData.GetClusterNetworks)
    $networks = New-Object -TypeName "System.Collections.Generic.List[PSCustomObject]"
    foreach ( $network in Get-ClusterNetwork )
    {
        $networks.Add([PSCustomObject]@{
            Address     = $network.Address
            AddressMask = $network.AddressMask
        })
        Write-Verbose -Message ($script:localizedData.FoundClusterNetwork -f $($network.Address), $($network.AddressMask))
    }

    return $networks
}

<#
    .SYNOPSIS
        Returns the cluster Dependency expression for a given cluster.
#>
function Get-ClusterResourceDependencyExpression
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
    )

    Write-Verbose -Message ($script:localizedData.GetClusterResourceExpression)
    $cluster = Get-ClusterResource | Where-Object {$_.name -eq 'Cluster Name'}
    $dependencyExpression = (Get-ClusterResourceDependency -Resource $cluster.Name).DependencyExpression
    Write-Verbose -Message ($script:localizedData.EchoDependencyExpression -f $dependencyExpression)
    return $dependencyExpression
}

<#
    .Synopsis
        Adds an IP Address Resource to a given Cluster Group and returns an IPAddress Resource
    .PARAMETER IPAddress
        IP address to check whether it's subnet is a cluster network already
    .PARAMETER OwnerGroup
        OwnerGroup of the cluster to add the IP resource to
#>
function Add-ClusterIPResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        # Owner Group of the cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $OwnerGroup
    )

    Test-IPAddress -IPAddress $IPAddress

    #* Create new IPAddress resource and add the IPAddress parameters to it
    Write-Verbose -Message ($script:localizedData.CreateNewIPResource -f $IPAddress, $OwnerGroup)
    $resourceName = "IP Address $IPAddress"
    $params = @{
        Name         = $resourceName
        ResourceType = 'IP Address'
        Group        = $OwnerGroup
        ErrorAction  = 'Stop'
    }
    $resource = Add-ClusterResource @params

    return $resourceName
}

<#
    .Synopsis
        Gets all IP Resources added to the cluster
    .PARAMETER OwnerGroup
        OwnerGroup of the cluster to get the IP resources from
#>
function Get-ClusterIPResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        # Owner Group of the cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $OwnerGroup
    )

    $ipResources = Get-ClusterResource | Where-Object {
        ( $_.OwnerGroup -eq $OwnerGroup ) -and
        ( $_.ResourceType -eq 'IP Address' )
    }

    return $ipResources
}

<#
    .Synopsis
        Gets the IP resource information of a Given Cluster IP address Resource
    .PARAMETER IPAddressResource
        IP cddress resource to get to information from
#>
function Get-ClusterIPResourceParameters
{
    [CmdletBinding()]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddressResourceName
    )

    $ipObj = Get-ClusterResource -Name $IPAddressResourceName

    $address = (Get-ClusterParameter -InputObject $ipObj -Name Address).Value
    $addressMask = (Get-ClusterParameter -InputObject $ipObj -Name SubnetMask).Value
    $network =  (Get-ClusterParameter -InputObject $ipObj -Name Network).Value
    Write-Verbose -Message ($script:localizedData.FoundIPAddressResource -f $address, $addressMask, $network)
    @{
        Address     = $address
        AddressMask = $addressMask
        Network     = $network
    }
}

<#
    .Synopsis
        Adds an IP address resource to cluster parameter
    .PARAMETER IPAddressResource
        IP cddress resource to add to the cluster parameter
    .PARAMETER IPAddress
        IP address to add to the cluster parameter
    .PARAMETER AddressMask
        Address mask of the IP address
#>
function Add-ClusterIPParameter
{
    [CmdletBinding()]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddressResourceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    $ipAddressResource = Get-ClusterResource -Name $IPAddressResourceName

    $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $iPAddressResource,Address,$IPAddress
    $parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $iPAddressResource,SubnetMask,$AddressMask
    $parameterList = $parameter1,$parameter2

    Write-Verbose -Message ($script:localizedData.AddIPAddressResource -f $IPAddress,$AddressMask)
    $parameterList | Set-ClusterParameter -ErrorAction Stop

}

<#
    .Synopsis
        Removes an IP address to the cluster parameter
    .PARAMETER IPAddressResource
        IP cddress resource to remove to the cluster parameter
    .PARAMETER IPAddress
        IP address to remove to the cluster parameter
    .PARAMETER AddressMask
        Address mask of the IP address
#>
function Remove-ClusterIPParameter
{
    [CmdletBinding()]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddressResourceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    $ipAddressResource = Get-ClusterResource -Name $IPAddressResourceName

    $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $iPAddressResource,Address,$IPAddress
    $parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $iPAddressResource,SubnetMask,$AddressMask
    $parameterList = $parameter1,$parameter2

    #* Add the IP Address resource to the cluster

    Write-Verbose -Message ($script:localizedData.RemoveIPAddressResource -f $IPAddress,$AddressMask)
    Set-ClusterParameter -InputObject $parameterList -Delete -ErrorAction Stop

}

<#
    .Synopsis
        Validates a given IP address
    .PARAMETER IPAddress
        IP address to validate
#>
function Test-IPAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    $ipObject = [System.Net.IPAddress]::Parse($IPAddress)
}


<#
    .Synopsis
        Creates a new cluster IP Dependency
    .PARAMETER ClusterResource
        Cluster resources to create IP Dependency from
#>
function New-ClusterIPDependencyExpression
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ClusterResource
    )

    if ($ClusterResource.count -eq 1)
    {
        $dependencyExpression = "[$ClusterResource]"
    }

    else
    {
        $dependencyExpression = ''
        $clusterResourceCount = $ClusterResource.count - 1
        $i = 0
        while ( $i -le $clusterResourceCount )
        {
            if ( $i -eq $clusterResourceCount )
        {
            $dependencyExpression += "[$($ClusterResource[$i])]"
        }
        else
        {
            $dependencyExpression += "[$($ClusterResource[$i])] or "
        }
        $i++
        }
    }
    Write-Verbose -Message ($script:localizedData.NewDependencyExpression -f $dependencyExpression)
    return $dependencyExpression
}

<#
    .Synopsis
        Returns an object representing the cluster
#>
function Get-ClusterObject
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
    )

    $cluster = Get-ClusterResource | Where-Object { $_.name -eq 'Cluster Name'}

    return $cluster
}

<#
    .Synopsis
        Gets a Cluster Resource from a given IP address.

    .Parameter IPAddress
        IP address of the cluster resource object to find.
#>
function Get-ClusterIPResourceFromIPAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IPAddress
    )

    $result = $null

    Test-IPAddress -IPAddress $IPAddress

    $clusterObj = Get-ClusterObject

    $ipResources = Get-ClusterIPResource -OwnerGroup $clusterObj.ownerGroup

    foreach ( $ipResource in $ipResources )
    {
        $resource = Get-ClusterIPResourceParameters -IPAddressResourceName $ipResource.name

        if ($resource.Address -eq $IPAddress)
        {
            $result = Get-ClusterResource $resource.name
        }
    }

    return $result
}
