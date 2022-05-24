$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
Function Get-TargetResource
{
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory = $true)]
        [ipaddress]
        $Address,

        [Parameter(Mandatory = $true)]
        [ipaddress]
        $AddressMask

    )

    return Get-ClusterNetworkList

}

Function Set-TargetResource
{
    Param
    (

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',

        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $SubnetMask
    )

    if ($Ensure -eq 'Present')
    {
        # We've gotten here because the IPAddress given is not in the DependencyExpression for the cluster
        # We need to Check if the network is added to the cluster. If not, we fail. If it is, we can append the IPAddress
        if ( -not $(Test-ClusterNetwork -IPAddress $IPAddress -SubnetMask $SubnetMask) )
        {
            Write-Error "$f ClusterNetwork for IPAddress $IPAddress and subnet mask $SubnetMask is not part of this Cluster"
            break
        }
        else
        {
            $params = @{
                IPAddress   = $IPAddress
                SubnetMask  = $SubnetMask
                ErrorAction = 'Stop'
            }
            Add-ClusterIPAddressDependency @params

        }
    }
    else
    {
        if (Test-ClusterIPAddressDependency -IPAddress $IPAddress -SubnetMask $SubnetMask) {
            Remove-ClusterIPAddressDependency -IPAddress $IPAddress -Subnet $SubnetMask
        }
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (

        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',

        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        [IPAddress]
        $SubnetMask
    )

    # If IPAddress is not in ClusterResource DependencyExpression #fail
    # If IPAddress' Subnet is not in ClusterNetworks #fail
    $params = @{
      IPAddress  = $IPAddress
      SubnetMask = $SubnetMask
      VerbosePreference = $VerbosePreference
    }
    $testResult = Test-ClusterIPAddressDependency @params

    if ($Ensure -eq 'Present')
    {
        if ($testResult)
        {
            return $True
        }
        else
        {
            return $False
        }
    }
    else
    {
        if ($testResult)
        {
            return $False
        }
        else
        {
            return $True
        }
    }
}


<#
    .Synopsis
        Given an IP Address and a Subnet Mask, returns the IP Addresses subnet.
    .DESCRIPTION
        Returns an IPAddress object of the subnet mask of the given IPAddress and Subnet.
    .PARAMETER IPAddress
        IP address to add to the Cluster's DependencyExpression
    .PARAMETER SubnetMask
        The subnet mask of the IPAddress
    .EXAMPLE
        Get-Subnet -IPAddress 10.235.32.129 -SubnetMask 255.255.255.128
#>
function Get-Subnet
{
    [CmdletBinding()]
    [OutputType([IpAddress])]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        [IPAddress]
        $SubnetMask
    )

    return [IPAddress]($Ipaddress.Address -band $SubnetMask.Address)
}

<#
    .Synopsis
        Adds an IPAddress as a Dependency to a Windows Cluster
    .DESCRIPTION
        Adds an IP Address resource to a Windows Cluster's Dependecy Expression
    .PARAMETER IPAddress
        IP address to add to the Cluster's DependencyExpression
    .PARAMETER SubnetMask
        The subnet mask of the IPAddress
    .PARAMETER ClusterName
        Name of the cluster to add IP Address resource to
    .EXAMPLE
        # Using the default ParameterSet of both IP Address and Subnet
        Add-ClusterIPAddressDependency -IPAddress 10.235.32.137 -Subnet 255.255.255.128 -Verbose
    .EXAMPLE
        # Using the Combined ParameterSet
        Add-ClusterIPAddressDependency -IPandSubnet 10.235.32.137/255.255.255.128 -Verbose
#>
function Add-ClusterIPAddressDependency
{
    [CmdletBinding()]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        [IPAddress]
        $SubnetMask,

        [String]
        $ClusterName = 'Cluster Name'
    )


    #* Get Windows Cluster resource
    $cluster = Get-ClusterResource | Where-Object { $_.name -eq $ClusterName}

    #* Create new IPAddress resource and add the IPAddress parameters to it
    Write-Verbose -Message ($script:localizedData.CreateNewIPResource -f $IPAddress,$SubnetMask)
    $params = @{
        Name         = "IP Address $IPAddress"
        ResourceType = "IP Address"
        Group        = $($cluster.OwnerGroup)
    }
    $ipResource = Add-ClusterResource @params
    $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $ipResource,Address,$ipAddress
    $parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $ipResource,SubnetMask,$subnetMask
    $parameterList = $parameter1,$parameter2

    #* Add the IP Address resource to the cluster
    Try
    {
        Write-Verbose -Message ($script:localizedData.AddIPAddressResource)
        $parameterList | Set-ClusterParameter -ErrorAction Stop
    }
    Catch
    {
        #TODO Add error handling here for failure. Most likely reasons are
        #* IP Address already exists (does this check actually IP Address or just IP Address Name)
        #* IP Address network has yet to be added to the Cluster
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }

    $ipResources = Get-ClusterResource | Where-Object
    {
        ( $_.OwnerGroup -eq $cluster.OwnerGroup ) -and
        ( $_.ResourceType -eq 'IP Address' )
    }

    $dependencyExpression = ''
    $ipResourceCount = $ipResources.count
    $i = 0
    while ( $i -lt $ipResourceCount )
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
    Try {
        $params = @{
        Resource    = $($cluster.Name)
        Dependency  = $dependencyExpression
        ErrorAction = 'Stop'
        }
        Write-Verbose -Message ($script:localizedData.SetDependencyExpression -f $dependencyExpression)
        Set-ClusterResourceDependency @params
    } Catch {
        #TODO error handling for when adding the depenencies list fails
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
}

<#
    .Synopsis
        Tests whether a given IPAddress is part of the Cluster's DependencyExpression
    .PARAMETER IPAddress
        IP address to check whether it's in the Cluster's DependencyExpression
    .PARAMETER SubnetMask
        The subnet mask of the IPAddress
    .PARAMETER IPandSubnet
        Combined IP address and subnet mask in the format 10.245.10.32/255.255.255.0
    .EXAMPLE
        Example using complete IPAddress and Subnetmask default ParameterSet
        Test-ClusterIPAddressDependency -IPAddress 10.235.0.141 -SubnetMask 255.255.255.128 -verbose
    .EXAMPLE
        Example using IPAddress from default ParameterSet
        Test-ClusterIPAddressDependency -IPAddress 10.235.0.141 -verbose
    .EXAMPLE
        Example using Combined ParameterSet
        Test-ClusterIPAddressDependency -IPandSubnet 10.235.0.141/255.255.255.128 -verbose
#>
function Test-ClusterIPAddressDependency
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [IPAddress]
        $IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        [IPAddress]
        $SubnetMask
    )

    $dependencyExpression = Get-ClusterResourceDependencyExpression

    Write-Verbose -Message ($script:localizedData.TestDependencyExpression -f $IPAddress, $dependencyExpression)
    If ( $dependencyExpression -match $IPAddress )
    {
        Write-Verbose -Message ($script:localizedData.SuccessfulTestDependencyExpression -f $IPAddress, $dependencyExpression
        return $True
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.FailedTestDependencyExpression -f $IPAddress, $dependencyExpression
        return $False
    }
}

<#
    .Synopsis
        Checks whether the ClusterNetwork for a given IPAddress has been added to a Cluster
    .DESCRIPTION
        Given an IPAddress and SubnetMask this cmdlet will check if the correct ClusterNetwork has
        been added to the cluster.
    .PARAMETER IPAddress
        IP address to check whether it's subnet is a cluster network already
    .PARAMETER SubnetMask
        The subnet mask of the IPAddress
    .EXAMPLE
    Test-ClusterNetwork -IPAddress 10.245.10.32 -SubnetMask 255.255.255.0
#>
function Test-ClusterNetwork
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [IPAddress]$IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [IPAddress]$SubnetMask
    )

    $clusterNetworks = Get-ClusterNetworkList
    Write-Verbose -Message ($script:localizedData.GetSubnetfromIPAddressandSubnetMask -f $IPAddress, $SubnetMask)
    $subnet = $(Get-Subnet -IPAddress $IPAddress -SubnetMask $SubnetMask -Verbose -ErrorAction Stop)
    Write-Verbose -Message ($script:localizedData.FoundSubnetfromIPAddressandSubnetMask -f $IPAddress, $SubnetMask, $Subnet)

    foreach ( $network in $clusterNetworks )
    {
        if (( $network.Address -eq $subnet.IPAddressToString ) -and
            ( $network.AddressMask -eq $SubnetMask.IPAddressToString ))
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
function Get-ClusterNetworkList {
    [CmdletBinding()]
    [Alias()]
    Param
    ()

    Write-Verbose -Message ($script:localizedData.GetClusterNetworks)
    $networks = New-Object "System.Collections.Generic.List[PSCustomObject]"
    Foreach ( $network in Get-ClusterNetwork )
    {
        $clusterNetworks.Add([PSCustomObject]@{
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
function Get-ClusterResourceDependencyExpression {
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [String]$ClusterName = 'Cluster Name'
    )

    Try
    {
        Write-Verbose -Message ($script:localizedData.GetClusterResourceExpression)
        $cluster = Get-ClusterResource | Where-Object {$_.name -eq $ClusterName}
        return $(Get-ClusterResourceDependency -Resource $cluster.Name).DependencyExpression
    }
    Catch
    {
        New-InvalidOperationException -Message $_.Exception.Message -ErrorRecord $_
    }
}
