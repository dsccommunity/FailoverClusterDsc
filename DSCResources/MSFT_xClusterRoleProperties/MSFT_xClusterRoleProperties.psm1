#We assume a unique AG name per WSFC. May change in future

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
	param
    (   
		[parameter(Mandatory = $true)][string] $Name,
        [parameter(Mandatory = $true)][string] $Cluster,
        [Parameter(Mandatory = $false)][string] $Priority,
        [Parameter(Mandatory = $false)][UInt32] $FailoverThreshold,
		[Parameter(Mandatory = $false)][UInt32] $FailoverPeriod,
		[Parameter(Mandatory = $false)][string] $AutoFailbackType
    )

    Write-Verbose "Getting Cluster Group Role $Name"
	$ClusterRole = Get-ClusterGroup -Cluster $Cluster -Name $Name
	
	@{
		Name = $ClusterRole.Name
		State = $ClusterRole.State
		Cluster = $ClusterRole.Cluster
		Priority = $ClusterRole.Priority
		FailoverThreshold = $ClusterRole.FailoverThreshold
		FailoverPeriod = $ClusterRole.FailoverPeriod
		AutoFailbackType = $ClusterRole.AutoFailbackType
	}
}

function Set-TargetResource
{
    [CmdletBinding()]
	param
    (   
		[parameter(Mandatory = $true)][string] $Name,
        [parameter(Mandatory = $true)][string] $Cluster,
        [Parameter(Mandatory = $false)][string] $Priority,
        [Parameter(Mandatory = $false)][UInt32] $FailoverThreshold,
		[Parameter(Mandatory = $false)][UInt32] $FailoverPeriod,
		[Parameter(Mandatory = $false)][string] $AutoFailbackType
    )
	
	#Get the actual object to update
	$ClusterRole = Get-ClusterGroup -Cluster $Cluster -Name $Name 
	
	Write-Verbose "Updating Cluster Role : $Name"
	foreach ($p in $PSBoundParameters.GetEnumerator())
    {
       if ($p.value -and $ClusterRole -and @("Cluster","Verbose") -notcontains $p.key) #these last ones are readonly. See Name issue in below switch
       {

			#For some reason unbeknown to me this piece of code will not work and set the parameters
			#Write-Verbose $p.key
			#Write-Verbose $p.value

            switch ($p.key)
            {
                {("AutoFailbackType","Priority") -contains $_} 
				{
					$ClusterRole.$($p.key) = (convert-parameters $p.value);
					Write-host "Updating" $p.key "to =" $ClusterRole.$($p.key)
					break;
				}
	            default {
					$ClusterRole.$($p.key) = $p.value
					Write-host "Updating" $p.key "to =" $p.value
					break;
				}
			}
       } 
    }
	$ClusterRole.Update()
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
	param
    (   
		[parameter(Mandatory = $true)][string] $Name,
        [parameter(Mandatory = $true)][string] $Cluster,
        [Parameter(Mandatory = $false)][string] $Priority,
        [Parameter(Mandatory = $false)][UInt32] $FailoverThreshold,
		[Parameter(Mandatory = $false)][UInt32] $FailoverPeriod,
		[Parameter(Mandatory = $false)][string] $AutoFailbackType
    )

    $ClusterRole = Get-TargetResource -Cluster $Cluster -Name $Name
	
	$test = $true
	
	foreach ($p in $PSBoundParameters.GetEnumerator())
    {
       if ($p.value -and $p.key -ne "Verbose")
       {
            
	
			#Switch code will not work
			Switch ($p.key)
            {
                {("AutoFailbackType","Priority") -contains $_}
				{
					if ((convert-parameters $p.value) -ne $ClusterRole.$($p.key)) 
					{
						$test = $false
						Write-host "Value" $p.key "not correct. Current Value =" $ClusterRole.$($p.key)
					}  
					break;
				}
                
				default 
				{
					if ($p.value -ne $ClusterRole.$($p.key)) 
					{
						$test = $false
						Write-host "Value" $p.key "not correct. Current Value =" $ClusterRole.$($p.key)
					}; 
					break;
				}
            }
       } 
    }
	
	Write-Verbose "Testing Cluster Role : $Name policy returned $test"
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
