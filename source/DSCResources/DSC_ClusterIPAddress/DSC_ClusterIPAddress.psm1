$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
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
    $result = @{}
    $ipResources = Get-ClusterResource | Where-Object {$_.ResourceType -eq 'IP Address'}

    foreach ( $ipResource in $ipResources )
    {
        $ipResourceDetails = Get-ClusterIPResource -IPAddressResource $ipResource

        if ( $ipResourceDetails.Address -eq $IPAddress )
        {
            Write-Verbose -Message ($script:localizedData.FoundIPResource -f $IPAddress)
            $result = @{
                IPAddress   = $ipResourceDetails.Address
                AddressMask = $ipResourceDetails.AddressMask
                Ensure      = $Ensure
            }
        }
    }
    $result
}

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
            New-InvalidArgumentException -Message ($script:localizedData.NonExistantClusterNetwork -f $IPAddress,$AddressMask)
            break
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
    # # If IPAddress is not in ClusterResource DependencyExpression #fail
    # # If IPAddress' Subnet is not in ClusterNetworks #fail
    # $testResult = Test-ClusterIPAddressDependency -IPAddress $IPAddress
    # $testTargetResourceReturnValue = $false

    $ipResource = Get-TargetResource -IPAddress $IPAddress -AddressMask $AddressMask
    $result = $false

    if ($Ensure -eq 'Present')
    {
        if (-not ([System.String]::IsNullOrEmpty($ipResource)))
        {
            if ( ($ipResource.IPAddress -eq $IPAddress) -and
                ($ipResource.AddressMask -eq $AddressMask) )
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
    [OutputType([IPAddress])]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $AddressMask
    )

    return [IPAddress]($Ipaddress.Address -band $AddressMask.Address)
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
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [IPAddress]
        $AddressMask,

        [Parameter()]
        [System.String]
        $ClusterName = 'Cluster Name'
    )

    #* Get Windows Cluster resource
    $cluster = Get-ClusterResource | Where-Object { $_.name -eq $ClusterName}

    $ipResourceName = Add-ClusterIPResource -IPAddress $IPAddress -OwnerGroup $cluster.OwnerGroup
    $ipResource = Get-ClusterResource -Name $ipResourceName
    Add-ClusterIPParameter -IPAddressResource $ipResource -IPAddress $IPAddress -AddressMask $AddressMask

    $ipResources = Get-ClusterResource | Where-Object {
        ( $_.OwnerGroup -eq $cluster.OwnerGroup ) -and
        ( $_.ResourceType -eq 'IP Address' )
    }

    #! Need to write
    #$dependencyExpression = New-ClusterDependencyExpression -IpAddressResource $ipResources
    $dependencyExpression = ''
    $ipResourceCount = $ipResources.count -1
    $i = 0
    while ( $i -le $ipResourceCount )
    {
        if ( $i -eq $ipResourceCount )
        {
            $dependencyExpression += "[$($ipResources[$i].name)]"
        }
        else
        {
            $dependencyExpression += "[$($ipResources[$i].name)] or "
        }
        $i++
    }

    #Set cluster resources
    try
    {
        $params = @{
            Resource    = $($cluster.Name)
            Dependency  = $dependencyExpression
            ErrorAction = 'Stop'
        }
        Write-Verbose -Message ($script:localizedData.SetDependencyExpression -f $dependencyExpression)
        Set-ClusterResourceDependency @params
    }
    catch
    {
        #TODO error handling for when adding the depenencies list fails
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
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
    .PARAMETER ClusterName
        Name of the cluster to add IP Address resource to
    .EXAMPLE
        Remove-ClusterIPAddressDependency -IPAddress 10.235.32.137 -AddressMask 255.255.255.128 -Verbose
#>
function Remove-ClusterIPAddressDependency
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [IPAddress]
        $AddressMask,

        [Parameter()]
        [System.String]
        $ClusterName = 'Cluster Name'
    )

    #* Get Windows Cluster resource
    $cluster = Get-ClusterResource | Where-Object { $_.name -eq $ClusterName}

    try
    {
        #! this probably does not stop, but returns null or empty
        $ipResource = Get-ClusterResource -Name "IP Address $IPAddress" -errorAction Stop
    }
    catch
    {
        #! Here we need to check if IP Address is original IP Resource named: 'Cluster IP Address'
        $errorMessage = $script:localizedData.IPResourceNotFound -f "IP Address $IPAddress"
        New-InvalidDataException -Message $errorMessage -ErrorID 'IPResourceNotFound'
    }
    Remove-ClusterIPResource -IPAddress $IPAddress -OwnerGroup $cluster.OwnerGroup
    #* I dont think below is necessary. Removing the resource will remove the IP
    #Remove-ClusterIPParameter -IPAddressResource $ipResource -IPAddress $IPAddress -AddressMask $AddressMask

    $ipResources = Get-ClusterResource | Where-Object
    {
        ( $_.OwnerGroup -eq $cluster.OwnerGroup ) -and
        ( $_.ResourceType -eq 'IP Address' )
    }

    #! Need to write
    #$dependencyExpression = New-ClusterDependencyExpression -IpAddressResource $ipResources
    $dependencyExpression = ''
    $ipResourceCount = $ipResources.count -1
    $i = 0
    while ( $i -le $ipResourceCount )
    {
        if ( $i -eq $ipResourceCount )
        {
            $dependencyExpression += "[$($ipResources[$i].name)]"
        }
        else
        {
            $dependencyExpression += "[$($ipResources[$i].name)] or "
        }
        $i++
    }

    #Set cluster resources
    try
    {
        $params = @{
            Resource    = $($cluster.Name)
            Dependency  = $dependencyExpression
            ErrorAction = 'Stop'
        }
        Write-Verbose -Message ($script:localizedData.SetDependencyExpression -f $dependencyExpression)
        Set-ClusterResourceDependency @params
    }
    catch
    {
        #TODO error handling for when adding the depenencies list fails
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
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
        [IPAddress]
        $IPAddress
    )

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
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $AddressMask
    )

    $clusterNetworks = Get-ClusterNetworkList
    Write-Verbose -Message ($script:localizedData.GetSubnetfromIPAddressandAddressMask -f $IPAddress, $AddressMask)
    $subnet = $(Get-Subnet -IPAddress $IPAddress -AddressMask $AddressMask -ErrorAction Stop)
    Write-Verbose -Message ($script:localizedData.FoundSubnetfromIPAddressandAddressMask -f $IPAddress, $AddressMask, $Subnet)

    foreach ( $network in $clusterNetworks )
    {
        if (( $network.Address -eq $subnet.IPAddressToString ) -and
            ( $network.AddressMask -eq $AddressMask.IPAddressToString ))
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
    $networks = New-Object "System.Collections.Generic.List[PSCustomObject]"
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
    .PARAMETER ClusterName
        The name of the cluster to get the Dependency expression
#>
function Get-ClusterResourceDependencyExpression
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [String]
        $ClusterName = 'Cluster Name'
    )

    try
    {
        Write-Verbose -Message ($script:localizedData.GetClusterResourceExpression)
        $cluster = Get-ClusterResource | Where-Object {$_.name -eq $ClusterName}
        return $(Get-ClusterResourceDependency -Resource $cluster.Name).DependencyExpression
    }
    catch
    {
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
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

    try
    {
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
    }
    catch
    {
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }

    return $resourceName
}

<#
    .Synopsis
        Removes an IP Address Resource to a given Cluster Group and returns an IPAddress Resource
    .PARAMETER IPAddress
        IP address to remove from the cluster
    .PARAMETER OwnerGroup
        OwnerGroup of the cluster to remove the IP resource from
#>
function Remove-ClusterIPResource
{
    [CmdletBinding()]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        # Owner Group of the cluster
        [Parameter(Mandatory = $true)]
        [System.String]
        $OwnerGroup
    )

    try
    {
        #* Create new IPAddress resource and add the IPAddress parameters to it
        Write-Verbose -Message ($script:localizedData.RemoveIPResource -f $IPAddress)
        $params = @{
            Name         = "IP Address $IPAddress"
            ResourceType = 'IP Address'
            Group        = $OwnerGroup
            ErrorAction  = 'Stop'
            Confirm      = $False
        }
        Remove-ClusterResource @params
    }
    catch
    {
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
}

<#
    .Synopsis
        Gets the IP resource information of a Given Cluster IP address Resource
    .PARAMETER IPAddressResource
        IP cddress resource to get to information from
#>
function Get-ClusterIPResource
{
    [CmdletBinding()]
    param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [Microsoft.FailoverClusters.PowerShell.ClusterResource]
        $IPAddressResource
    )

    $address = ($IPAddressResource | Get-ClusterParameter -Name Address).Value
    $addressMask = ($IPAddressResource | Get-ClusterParameter -Name SubnetMask).Value
    $network = ($IPAddressResource | Get-ClusterParameter -Name Network).Value
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
        [Microsoft.FailoverClusters.PowerShell.ClusterResource]
        $IPAddressResource,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AddressMask
    )

    Test-IPAddress -IPAddress $IPAddress
    Test-IPAddress -IPAddress $AddressMask

    $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPAddressResource,Address,$IPAddress
    $parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPAddressResource,SubnetMask,$AddressMask
    $parameterList = $parameter1,$parameter2

    #* Add the IP Address resource to the cluster
    try
    {
        Write-Verbose -Message ($script:localizedData.AddIPAddressResource -f $IPAddress,$AddressMask)
        $parameterList | Set-ClusterParameter -ErrorAction Stop
    }
    catch
    {
        #TODO Add error handling here for failure. Most likely reasons are
        #* IP Address already exists (does this check actually IP Address or just IP Address Name)
        #* IP Address network has yet to be added to the Cluster
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
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
        [Microsoft.FailoverClusters.PowerShell.ClusterResource]
        $IPAddressResource,

        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [IPAddress]
        $AddressMask
    )

    $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPAddressResource,Address,$IPAddress
    $parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPAddressResource,SubnetMask,$AddressMask
    $parameterList = $parameter1,$parameter2

    #* Add the IP Address resource to the cluster
    try
    {
        Write-Verbose -Message ($script:localizedData.RemoveIPAddressResource -f $IPAddress,$AddressMask)
        $parameterList | Set-ClusterParameter -Delete -ErrorAction Stop
    }
    catch
    {
        #TODO Add error handling here for failure. Most likely reasons are
        #* IP Address already exists (does this check actually IP Address or just IP Address Name)
        #* IP Address network has yet to be added to the Cluster
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
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

    try
    {
        $ipObject = [System.Net.IPAddress]::Parse($IPAddress)
    }
    catch
    {
        #TODO Add error handling here for failure. Most likely reasons are
        #* IP Address already exists (does this check actually IP Address or just IP Address Name)
        #* IP Address network has yet to be added to the Cluster
        $message = $script:localizedData.InvalidIPAddress -f $IPAddress
        New-InvalidArgumentException -Message $message -Argument "IPAddress"
    }
}
