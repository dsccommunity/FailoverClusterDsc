#
# cClusterPreferredOwner: DSC resource to configure the Windows Failover Cluster Preferred Owner.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string[]]
        $ClusterGroup,

        [parameter(Mandatory)]
        [string]
        $Clustername,

        [parameter(Mandatory)]
        [string[]]
        $Nodes,

        [string[]]
        $ClusterResources,

        [ValidateSet('Present', 'Absent')]
		[String]
		$Ensure = 'Present'
    )
    
    Write-Verbose -Message "Retrieving Owner information for cluster $Clustername..."

    $ownernodes = @(
        
        Write-Verbose -Message "Retrieving Owner information for Cluster Group $ClusterGroup"
        (((Get-Cluster $Clustername | Get-ClusterGroup | Where-Object {$_.name -like "$ClusterGroup"}) | Get-ClusterOwnerNode).ownernodes).name

        if ($ClusterResources)
        {
            foreach ($resource in $ClusterResources)
            {
                Write-Verbose -Message "Retrieving Owner information for Cluster Resource $resource"
                (((Get-Cluster $Clustername | get-ClusterResource | Where-Object {$_.name -like "$resource"}) | Get-ClusterOwnerNode).ownernodes).name
            }
        }
    )
    $ownernodes | Select-Object -Unique
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string[]]
        $ClusterGroup,

        [parameter(Mandatory)]
        [string]
        $Clustername,

        [parameter(Mandatory)]
        [string[]]
        $Nodes,

        [string[]]
        $ClusterResources,

        [ValidateSet('Present', 'Absent')]
		[String]
		$Ensure = 'Present'
    )

    Write-Verbose -Message "Retrieving all owners from cluster $Clustername"
    $allnodes = (Get-Cluster $ClusterName | Get-ClusterNode).name

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message "Setting Cluster owners for Group $ClusterGroup to $nodes" -Verbose
        Get-Cluster $ClusterName  | Get-ClusterGroup | Where-Object {$_.name -like $ClusterGroup} | Set-ClusterOwnerNode $Nodes
        Get-Cluster $ClusterName  | Get-ClusterGroup | Where-Object {$_.name -like $ClusterGroup} | Get-ClusterResource | Set-ClusterOwnerNode $allnodes
        Write-Verbose -Message "Moving Cluster Group $ClusterGroup to node $($nodes[0])" -Verbose
        Get-Cluster $ClusterName  | Get-ClusterGroup | Where-Object {$_.name -like $ClusterGroup} | Move-ClusterGroup -Node $Nodes[0]
        foreach ($resource in $ClusterResources)
        {
            Write-Verbose -Message "Setting Cluster owners for Resource $resource to $nodes" -Verbose
            Get-Cluster $ClusterName  | Get-ClusterResource | Where-Object {$_.name -like "$resource"} | Set-ClusterOwnerNode -owners $Nodes
        }
    }
    if ($Ensure -eq 'Absent')
    {          

            Write-Verbose -Message "Retrieving current clusterowners for group $ClusterGroup" -Verbose
            $currentowners = (((Get-Cluster $Clustername | Get-ClusterGroup | Where-Object {$_.name -like "$ClusterGroup"}) | Get-ClusterOwnerNode).ownernodes).name | Sort-Object -Unique
            $newowners = @(
                foreach ($currentowner in $currentowners)
                {
                    if ($Nodes -notcontains $currentowner)
                    {
                        $currentowner
                    }
                }
            )
            Write-Verbose -Message "Removing owners from group $($ClusterGroup): $Nodes"
            Write-Verbose -Message "Setting Cluster owners for Group $ClusterGroup to $newowners" -Verbose
            Get-Cluster $ClusterName  | Get-ClusterGroup | Where-Object {$_.name -like $ClusterGroup} | Set-ClusterOwnerNode $newowners
            Get-Cluster $ClusterName  | Get-ClusterGroup | Where-Object {$_.name -like $ClusterGroup} | Get-ClusterResource | Set-ClusterOwnerNode $allnodes
            Write-Verbose -Message "Moving Cluster Group $ClusterGroup to node $($newowners[0])" -Verbose
            Get-Cluster $ClusterName  | Get-ClusterGroup | Where-Object {$_.name -like $ClusterGroup} | Move-ClusterGroup -Node $newowners[0]

        foreach ($resource in $ClusterResources)
        {
            Write-Verbose -Message "Retrieving current clusterowners for resource $resource" -Verbose
            $currentowners = ((Get-Cluster $Clustername | Get-ClusterResource | Where-Object {$_.name -like "$resource"} | Get-ClusterOwnerNode).ownernodes).name | Sort-Object -Unique
            $newowners = @(
                foreach ($currentowner in $currentowners)
                {
                    if ($Nodes -notcontains $currentowner)
                    {
                        $currentowner
                    }
                }
            )
            Write-Verbose -Message "Removing owners from resource $($resource): $Nodes"
            Write-Verbose -Message "Setting Cluster owners for Resource $resource to $newowners" -Verbose
            Get-Cluster $ClusterName  | Get-ClusterResource | Where-Object {$_.name -like "$resource"} | Set-ClusterOwnerNode -owners $newowners
        }
    } 
}

# 
# Test-TargetResource
#

function Test-TargetResource  
{
    param
    (	
        [parameter(Mandatory)]
        [string[]]
        $ClusterGroup,

        [parameter(Mandatory)]
        [string]
        $Clustername,

        [parameter(Mandatory)]
        [string[]]
        $Nodes,

        [string[]]
        $ClusterResources,

        [ValidateSet('Present', 'Absent')]
		[String]
		$Ensure = 'Present'
    )

    Write-Verbose -Message "Testing Owner information for cluster $Clustername..."

    $getinfo = Get-TargetResource @PSBoundParameters
    $result = $true

    if ($Ensure -eq 'Present')
        {
        foreach ($object in $getinfo)
        {
            if ($Nodes -notcontains $object)
            {
                Write-Verbose -Message "$object was NOT found as possible owner"
                $result = $false
            }
        }
        foreach ($object in $nodes)
        {
            if ($getinfo -notcontains $object)
            {
                Write-Verbose -Message "$object was NOT found as possible owner"
                $result = $false
            }

        }
    }

    if ($Ensure -eq 'Absent')
        {
        foreach ($object in $getinfo)
        {
            if ($Nodes -contains $object)
            {
                Write-Verbose -Message "$object WAS found as possible owner"
                $result = $false
            }
        }
        foreach ($object in $nodes)
        {
            if ($getinfo -contains $object)
            {
                Write-Verbose -Message "$object WAS found as possible owner"
                $result = $false
            }

        }
    }

    $result
}
