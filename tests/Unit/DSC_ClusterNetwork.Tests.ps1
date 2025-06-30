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
    $script:DSCResourceName = 'DSC_ClusterNetwork'

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

Describe 'ClusterNetwork\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Get-ClusterNetwork -MockWith {
            [PSCustomObject] @{
                Cluster     = 'CLUSTER01'
                Name        = 'Client1'
                Address     = '10.0.0.0'
                AddressMask = '255.255.255.0'
                Role        = [System.UInt32] 1
                Metric      = '70240'
            }
        }
    }

    Context 'When the system is not in the desired state' {
        It 'Should return the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Address     = '10.0.0.0'
                    AddressMask = '255.255.255.0'
                }

                $result = Get-TargetResource @mockParameters
                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Address | Should -Be $mockParameters.Address
                $result.AddressMask | Should -Be $mockParameters.AddressMask

                $result.Name | Should -Not -Be 'Client2'
                $result.Role | Should -Not -Be ([System.UInt32] 3)
                $result.Metric | Should -Not -Be '10'
            }

            Should -Invoke -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
        }

        Context 'When testing against WS2016 and later' {
            BeforeAll {
                Mock -CommandName Get-ClusterNetwork -MockWith {
                    [PSCustomObject] @{
                        Cluster     = 'CLUSTER01'
                        Name        = 'Client1'
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Role        = [PSCustomObject] @{ value__ = 1 }
                        Metric      = '70240'
                    }
                }
            }

            It 'Should not return the the correct values for the cluster network role on WS2016' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                    }

                    $result = Get-TargetResource @mockParameters
                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result.Address | Should -Be $mockParameters.Address
                    $result.AddressMask | Should -Be $mockParameters.AddressMask

                    $result.Name | Should -Not -Be 'Client2'
                    $result.Role | Should -Not -Be ([System.UInt32] 3)
                    $result.Metric | Should -Not -Be '10'
                }

                Should -Invoke -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Address     = '10.0.0.0'
                    AddressMask = '255.255.255.0'
                }

                $result = Get-TargetResource @mockParameters

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Address | Should -Be $mockParameters.Address
                $result.AddressMask | Should -Be $mockParameters.AddressMask
                $result.Name | Should -Be 'Client1'
                $result.Role | Should -Be ([System.UInt32] 1)
                $result.Metric | Should -Be '70240'
            }

            Should -Invoke -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
        }

        Context 'When testing against WS2016 and later' {
            BeforeAll {
                Mock -CommandName Get-ClusterNetwork -MockWith {
                    [PSCustomObject] @{
                        Cluster     = 'CLUSTER01'
                        Name        = 'Client1'
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Role        = [PSCustomObject] @{ value__ = 1 }
                        Metric      = '70240'
                    }
                }
            }

            It 'Should return the the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result.Address | Should -Be $mockParameters.Address
                    $result.AddressMask | Should -Be $mockParameters.AddressMask
                    $result.Name | Should -Be 'Client1'
                    $result.Role | Should -Be ([System.UInt32] 1)
                    $result.Metric | Should -Be '70240'
                }

                Should -Invoke -CommandName Get-ClusterNetwork -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'ClusterNetwork\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith {
            [PSCustomObject] @{
                Address     = '10.0.0.0'
                AddressMask = '255.255.255.0'
                Name        = 'Client1'
                Role        = [System.UInt32] 1
                Metric      = '70240'
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When all supported properties is not in desired state' {
            It 'Should return result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client2'
                        Role        = [System.UInt32] 3
                        Metric      = '10'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When all Name property is not in desired state' {
            It 'Should return result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client2'
                        Role        = [System.UInt32] 1
                        Metric      = '70240'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When all Role property is not in desired state' {
            It 'Should return result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client1'
                        Role        = [System.UInt32] 3
                        Metric      = '70240'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When all Metric property is not in desired state' {
            It 'Should return result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client1'
                        Role        = [System.UInt32] 1
                        Metric      = '10'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should return result as $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Address     = '10.0.0.0'
                    AddressMask = '255.255.255.0'
                    Name        = 'Client1'
                    Role        = [System.UInt32] 1
                    Metric      = '70240'
                }

                Test-TargetResource @mockParameters | Should -BeTrue
            }
        }
    }
}

Describe 'ClusterNetwork\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Mock -CommandName Get-ClusterNetwork -MockWith {
                [PSCustomObject] @{
                    Cluster     = 'CLUSTER01'
                    Name        = 'Client1'
                    Address     = '10.0.0.0'
                    AddressMask = '255.255.255.0'
                    Role        = [System.UInt32] 1
                    Metric      = '70240'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $script:mockNumberOfTimesMockedMethodUpdateWasCalled += 1
                } -PassThru
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockNumberOfTimesMockedMethodUpdateWasCalled = 0
            }
        }

        Context 'When all supported properties is not in desired state' {
            It 'Should call Update method correct number of times' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client2'
                        Role        = [System.UInt32] 3
                        Metric      = '10'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw

                    $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly 3
                }
            }
        }

        Context 'When all Name property are not in desired state' {
            It 'Should call Update method correct number of times' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client2'
                        Role        = [System.UInt32] 1
                        Metric      = '70240'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw

                    $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly 1
                }
            }
        }

        Context 'When all Role property are not in desired state' {
            It 'Should call Update method correct number of times' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client1'
                        Role        = [System.UInt32] 3
                        Metric      = '70240'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw

                    $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly 1
                }
            }
        }

        Context 'When all Metric property is not in desired state' {
            It 'Should call Update method correct number of times' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockProperties = @{
                        Address     = '10.0.0.0'
                        AddressMask = '255.255.255.0'
                        Name        = 'Client1'
                        Role        = [System.UInt32] 1
                        Metric      = '10'
                    }

                    { Set-TargetResource @mockProperties } | Should -Not -Throw

                    $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly 1
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should call Update method correct number of times' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockNumberOfTimesMockedMethodUpdateWasCalled = 0

                $mockParameters = @{
                    Address     = '10.0.0.0'
                    AddressMask = '255.255.255.0'
                    Name        = 'Client1'
                    Role        = [System.UInt32] 1
                    Metric      = '70240'
                }


                { Set-TargetResource @mockParameters } | Should -Not -Throw

                $script:mockNumberOfTimesMockedMethodUpdateWasCalled | Should -BeExactly 0
            }
        }
    }
}
