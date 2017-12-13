function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
	param
    (   
		[parameter(Mandatory = $true)][string] $OwnerGroup,
        [parameter(Mandatory = $true)][string] $Cluster,
        [Parameter(Mandatory = $true)][string] $ResourceType,
        [Parameter(Mandatory = $true)][string] $Name,

		####### Failover Based properties - mainly for Cluster Roles
        [Parameter(Mandatory = $false)][string] $Priority,
        [Parameter(Mandatory = $false)][UInt64] $FailoverThreshold,
		[Parameter(Mandatory = $false)][UInt64] $FailoverPeriod,
		[Parameter(Mandatory = $false)][string] $AutoFailbackType,
		
		####### Policy Based properties	
        [Parameter(Mandatory = $false)][UInt64] $RestartAction,
        [Parameter(Mandatory = $false)][UInt64] $RestartPeriod,
		[Parameter(Mandatory = $false)][UInt64] $RestartThreshold,
		[Parameter(Mandatory = $false)][UInt64] $RestartDelay,
		[Parameter(Mandatory = $false)][UInt64] $RetryPeriodOnFailure,
		[Parameter(Mandatory = $false)][UInt64] $PendingTimeout
    )

    Write-Verbose "Getting Cluster Resource $Name"
	$ClusterResource = Get-ClusterResource -Cluster $Cluster | ? {$_.OwnerGroup -eq $OwnerGroup -and $_.ResourceType -eq $ResourceType}
	
	@{
		Name = $ClusterResource.Name
		State = $ClusterResource.State
		Cluster = $ClusterResource.Cluster
		OwnerGroup = $ClusterResource.OwnerGroup
		ResourceType = $ClusterResource.ResourceType
		Priority = $ClusterResource.Priority
		FailoverThreshold = $ClusterResource.FailoverThreshold
		RestartPeriod = $ClusterResource.RestartPeriod
		AutoFailbackType = $ClusterResource.AutoFailbackType
		RestartAction  = $ClusterResource.RestartAction
		RestartThreshold  = $ClusterResource.RestartThreshold
		RestartDelay  = $ClusterResource.RestartDelay
		RetryPeriodOnFailure  = $ClusterResource.RetryPeriodOnFailure
		PendingTimeout  = $ClusterResource.PendingTimeout
	}
}

function Set-TargetResource
{
    [CmdletBinding()]
	param
    (   
		[parameter(Mandatory = $true)][string] $OwnerGroup,
        [parameter(Mandatory = $true)][string] $Cluster,
        [Parameter(Mandatory = $true)][string] $ResourceType,
        [Parameter(Mandatory = $true)][string] $Name,

		####### Failover Based properties - mainly for Cluster Roles
        [Parameter(Mandatory = $false)][string] $Priority,
        [Parameter(Mandatory = $false)][UInt64] $FailoverThreshold,
		[Parameter(Mandatory = $false)][UInt64] $FailoverPeriod,
		[Parameter(Mandatory = $false)][string] $AutoFailbackType,
		
		####### Policy Based properties	
        [Parameter(Mandatory = $false)][UInt64] $RestartAction,
        [Parameter(Mandatory = $false)][UInt64] $RestartPeriod,
		[Parameter(Mandatory = $false)][UInt64] $RestartThreshold,
		[Parameter(Mandatory = $false)][UInt64] $RestartDelay,
		[Parameter(Mandatory = $false)][UInt64] $RetryPeriodOnFailure,
		[Parameter(Mandatory = $false)][UInt64] $PendingTimeout
    )
	
	#Get the actual object to update
	$ClusterResource = Get-ClusterResource -Cluster $Cluster | ? {$_.OwnerGroup -eq $OwnerGroup -and $_.ResourceType -eq $ResourceType}
	
	$recycle = $false

	foreach ($p in $PSBoundParameters.GetEnumerator())
    {
       if ($p.value -and $ClusterResource -and @("Cluster","Verbose","OwnerGroup","ResourceType") -notcontains $p.key)
       {
			switch ($p.key)
            {
                {("AutoFailbackType","Priority") -contains $_} 
				{
					$ClusterResource.$($p.key) = (convert-parameters $p.value);
					Write-host "Updating" $p.key "to =" $ClusterResource.$($p.key)
					break;
				}
				{$_ -eq "PendingTimeout"}
				{
					#Pending restart needed
					if ($p.value -ne $ClusterResource.$($p.key) -and $ResourceType -eq "Cloud Witness")
					{
						$recycle = $true
						$ClusterResource.$($p.key) = $p.value
						Write-Host "Cluster Witness : " $Name "being recycled"
					}
					
					if ($recycle)
					{
						Stop-ClusterResource -Cluster $Cluster -Name $Name -Wait 10 -ErrorAction SilentlyContinue
						Start-ClusterResource -Cluster $Cluster -Name $Name -Wait 10 -ErrorAction SilentlyContinue
					}
					break;
				}
                default {			
					$ClusterResource.$($p.key) = $p.value
					Write-host "Updating" $p.key "to =" $p.value
					break;
				}
			}
       } 
    }
	
	$ClusterResource.Update()
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
	param
    (   
		[parameter(Mandatory = $true)][string] $OwnerGroup,
        [parameter(Mandatory = $true)][string] $Cluster,
        [Parameter(Mandatory = $true)][string] $ResourceType,
        [Parameter(Mandatory = $true)][string] $Name,

		####### Failover Based properties - mainly for Cluster Roles
        [Parameter(Mandatory = $false)][string] $Priority,
        [Parameter(Mandatory = $false)][UInt64] $FailoverThreshold,
		[Parameter(Mandatory = $false)][UInt64] $FailoverPeriod,
		[Parameter(Mandatory = $false)][string] $AutoFailbackType,
		
		####### Policy Based properties	
        [Parameter(Mandatory = $false)][UInt64] $RestartAction,
        [Parameter(Mandatory = $false)][UInt64] $RestartPeriod,
		[Parameter(Mandatory = $false)][UInt64] $RestartThreshold,
		[Parameter(Mandatory = $false)][UInt64] $RestartDelay,
		[Parameter(Mandatory = $false)][UInt64] $RetryPeriodOnFailure,
		[Parameter(Mandatory = $false)][UInt64] $PendingTimeout
    )

    Write-Verbose "Testing Cluster Resource $Name"
	$ClusterResource = Get-TargetResource -Cluster $Cluster -OwnerGroup $OwnerGroup -ResourceType $ResourceType -Name $Name
	
	$test = $true
	
	foreach ($p in $PSBoundParameters.GetEnumerator())
    {
       if ($p.value -and @("Cluster","Verbose","OwnerGroup","ResourceType") -notcontains $p.key)
       {
			#Switch code will not work
			Switch ($p.key)
			{
				{("AutoFailbackType","Priority") -contains $_}
				{
					if ((convert-parameters $p.value) -ne $ClusterResource.$($p.key)) 
					{
						$test = $false
						Write-host "Value" $p.key "not correct. Current Value =" $ClusterResource.$($p.key)
					}  
					break;
				}			
				default 
				{
					if ($p.value -ne $ClusterResource.$($p.key)) 
					{
						$test = $false
						Write-host "Value" $p.key "not correct. Current Value =" $ClusterResource.$($p.key)
					}
					break;
				}
			}
       } 
    }
	
	Write-Verbose "Testing Cluster Role : $RoleName policy returned $test"
	return $test	
}

function convert-parameters
{
    [CmdletBinding()]
	param
    (   
		[parameter(Mandatory = $false)][string] $value
    )
	
	switch ($value)
	{
		"No Auto Start" {$response = 0} 
		"Low" {$response = 1000}
		"Medium" {$response = 2000}
		"High" {$response = 3000}
		"Prevent" {$response = 0}
		"Allow" {$response = 1}
		default {$response = $null}
	}
	
	return $response
}

Export-ModuleMember -Function *-TargetResource
