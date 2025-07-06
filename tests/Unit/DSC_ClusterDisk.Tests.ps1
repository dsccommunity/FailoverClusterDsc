# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:DSCModuleName = 'FailoverClusterDsc'
    $script:DSCResourceName = 'DSC_ClusterDisk'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Load stub cmdlets and classes.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\FailoverClusters.stubs.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload stub module
    Remove-Module -Name FailoverClusters.stubs -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'ClusterDisk\Get-TargetResource' -Tag 'Get' {
    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Name = 'First Data'
                    Id   = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
                }
            } -ParameterFilter {
                $Filter -eq 'Number = 1'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @(
                    [PSCustomObject] @{
                        Name         = 'First Data'
                        ResourceType = 'Physical Disk'
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru

                    [PSCustomObject] @{
                        Name         = 'Second Data'
                        ResourceType = 'Physical Disk'
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru
                )
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                [PSCustomObject] @{
                    Value = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
                }
            } -ParameterFilter {
                $InputObject.Name -eq 'First Data'
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                [PSCustomObject] @{
                    Value = '{5182f370-e2b8-4579-8caa-176e0e05c323}'
                }
            } -ParameterFilter {
                $InputObject.Name -eq 'Second Data'
            }
        }

        Context 'When Ensure is set to ''Present'' but the disk is not present' {
            BeforeAll {
                Mock -CommandName Get-CimInstance
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '2'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result.Number | Should -Be $mockParameters.Number
                    $result.Ensure | Should -Be 'Absent'
                    $result.Label | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the disk is present' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.Number | Should -Be $mockParameters.Number
                    $result.Ensure | Should -Be 'Present'
                    $result.Label | Should -Be 'First Data'
                }
            }
        }

        Context 'When Ensure is set to ''Present'' and the disk is present but has the wrong label' {
            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.Number | Should -Be $mockParameters.Number
                    $result.Ensure | Should -Be 'Present'
                    $result.Label | Should -Not -Be 'Wrong Label'
                    $result.Label | Should -Be 'First Data'
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Name = 'First Data'
                    Id   = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
                }
            } -ParameterFilter {
                $Filter -eq 'Number = 1'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @(
                    [PSCustomObject] @{
                        Name         = 'First Data'
                        ResourceType = 'Physical Disk'
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru

                    [PSCustomObject] @{
                        Name         = 'Second Data'
                        ResourceType = 'Physical Disk'
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru
                )
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                [PSCustomObject] @{
                    Value = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
                }
            } -ParameterFilter {
                $InputObject.Name -eq 'First Data'
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                [PSCustomObject] @{
                    Value = '{5182f370-e2b8-4579-8caa-176e0e05c323}'
                }
            } -ParameterFilter {
                $InputObject.Name -eq 'Second Data'
            }
        }

        Context 'When Ensure is set to ''Present'' and the disk is present' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result.Number | Should -Be $mockParameters.Number
                    $result.Ensure | Should -Be 'Present'
                    $result.Label | Should -Be 'First Data'
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the disk is not present' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '2'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.Number | Should -Be $mockParameters.Number
                    $result.Ensure | Should -Be 'Absent'
                    $result.Label | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'ClusterDisk\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith {
            @{
                Number = '1'
                Ensure = 'Present'
                Label  = 'First Data'
            }
        } -ParameterFilter {
            $Number -eq '1'
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When Ensure is set to ''Present'' but the disk is not present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Number = '2'
                        Ensure = 'Absent'
                        Label  = ''
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '2'
                        Ensure = 'Present'
                        Label  = 'Second Data'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the disk is present' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                        Ensure = 'Absent'
                        Label  = 'First Data'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When Ensure is set to ''Present'' and the disk is present but has the wrong label' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                        Ensure = 'Present'
                        Label  = 'Wrong Label'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When Ensure is set to ''Present'' and the disk is present' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                        Ensure = 'Present'
                        Label  = 'First Data'
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the disk is not present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Number = '3'
                        Ensure = 'Absent'
                        Label  = ''
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '3'
                        Ensure = 'Absent'
                        Label  = 'Third Data'
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }
            }
        }
    }
}

Describe 'ClusterDisk\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Get-CimInstance -MockWith {
            [PSCustomObject] @{
                Name = 'Second Data'
                Id   = '{5182f370-e2b8-4579-8caa-176e0e05c323}'
            }
        }

        Mock -CommandName Get-ClusterResource -MockWith {
            @(
                [PSCustomObject] @{
                    Name         = 'First Data'
                    ResourceType = 'Physical Disk'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru

                [PSCustomObject] @{
                    Name         = 'Second Data'
                    ResourceType = 'Physical Disk'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru
            )
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            [PSCustomObject] @{
                Value = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
            }
        } -ParameterFilter {
            $InputObject.Name -eq 'First Data'
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            [PSCustomObject] @{
                Value = '{5182f370-e2b8-4579-8caa-176e0e05c323}'
            }
        } -ParameterFilter {
            $InputObject.Name -eq 'Second Data'
        }

        Mock -CommandName Get-ClusterAvailableDisk -MockWith {
            @(
                [PSCustomObject] @{
                    Number = '2'
                }
            )
        }

        Mock -CommandName Add-ClusterDisk
        Mock -CommandName Remove-ClusterResource
    }

    Context 'When the system is not in the desired state' {
        Context 'When Ensure is set to ''Present'' but the disk is not present' {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Number = '2'
                        Ensure = 'Absent'
                        Label  = $null
                    }
                }
            }

            It 'Should add the disk to the cluster' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '2'
                        Ensure = 'Present'
                        Label  = 'Second Data'
                    }


                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Add-ClusterDisk -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-ClusterResource -Exactly -Times 0 -Scope It
            }
        }

        Context 'When Ensure is set to ''Absent'' and the disk is present' {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Number = '1'
                        Ensure = 'Present'
                        Label  = 'First Data'
                    }
                }
            }

            It 'Should remove the disk from the cluster' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                        Ensure = 'Absent'
                        Label  = 'First Data'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Add-ClusterDisk -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When Ensure is set to ''Present'' and the disk is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Number = '1'
                        Ensure = 'Present'
                        Label  = 'First Data'
                    }
                }
            }

            It 'Should not call any cluster cmdlets' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '1'
                        Ensure = 'Present'
                        Label  = 'First Data'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Add-ClusterDisk -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterResource -Exactly -Times 0 -Scope It
            }
        }

        Context 'When Ensure is set to ''Absent'' and the disk is not present' {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Number = '1'
                        Ensure = 'Absent'
                        Label  = 'First Data'
                    }
                }
            }

            It 'Should not call any cluster cmdlets' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Number = '3'
                        Ensure = 'Absent'
                        Label  = 'Third Data'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Add-ClusterDisk -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterResource -Exactly -Times 0 -Scope It
            }
        }
    }
}
