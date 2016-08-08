
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

        $TestParameter2 = @{
            Number = 2
            Ensure = 'Present'
            Label  = 'Second Data'
        }

        $TestParameter3 = @{
            Number = 3
            Ensure = 'Absent'
            Label  = 'Third Data'
        }

        $TestParameter4 = @{
            Number = 1
            Ensure = 'Present'
            Label  = 'Wrong Label'
        }
        
        Mock -CommandName 'Get-CimInstance' -ParameterFilter { $ClassName -eq 'MSCluster_Disk' -and $Namespace -eq 'Root\MSCluster' } -MockWith {
            switch($Filter)
            {
                'Number = 1' {
                    [PSCustomObject] @{
                        Name = '1'
                        Id   = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
                    }                    
                }
                default {
                    $null
                }
            }
        }

        Mock -CommandName 'Get-ClusterResource' -MockWith {
            @(
                [PSCustomObject] @{
                    Name         = 'Cluster IP Address'
                    ResourceType = 'IP Address'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
                [PSCustomObject] @{
                    Name         = 'Clsuter Name'
                    ResourceType = 'Network Name'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
                [PSCustomObject] @{
                    Name         = 'First Data'
                    ResourceType = 'Physical Disk'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {} -PassThru
                [PSCustomObject] @{
                    Name         = 'Witness'
                    ResourceType = 'Physical Disk'
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
                
                $Result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Returns absent for a disk that is absent but should be present' {

                $Result = Get-TargetResource @TestParameter2
                
                $Result.Number | Should Be $TestParameter2.Number
                $Result.Ensure | Should Not Be $TestParameter2.Ensure
                $Result.Label  | Should Not Be $TestParameter2 .Label
                
                $Result -is [System.Collections.Hashtable] | Should Be $true
            }
            
            It 'Returns absent for a disk that is absent as it should be' {

                $Result = Get-TargetResource @TestParameter3
                
                $Result.Number | Should Be $TestParameter3.Number
                $Result.Ensure | Should Be $TestParameter3.Ensure
                $Result.Label  | Should Be ''
                
                $Result -is [System.Collections.Hashtable] | Should Be $true
            }
            
            It 'Returns present for a disk that is present but has the wrong label' {

                $Result = Get-TargetResource @TestParameter4
                
                $Result.Number | Should Be $TestParameter4.Number
                $Result.Ensure | Should Be $TestParameter4.Ensure
                $Result.Label  | Should Not Be $TestParameter4.Label
                
                $Result -is [System.Collections.Hashtable] | Should Be $true
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Returns nothing' {

                $Result = Set-TargetResource @TestParameter

                $Result -eq $null | Should Be $true
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check present disk that is present returns $true' {

                $Result = Test-TargetResource -Ensure $TestParameter.Ensure -Label $TestParameter.Label -Number $TestParameter.Number

                $Result -is [System.Boolean] | Should Be $true
                $Result | Should Be $true
            }
            
            It 'Check absent disk that should be present returns $false' {

                $Result = Test-TargetResource -Ensure $TestParameter2.Ensure -Label $TestParameter2.Label -Number $TestParameter2.Number

                $Result -is [System.Boolean] | Should Be $true
                $Result | Should Be $false
            }
            
            It 'Check absent disk that is absent returns $true' {

                $Result = Test-TargetResource -Ensure $TestParameter3.Ensure -Label $TestParameter3.Label -Number $TestParameter3.Number

                $Result -is [System.Boolean] | Should Be $true
                $Result | Should Be $true
            }
            
            It 'Check that present disk but with a wrong label returns $false' {

                $Result = Test-TargetResource -Ensure $TestParameter4.Ensure -Label $TestParameter4.Label -Number $TestParameter4.Number

                $Result -is [System.Boolean] | Should Be $true
                $Result | Should Be $false
            }
        }
    }
}
