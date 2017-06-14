#
# MSFT_xClusterPreferredOwner: DSC resource to configure the Windows Failover Cluster Preferred Owner.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ClusterGroup,

        [parameter(Mandatory = $true)]
        [string]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Nodes,

        [Parameter()]
        [string[]]
        $ClusterResources,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Retrieving Owner information for cluster $ClusterName..."

    $ownerNodes = @(

        Write-Verbose -Message "Retrieving Owner information for Cluster Group $ClusterGroup"
        (((Get-ClusterGroup -Cluster $ClusterName) | Where-Object -FilterScript {$_.Name -like "$ClusterGroup"} | Get-ClusterOwnerNode).OwnerNodes).Name

        if ($ClusterResources)
        {
            foreach ($resource in $ClusterResources)
            {
                Write-Verbose -Message "Retrieving Owner information for Cluster Resource $resource"
                (((Get-ClusterResource -Cluster $ClusterName) | Where-Object -FilterScript {$_.Name -like "$resource"} | Get-ClusterOwnerNode).OwnerNodes).Name
            }
        }
    )

    $ownerNodes = $ownerNodes | Select-Object -Unique

    $returnValue = @{
        ClusterGroup = $ClusterGroup
        Clustername = $ClusterName
        Nodes = $ownerNodes
        ClusterResources = $ClusterResources
        Ensure = $Ensure
    }

    $returnValue
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ClusterGroup,

        [Parameter(Mandatory = $true)]
        [string]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Nodes,

        [Parameter()]
        [string[]]
        $ClusterResources,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Retrieving all owners from cluster $ClusterName"
    $allNodes = (Get-ClusterNode -Cluster $ClusterName).Name

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message "Setting Cluster owners for Group $ClusterGroup to $Nodes"
        $null = (Get-ClusterGroup -Cluster $ClusterName) | Where-Object -FilterScript {$_.Name -like $ClusterGroup} | Set-ClusterOwnerNode -Owners $Nodes
        $null = (Get-ClusterResource) | Where-Object {$_.OwnerGroup -like $ClusterGroup} | Set-ClusterOwnerNode -Owners $allNodes

        Write-Verbose -Message "Moving Cluster Group $ClusterGroup to node $($Nodes[0])"
        $null = (Get-ClusterGroup -Cluster $ClusterName) | Where-Object -FilterScript {$_.name -like $ClusterGroup} | Move-ClusterGroup -Node $Nodes[0]

        foreach ($resource in $ClusterResources)
        {
            Write-Verbose -Message "Setting Cluster owners for Resource $resource to $Nodes"
            $null = (Get-ClusterResource -Cluster $ClusterName)| Where-Object -FilterScript {$_.Name -like "$resource"} | Set-ClusterOwnerNode -Owners $Nodes
        }
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Retrieving current cluster owners for group $ClusterGroup"
        $currentOwners = (((Get-ClusterGroup -Cluster $ClusterName)| Where-Object -FilterScript {$_.Name -like "$ClusterGroup"} | Get-ClusterOwnerNode).OwnerNodes).Name | Sort-Object -Unique
        $newOwners = @(
            foreach ($currentOwner in $currentOwners)
            {
                if ($Nodes -notcontains $currentOwner)
                {
                    $currentOwner
                }
            }
        )
        Write-Verbose -Message "Removing owners from group $($ClusterGroup): $Nodes"
        $null = (Get-ClusterGroup -Cluster $ClusterName)| Where-Object -FilterScript {$_.Name -like $ClusterGroup} | Set-ClusterOwnerNode $newOwners

        Write-Verbose -Message "Setting Cluster owners for Group $ClusterGroup to $newOwners"
        $null = (Get-ClusterResource)| Where-Object -FilterScript {$_.OwnerGroup -like $ClusterGroup} | Set-ClusterOwnerNode $allNodes

        Write-Verbose -Message "Moving Cluster Group $ClusterGroup to node $($newOwners[0])"
        $null = (Get-ClusterGroup -Cluster $ClusterName)| Where-Object -FilterScript {$_.Name -like $ClusterGroup} | Move-ClusterGroup -Node $newOwners[0]

        foreach ($resource in $ClusterResources)
        {
            Write-Verbose -Message "Retrieving current clusterowners for resource $resource"
            $currentOwners = ((Get-ClusterResource -Cluster $ClusterName | Where-Object -FilterScript {$_.Name -like "$resource"} | Get-ClusterOwnerNode).OwnerNodes).Name | Sort-Object -Unique
            $newOwners = @(
                foreach ($currentOwner in $currentOwners)
                {
                    if ($Nodes -notcontains $currentOwner)
                    {
                        $currentOwner
                    }
                }
            )
            Write-Verbose -Message "Setting Cluster owners for Resource $resource to $newOwners"
            $null = Get-ClusterResource -Cluster $ClusterName | Where-Object -FilterScript {$_.Name -like "$resource"} | Set-ClusterOwnerNode -Owners $newOwners
        }
    }
}

#
# Test-TargetResource
#

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ClusterGroup,

        [Parameter(Mandatory = $true)]
        [string]
        $ClusterName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Nodes,

        [Parameter()]
        [string[]]
        $ClusterResources,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Testing Owner information for cluster $ClusterName..."

    $getTargetResourceResult = (Get-TargetResource @PSBoundParameters).Nodes
    $result = $true

    if ($Ensure -eq 'Present')
    {
        foreach ($object in $getTargetResourceResult)
        {
            if ($Nodes -notcontains $object)
            {
                Write-Verbose -Message "$object was NOT found as possible owner"
                $result = $false
            }
        }

        foreach ($object in $Nodes)
        {
            if ($getTargetResourceResult -notcontains $object)
            {
                Write-Verbose -Message "$object was NOT found as possible owner"
                $result = $false
            }
        }
    }

    if ($Ensure -eq 'Absent')
    {
        foreach ($object in $getTargetResourceResult)
        {
            if ($Nodes -contains $object)
            {
                Write-Verbose -Message "$object WAS found as possible owner"
                $result = $false
            }
        }

        foreach ($object in $Nodes)
        {
            if ($getTargetResourceResult -contains $object)
            {
                Write-Verbose -Message "$object WAS found as possible owner"
                $result = $false
            }
        }
    }

    $result
}
