
[CmdletBinding()]
param
(
)

if (!$PSScriptRoot)
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
$ModuleName = 'MSFT_xClusterNetwork'

try
{
    if (-not (Get-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction Stop).Installed)
    {
        Add-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction Stop
    }
}
catch
{
    Write-Warning $_
}

Import-Module (Join-Path -Path $RootPath -ChildPath "DSCResources\$ModuleName\$ModuleName.psm1") -Force


## General test for the xClusterNetwork resource

Describe 'xClusterNetwork' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            Address     = '10.0.0.0'
            AddressMask = '255.255.255.0'
            Name        = 'Client'
            Role        = '1'
            Metric      = '70240'
        }

        Mock -CommandName 'Get-ClusterNetwork' -MockWith {
            [PSCustomObject] @{
                Cluster           = 'CLUSTER01'
                Name              = 'Client'
                Address           = '10.0.0.0'
                AddressMask       = '255.255.255.0'
                Role              = '1'
                Metric            = '70240'
            }
        }

        Context 'Validate Get-TargetResource method' {

            It 'Returns a [System.Collection.Hashtable] type' {

                $Result = Get-TargetResource @TestParameter

                $Result -is [System.Collections.Hashtable] | Should Be $true
            }
        }

        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter
                
                $Result.Address      | Should Be $TestParameter.Address     
                $Result.AddressMask  | Should Be $TestParameter.AddressMask 
                $Result.Name         | Should Be $TestParameter.Name        
                $Result.Role         | Should Be $TestParameter.Role        
                $Result.Metric       | Should Be $TestParameter.Metric      
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Returns nothing' {

                $Result = Set-TargetResource @TestParameter

                $Result -eq $null | Should Be $true
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Returns a [System.Boolean] type' {

                $Result = Test-TargetResource @TestParameter

                $Result -is [System.Boolean] | Should Be $true
            }
        }
    }
}

