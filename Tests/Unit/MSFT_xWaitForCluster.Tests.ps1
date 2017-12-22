$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xWaitForCluster'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'FailoverClusters.stubs.psm1') -Global -Force
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockDomainName = 'domain.local'
        $mockClusterName = 'CLUSTER001'
        $mockRetryIntervalSec = '1'
        $mockRetryCount = '1'

        $mockGetCimInstance = {
            return [PSCustomObject] @{
                Domain = $mockDynamicDomainName
            }
        }

        $mockCimInstance_ParameterFilter = {
            $ClassName -eq 'Win32_ComputerSystem'
        }

        $mockGetCluster = {
            return [PSCustomObject] @{
                Domain = $mockDomainName
                Name   = $mockClusterName
            }
        }

        $mockGetCluster_ParameterFilter = {
            $Name -eq $mockClusterName -and $Domain -eq $mockDomainName
        }

        $mockDefaultParameters = @{
            Name             = $mockClusterName
            RetryIntervalSec = $mockRetryIntervalSec
            RetryCount       = $mockRetryCount
        }

        Describe 'xCluster\Get-TargetResource' -Tag Get {
            Context 'When the system is either in the desired state or not in the desired state' {
                It 'Returns a [System.Collection.Hashtable] type' {
                    $getTargetResourceResult = Get-TargetResource @mockDefaultParameters
                    $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                }

                It 'Returns the same values passed as parameters' {
                    $getTargetResourceResult = Get-TargetResource @mockDefaultParameters
                    $getTargetResourceResult.Name              | Should -Be $mockDefaultParameters.Name
                    $getTargetResourceResult.RetryIntervalSec  | Should -Be $mockDefaultParameters.RetryIntervalSec
                    $getTargetResourceResult.RetryCount        | Should -Be $mockDefaultParameters.RetryCount
                }

                Assert-VerifiableMock
            }
        }

        Describe 'xCluster\Set-TargetResource' -Tag Set {
            Context 'When computers domain name cannot be evaluated' {
                $mockDynamicDomainName = $null

                It 'Should throw the correct error message' {
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockCimInstance_ParameterFilter -Verifiable

                    $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.ClusterAbsentAfterTimeOut -f $mockClusterName, ($mockRetryCount-1), $mockRetryIntervalSec)
                    { Set-TargetResource @mockDefaultParameters } | Should -Throw $mockCorrectErrorRecord
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockCimInstance_ParameterFilter -Verifiable
                }

                Context 'When the cluster does not exist' {
                    Context 'When Get-Cluster throws an error' {
                        BeforeEach {
                            # This is used for the evaluation of a cluster that does not exist
                            Mock -CommandName Get-Cluster -MockWith {
                                throw 'Mock Get-Cluster throw error'
                            } -ParameterFilter $mockGetCluster_ParameterFilter
                        }

                        $mockDynamicDomainName = $mockDomainName

                        It 'Should throw the correct error message' {
                            $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.ClusterAbsentAfterTimeOut -f $mockClusterName, $mockRetryCount, $mockRetryIntervalSec)
                            { Set-TargetResource @mockDefaultParameters } | Should -Throw $mockCorrectErrorRecord
                        }

                        Assert-VerifiableMock
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the cluster exist' {
                    BeforeEach {
                        Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockCimInstance_ParameterFilter -Verifiable
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                    }

                    $mockDynamicDomainName = $mockDomainName

                    It 'Should not throw any error' {
                        { Set-TargetResource @mockDefaultParameters } | Should -Not -Throw
                    }

                    Assert-VerifiableMock
                }
            }
        }

        Describe 'xCluster\Test-TargetResource' -Tag Test {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockCimInstance_ParameterFilter -Verifiable
            }

            Context 'When computers domain name cannot be evaluated' {
                $mockDynamicDomainName = $null

                It 'Should return the value $false' {
                    $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                    $testTargetResourceResult | Should -Be $false
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the cluster does not exist' {
                    Context 'When Get-Cluster throws an error' {
                        BeforeEach {
                            # This is used for the evaluation of a cluster that does not exist.
                            Mock -CommandName Get-Cluster -MockWith {
                                throw 'Mock Get-Cluster throw error'
                            } -ParameterFilter $mockGetCluster_ParameterFilter
                        }

                        $mockDynamicDomainName = $mockDomainName

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                            $testTargetResourceResult | Should -Be $false
                        }

                        Assert-VerifiableMock
                    }

                    Context 'When Get-Cluster returns nothing' {
                        BeforeEach {
                            # This is used for the evaluation of a cluster that does not exist.
                            Mock -CommandName Get-Cluster -MockWith {
                                $null
                            } -ParameterFilter $mockGetCluster_ParameterFilter
                        }

                        $mockDynamicDomainName = $mockDomainName

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                            $testTargetResourceResult | Should -Be $false
                        }

                        Assert-VerifiableMock
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the cluster exist' {
                    BeforeEach {
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                    }

                    $mockDynamicDomainName = $mockDomainName

                    It 'Should return the value $true' {
                        $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                        $testTargetResourceResult | Should -Be $true
                    }

                    Assert-VerifiableMock
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
