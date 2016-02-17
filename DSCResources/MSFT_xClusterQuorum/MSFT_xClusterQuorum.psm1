
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String] $IsSingleInstance,

        [Parameter(Mandatory = $false)]
        [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'DiskOnly')]
        [String] $Type,
        
        [Parameter(Mandatory = $false)]
        [String] $Resource
    )

    
    $ClusterQuorum = Get-ClusterQuorum
        
    @{
        IsSingleInstance = $IsSingleInstance
        Type             = [String] $ClusterQuorum.QuorumType
        Resource         = [String] $ClusterQuorum.QuorumResource
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String] $IsSingleInstance,

        [Parameter(Mandatory = $false)]
        [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'DiskOnly')]
        [String] $Type,
        
        [Parameter(Mandatory = $false)]
        [String] $Resource
    )

    switch ($Type)
    {
        'NodeMajority' {
            Set-ClusterQuorum -NoWitness
        }

        'NodeAndDiskMajority' {
            Set-ClusterQuorum -DiskWitness $Resource
        }

        'NodeAndFileShareMajority' {
            Set-ClusterQuorum -FileShareWitness $Resource
        }

        'DiskOnly' {
            Set-ClusterQuorum -DiskOnly $Resource
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String] $IsSingleInstance,

        [Parameter(Mandatory = $false)]
        [ValidateSet('NodeMajority', 'NodeAndDiskMajority', 'NodeAndFileShareMajority', 'DiskOnly')]
        [String] $Type,
        
        [Parameter(Mandatory = $false)]
        [String] $Resource
    )
    
    $CurrentQuorum = Get-TargetResource -IsSingleInstance $IsSingleInstance
    
    return (
        ($CurrentQuorum.Type -eq $Type) -and
        ($CurrentQuorum.Resource -eq $Resource)
    )
}

Export-ModuleMember -Function *-TargetResource
