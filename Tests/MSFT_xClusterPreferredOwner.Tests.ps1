
[CmdletBinding()]
param
(
)

if (!$PSScriptRoot)
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
$ModuleName = 'MSFT_xClusterPreferredOwner'

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


## General tests for the xClusterPreferredOwner resource

Describe 'xClusterPreferredOwner' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            ClusterGroup     = 'ClusterGroup1'
            Clustername      = 'ClusterName1'
            Nodes            = @('Node1', 'Node2')
            ClusterResources = 'Resource1'
            Ensure           = 'Present'
        }

        Mock -CommandName 'Get-ClusterGroup' -ParameterFilter {$Cluster -eq 'ClusterName1'} -MockWith {
            @{
                Name              = 'ClusterGroup1'
                OwnerNode         = 'Node1'
                State             = 'Online'
            }
        }

        Mock -CommandName 'Get-ClusterResource' -MockWith {
            @{
                Name              = 'Resource1'
                State             = 'Online'
                OwnerGroup        = 'ClusterGroup1'
                ResourceType      = 'type1'
            }
        }

        Mock -CommandName 'Get-ClusterOwnerNode' -MockWith {
            @{
                ClusterObject     = 'ClusterName1'
                OwnerNodes        = @(
                                        @{name = 'Node1'}
                                        @{name = 'Node2'}
                                    )
            }
        }

        Mock -CommandName 'Get-ClusterNode' -MockWith {
            @{
                Name     = @('Node1', 'Node2')
            }
        }

        Mock -CommandName 'Set-ClusterOwnerNode' {
            return $null 
        }

        Mock -CommandName 'Move-ClusterGroup' {
            return $null 
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
                
                $Result.ClusterGroup     | Should Be $TestParameter.ClusterGroup     
                $Result.Clustername      | Should Be $TestParameter.Clustername 
                $Result.Nodes            | Should Be $TestParameter.Nodes        
                $Result.ClusterResources | Should Be $TestParameter.ClusterResources        
                $Result.Ensure           | Should Be $TestParameter.Ensure      
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

