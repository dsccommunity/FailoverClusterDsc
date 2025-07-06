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
    $script:DSCResourceName = 'DSC_ClusterProperty'

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

Describe 'ClusterProperty\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Get-Cluster -MockWith {
                [PSCustomObject] @{
                    SameSubnetDelay      = 1000
                    SameSubnetThreshold  = 5
                    CrossSubnetDelay     = 1000
                    CrossSubnetThreshold = 5
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name = 'Cluster1'
                }

                $result = Get-TargetResource @mockParameters

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Name | Should -Be $mockParameters.Name

                $result.SameSubnetDelay | Should -Be 1000
                $result.SameSubnetThreshold | Should -Be 5
                $result.CrossSubnetDelay | Should -Be 1000
                $result.CrossSubnetThreshold | Should -Be 5

                $result.AddEvictDelay | Should -BeNullOrEmpty
                $result.BlockCacheSize | Should -BeNullOrEmpty
                $result.ClusterLogLevel | Should -BeNullOrEmpty
                $result.ClusterLogSize | Should -BeNullOrEmpty
                $result.CrossSiteDelay | Should -BeNullOrEmpty
                $result.CrossSiteThreshold | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.DatabaseReadWriteMode | Should -BeNullOrEmpty
                $result.DefaultNetworkRole | Should -BeNullOrEmpty
                $result.DrainOnShutdown | Should -BeNullOrEmpty
                $result.DynamicQuorum | Should -BeNullOrEmpty
                $result.NetftIPSecEnabled | Should -BeNullOrEmpty
                $result.QuarantineDuration | Should -BeNullOrEmpty
                $result.PreferredSite | Should -BeNullOrEmpty
                $result.QuarantineThreshold | Should -BeNullOrEmpty
                $result.ShutdownTimeoutInMinutes | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the resource does not exist' {
        BeforeAll {
            Mock -CommandName Get-Cluster
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name = 'Cluster1'
                }

                $result = Get-TargetResource @mockParameters

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Name | Should -Be $mockParameters.Name

                $result.SameSubnetDelay | Should -BeNullOrEmpty
                $result.SameSubnetThreshold | Should -BeNullOrEmpty
                $result.CrossSubnetDelay | Should -BeNullOrEmpty
                $result.CrossSubnetThreshold | Should -BeNullOrEmpty
                $result.AddEvictDelay | Should -BeNullOrEmpty
                $result.BlockCacheSize | Should -BeNullOrEmpty
                $result.ClusterLogLevel | Should -BeNullOrEmpty
                $result.ClusterLogSize | Should -BeNullOrEmpty
                $result.CrossSiteDelay | Should -BeNullOrEmpty
                $result.CrossSiteThreshold | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.DatabaseReadWriteMode | Should -BeNullOrEmpty
                $result.DefaultNetworkRole | Should -BeNullOrEmpty
                $result.DrainOnShutdown | Should -BeNullOrEmpty
                $result.DynamicQuorum | Should -BeNullOrEmpty
                $result.NetftIPSecEnabled | Should -BeNullOrEmpty
                $result.QuarantineDuration | Should -BeNullOrEmpty
                $result.PreferredSite | Should -BeNullOrEmpty
                $result.QuarantineThreshold | Should -BeNullOrEmpty
                $result.ShutdownTimeoutInMinutes | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'ClusterProperty\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Get-Cluster -MockWith {
            [PSCustomObject] @{
                Description          = ''
                PreferredSite        = ''
                SameSubnetDelay      = 1000
                SameSubnetThreshold  = 5
                CrossSubnetDelay     = 1000
                CrossSubnetThreshold = 5
            }
        }
    }

    Context 'When setting a single integer cluster property' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name            = 'Cluster1'
                    SameSubnetDelay = 2000
                }

                Set-TargetResource @mockParameters | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When setting multiple integer cluster properties' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name                = 'Cluster1'
                    SameSubnetDelay     = 2000
                    SameSubnetThreshold = 5
                }

                Set-TargetResource @mockParameters | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When setting a single string cluster property' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name        = 'Cluster1'
                    Description = 'Exchange DAG'
                }

                Set-TargetResource @mockParameters | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When setting a single string cluster property to an empty string' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name        = 'Cluster1'
                    Description = ''
                }

                Set-TargetResource @mockParameters | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When setting a multiple string cluster properties' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name          = 'Cluster1'
                    Description   = 'Exchange DAG'
                    PreferredSite = 'London'
                }

                Set-TargetResource @mockParameters | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'ClusterProperty\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-Cluster -MockWith {
            [PSCustomObject] @{
                AddEvictDelay        = 60
                BlockCacheSize       = 1024
                CrossSubnetDelay     = 1000
                CrossSubnetThreshold = 5
                Description          = ''
                PreferredSite        = 'Default-First-Site-Name'
                SameSubnetDelay      = 1000
                SameSubnetThreshold  = 5
            }
        }
    }

    Context 'When the resource is in the desired state' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Parameters = @{
                        SameSubnetDelay     = 1000
                        SameSubnetThreshold = 5
                    }
                }
                @{
                    Parameters = @{
                        SameSubnetDelay = 1000
                    }
                }
                @{
                    Parameters = @{
                        PreferredSite = 'Default-First-Site-Name'
                    }
                }
                @{
                    Parameters = @{
                        PreferredSite = 'Default-First-Site-Name'
                        Description   = ''
                    }
                }
                @{
                    Parameters = @{
                        BlockCacheSize = 1024
                    }
                }
                @{
                    Parameters = @{
                        PreferredSite   = 'Default-First-Site-Name'
                        Description     = ''
                        AddEvictDelay   = 60
                        SameSubnetDelay = 1000
                    }
                }
                @{
                    Parameters = @{
                        Description = ''
                    }
                }
            )
        }

        It 'Should return the correct result' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name = 'Cluster1'
                }

                Test-TargetResource @mockParameters @parameters | Should -BeTrue
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the resource is not in the desired state' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Parameters = @{
                        SameSubnetDelay = 2000
                    }
                }
                @{
                    Parameters = @{
                        SameSubnetDelay     = 2000
                        SameSubnetThreshold = 6
                    }
                }
                @{
                    Parameters = @{
                        Description = 'Exchange DAG'
                    }
                }
                @{
                    Parameters = @{
                        PreferredSite = 'Default-First-Site-Name'
                        Description   = 'Exchange DAG'
                    }
                }
                @{
                    Parameters = @{
                        BlockCacheSize = 2048
                    }
                }
                @{
                    Parameters = @{
                        PreferredSite   = 'Default-First-Site-Name'
                        Description     = 'Exchange DAG'
                        AddEvictDelay   = 60
                        SameSubnetDelay = 1500
                    }
                }
            )
        }

        It 'Should return the correct result' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name = 'Cluster1'
                }

                Test-TargetResource @mockParameters @parameters | Should -BeFalse
            }

            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
        }
    }
}
