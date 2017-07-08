<#
    .SYNOPSIS
        Get the values for which failover cluster and for how long to wait for the
        cluster to exist.

    .PARAMETER Name
        Name of the cluster to wait for.

    .PARAMETER RetryIntervalSec
        Interval to check for cluster existence. Default values is 10 seconds.

    .PARAMETER RetryCount
        Maximum number of retries to check for cluster existence. Default value
        is 50 retries.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 10,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 50
    )

    @{
        Name = $Name
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }
}

<#
    .SYNOPSIS
        Waits for the specific failover cluster to exist. It will throw an error if the
        cluster has not been detected during the timeout period.

    .PARAMETER Name
        Name of the cluster to wait for.

    .PARAMETER RetryIntervalSec
        Interval to check for cluster existence. Default values is 10 seconds.

    .PARAMETER RetryCount
        Maximum number of retries to check for cluster existence. Default value
        is 50 retries.
#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 10,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 50
    )

    $clusterFound = $false
    Write-Verbose -Message "Checking for the existance of failover cluster $Name."

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $computerObject = Get-CimInstance -Class Win32_ComputerSystem
            if ($null -eq $computerObject -or $null -eq $computerObject.Domain)
            {
                Write-Verbose -Message "Can't find machine's domain name"
                break
            }

            $cluster = Get-Cluster -Name $Name -Domain $computerObject.Domain

            if ($null -ne $cluster)
            {
                Write-Verbose -Message "Found failover cluster $Name"
                $clusterFound = $true
                break
            }
        }
        catch
        {
             Write-Verbose -Message "Failover cluster $Name not found. Will retry again after $RetryIntervalSec sec"
        }

        Write-Verbose -Message "Failover cluster $Name not found. Will retry again after $RetryIntervalSec sec"
        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (! $clusterFound)
    {
        throw "Failover cluster $Name not found after $count attempts with $RetryIntervalSec sec interval"
    }
}

<#
    .SYNOPSIS
        Test if the specific failover cluster exist.

    .PARAMETER Name
        Name of the cluster to wait for.

    .PARAMETER RetryIntervalSec
        Interval to check for cluster existence. Default values is 10 seconds.

    .PARAMETER RetryCount
        Maximum number of retries to check for cluster existence. Default value
        is 50 retries.
#>
function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.UInt64]
        $RetryIntervalSec = 10,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 50
    )

    Write-Verbose -Message "Checking for Cluster $Name ..."

    $testTargetResourceReturnValue = $false

    try
    {
        $computerObject = Get-CimInstance -Class Win32_ComputerSystem
        if ($null -eq $computerObject -or $null -eq $computerObject.Domain)
        {
            Write-Verbose -Message "Can't find machine's domain name"
        }
        else
        {
            $cluster = Get-Cluster -Name $Name -Domain $computerObject.Domain
            if ($null -eq $cluster)
            {
                Write-Verbose -Message "Cluster $Name not found in domain $computerObject.Domain"
            }
            else
            {
                Write-Verbose -Message "Found cluster $Name"
                $testTargetResourceReturnValue = $true
            }
        }
    }
    catch
    {
        Write-Verbose -Message "Cluster $Name not found"
    }

    $testTargetResourceReturnValue
}

