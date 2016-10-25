
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Guid,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Label
    )

    $activeDisks = Get-ClusterActiveDisk

    # Check all active disks, if the specified disk is has already been added to
    # the cluster or not.
    if ($activeDisks.Guid -contains $Guid)
    {
        $activeDisk = $activeDisks | Where-Object { $_.Guid -eq $Guid }

        @{
            Ensure = 'Present'
            Guid   = $activeDisk.Guid
            Label  = $activeDisk.Label
        }
    }
    else
    {
        @{
            Ensure = 'Absent'
            Guid   = $Guid
            Label  = ''
        }
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Guid,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Label
    )

    # Only perform any action if the target resource is not in desired state.
    # Use the test function to verify the desired state.
    if (-not (Test-TargetResource @PSBoundParameters))
    {
        $currentDisk = Get-TargetResource -Guid $Guid

        if ($Ensure -eq 'Present')
        {
            # If the disk is not present, add it to the cluster.
            if ($currentDisk.Ensure -ne $Ensure)
            {
                try
                {
                    Write-Verbose "Add the disk '$Guid' to the cluster"

                    Get-ClusterAvailableDisk | Where-Object { $_.Id -eq $Guid } | Add-ClusterDisk
                }
                catch
                {
                    throw "Unable to add disk with guid '$Guid': $_"
                }
            }

            # If the disk label does not match, set it correctly.
            if ($PSBoundParameters.ContainsKey('Label') -and $currentDisk.Label -ne $Label)
            {
                try
                {
                    Write-Verbose "Set the disk '$Guid' label to '$Label'"

                    $activeDisk = Get-ClusterActiveDisk | Where-Object { $_.Guid -eq $Guid }

                    $activeDisk.Resource.Name = $Label
                    $activeDisk.Resource.Update()
                }
                catch
                {
                    throw "Unable to update disk '$Guid' label to '$Label': $_"
                }
            }
        }
        else
        {
            try
            {
                Write-Verbose "Remove the disk '$Guid' from the cluster"

                $activeDisk = Get-ClusterActiveDisk | Where-Object { $_.Guid -eq $Guid }

                $activeDisk.Resource | Remove-ClusterResource -Force
            }
            catch
            {
                throw "Unable to remove disk with guid '$Guid': $_"
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Guid,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Label
    )

    $currentDisk = Get-TargetResource -Guid $Guid

    # If ensure is set to present and a label property was specified as a
    # parameter, test the ensure and label property. Else, ignore the label.
    if ($Ensure -eq 'Present' -and $PSBoundParameters.ContainsKey('Label'))
    {
        return ($Ensure -eq $currentDisk.Ensure -and $Label -eq $currentDisk.Label)
    }
    else
    {
        return ($Ensure -eq $currentDisk.Ensure)
    }
}

function Get-ClusterActiveDisk
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param ()

    $diskResources = Get-ClusterResource | Where-Object { $_.ResourceType -eq 'Physical Disk' }

    foreach ($diskResource in $diskResources)
    {
        New-Object -TypeName PSObject -Property @{
            Guid     = $diskResource | Get-ClusterParameter -Name DiskIdGuid | ForEach-Object { $_.Value.Trim('{}') }
            Label    = $diskResource.Name
            Resource = $diskResource
        }
    }
}

Export-ModuleMember -Function *-TargetResource
