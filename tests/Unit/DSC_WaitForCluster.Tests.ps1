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
    $script:DSCResourceName = 'DSC_WaitForCluster'

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

Describe 'Cluster\Get-TargetResource' -Tag 'Get' {
    Context 'When the system is either in the desired state or not in the desired state' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name             = 'CLUSTER001'
                    RetryIntervalSec = 1
                    RetryCount       = 1
                }

                $result = Get-TargetResource @mockParameters

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Name | Should -Be $mockParameters.Name
                $result.RetryIntervalSec | Should -Be $mockParameters.RetryIntervalSec
                $result.RetryCount | Should -Be $mockParameters.RetryCount
            }
        }
    }
}

Describe 'Cluster\Set-TargetResource' -Tag 'Set' {
    Context 'When computers domain name cannot be evaluated' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = $null
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name             = 'CLUSTER001'
                    RetryIntervalSec = 1
                    RetryCount       = 1
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.ClusterAbsentAfterTimeOut -f
                    $mockParameters.Name,
                    $($mockParameters.RetryCount - 1),
                    $mockParameters.RetryIntervalSec
                )

                { Set-TargetResource @mockParameters } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the cluster does not exist' {
            Context 'When Get-Cluster throws an error' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        [PSCustomObject] @{
                            Domain = 'domain.local'
                        }
                    }

                    # This is used for the evaluation of a cluster that does not exist
                    Mock -CommandName Get-Cluster -MockWith { throw 'Mock Get-Cluster throw error' }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            Name             = 'CLUSTER001'
                            RetryIntervalSec = 1
                            RetryCount       = 1
                        }

                        $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.ClusterAbsentAfterTimeOut -f
                            $mockParameters.Name,
                            $mockParameters.RetryCount,
                            $mockParameters.RetryIntervalSec)

                        { Set-TargetResource @mockParameters } | Should -Throw $errorRecord
                    }

                    Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the cluster exist' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                    }
                }

                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                }
            }

            It 'Should not throw any error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name             = 'CLUSTER001'
                        RetryIntervalSec = 1
                        RetryCount       = 1
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'Cluster\Test-TargetResource' -Tag 'Test' {
    Context 'When computers domain name cannot be evaluated' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = $null
                }
            }
        }

        It 'Should return the value $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name             = 'CLUSTER001'
                    RetryIntervalSec = 1
                    RetryCount       = 1
                }

                Test-TargetResource @mockParameters | Should -BeFalse
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the cluster does not exist' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                    }
                }
            }

            Context 'When Get-Cluster throws an error' {
                BeforeAll {
                    # This is used for the evaluation of a cluster that does not exist.
                    Mock -CommandName Get-Cluster -MockWith { throw 'Mock Get-Cluster throw error' }
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            Name             = 'CLUSTER001'
                            RetryIntervalSec = 1
                            RetryCount       = 1
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Get-Cluster returns nothing' {
                BeforeAll {
                    # This is used for the evaluation of a cluster that does not exist.
                    Mock -CommandName Get-Cluster
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            Name             = 'CLUSTER001'
                            RetryIntervalSec = 1
                            RetryCount       = 1
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the cluster exist' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                    }
                }

                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                }
            }

            It 'Should return the value $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name             = 'CLUSTER001'
                        RetryIntervalSec = 1
                        RetryCount       = 1
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
            }
        }
    }
}
