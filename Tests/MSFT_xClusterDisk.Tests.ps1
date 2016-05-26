
[CmdletBinding()]
param
(
)

if (!$PSScriptRoot)
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
$ModuleName = 'MSFT_xClusterDisk'

Add-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction SilentlyContinue

Import-Module (Join-Path -Path $RootPath -ChildPath "DSCResources\$ModuleName\$ModuleName.psm1") -Force


## General test for the xClusterDisk resource

Describe 'xClusterDisk' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            Number = 1
            Ensure = 'Present'
            Label  = 'First Data'
        }

        Mock -CommandName 'Get-CimInstance' -ParameterFilter { $ClassName -eq 'MSCluster_Disk' -and $Namespace -eq 'Root\MSCluster' -and $Filter -eq 'Number = 1' } -MockWith {
            [PSCustomObject] @{
                Name = '1'
                Id   = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
            }
        }

        Mock -CommandName 'Get-ClusterResource' -MockWith {
            @(
                [PSCustomObject] @{
                    Name         = 'Cluster IP Address'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
                [PSCustomObject] @{
                    Name         = 'Clsuter Name'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
                [PSCustomObject] @{
                    Name         = 'First Data'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
                [PSCustomObject] @{
                    Name         = 'Witness'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
            )
        }

        Mock -CommandName 'Get-ClusterParameter' -ParameterFilter { $Name -eq 'DiskIdGuid' } -MockWith {
            #write-host $args.count -ForegroundColor Cyan
            #write-host $args -ForegroundColor Cyan
            switch ($InputObject.Name)
            {
                'First Data' {
                    [PSCustomObject] @{
                        Value = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
                    }
                }
                'Witness' {
                    [PSCustomObject] @{
                        Value = '{c8d2cafc-b694-4287-a49d-ed4e87d3d61d}'
                    }
                }
            }
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns a [System.Collection.Hashtable] type' {

                $Result = Get-TargetResource @TestParameter

                $Result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter
                
                $Result.Number | Should Be $TestParameter.Number
                $Result.Ensure | Should Be $TestParameter.Ensure
                $Result.Label  | Should Be $TestParameter.Label
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
