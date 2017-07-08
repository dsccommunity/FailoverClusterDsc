$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xClusterQuorum'

#region Header

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

#endregion Header

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
        $mockQuorumType_Majority = 'Majority'
        $mockQuorumType_NodeMajority = 'NodeMajority'
        $mockQuorumType_NodeAndDiskMajority = 'NodeAndDiskMajority'
        $mockQuorumType_NodeAndFileShareMajority = 'NodeAndFileShareMajority'
        $mockQuorumType_DiskOnly = 'DiskOnly'
        $mockQuorumType_Unknown = 'Unknown'

        $mockQuorumResourceName = 'Witness'
        $mockQuorumFileShareWitnessPath = '\\FILE01\CLUSTER01'

        $mockGetClusterQuorum = {
            $getClusterQuorumReturnValue = [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = $mockDynamicQuorumType
                QuorumResource = [PSCustomObject] @{
                    Name         = $mockDynamicQuorumResourceName
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = [PSCustomObject] @{
                        DisplayName = 'Physical Disk'
                    }
                }
            }

            switch ($mockDynamicExcpectedQuorumType)
            {
                $mockQuorumType_NodeMajority
                {
                    $getClusterQuorumReturnValue.QuorumResource = $null
                }

                $mockQuorumType_NodeAndDiskMajority
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Physical Disk'
                }

                $mockQuorumType_NodeAndFileShareMajority
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'File Share Witness'
                }

                $mockQuorumType_Unknown
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Unknown'
                }
            }

            $getClusterQuorumReturnValue
        }

        $mockGetClusterParameter = {
            @(
                [PSCustomObject] @{
                    ClusterObject = 'File Share Witness'
                    Name          = 'SharePath'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = $mockQuorumFileShareWitnessPath
                }
            )
        }

        $mockGetClusterParameter_ParameterFilter = {
            $Name -eq 'SharePath'
        }

        $mockSetClusterQuorum_NoWitness_ParameterFilter = {
            $NoWitness -eq $true
        }

        $mockSetClusterQuorum_DiskWitness_ParameterFilter = {
            $PSBoundParameters.ContainsKey('DiskWitness') -eq $true
        }

        $mockSetClusterQuorum_FileShareWitness_ParameterFilter = {
            $PSBoundParameters.ContainsKey('FileShareWitness') -eq $true
        }

        $mockSetClusterQuorum_DiskOnly_ParameterFilter = {
            $PSBoundParameters.ContainsKey('DiskOnly') -eq $true
        }

        $mockSetClusterQuorum = {
            $wrongParameters = $false

            # Evaluate if the Set-ClusterQuorum is called with the correct parameters.
            switch ($mockDynamicSetClusterQuorum_ExcpectedQuorumType)
            {
                $mockQuorumType_NodeMajority
                {
                    if (-not $NoWitness)
                    {
                        $wrongParameters = $true
                    }
                }

                $mockQuorumType_NodeAndDiskMajority
                {
                    if ($DiskWitness -ne $mockDynamicQuorumResourceName)
                    {
                        $wrongParameters = $true
                    }
                }

                $mockQuorumType_NodeAndFileShareMajority
                {
                    if ($FileShareWitness -ne $mockDynamicQuorumResourceName)
                    {
                        $wrongParameters = $true
                    }
                }

                $mockQuorumType_DiskOnly
                {
                    if ($DiskOnly -ne $mockDynamicQuorumResourceName)
                    {
                        $wrongParameters = $true
                    }
                }

                default
                {
                    $wrongParameters = $true
                }
            }

            if ($wrongParameters)
            {
                throw 'Mock Set-ClusterQuorum was called with the wrong parameters.'
            }
        }

        $mockDefaultParameters = @{
            IsSingleInstance = 'Yes'
        }

        Describe 'xClusterQuorum\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName 'Get-ClusterQuorum' -MockWith $mockGetClusterQuorum
                Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter -ParameterFilter $mockGetClusterParameter_ParameterFilter

                $mockTestParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is either in the desired state or not in the desired state' {
                BeforeAll {
                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                }

                Context 'When quorum type should be NodeMajority' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the correct type' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult | Should BeOfType [System.Collections.Hashtable]
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should Be $mockQuorumType_NodeMajority
                            $getTargetResourceResult.Resource  | Should Be $mockQuorumResourceName
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should Be $mockQuorumType_NodeMajority
                            $getTargetResourceResult.Resource  | Should BeNullorEmpty
                        }
                    }
                }

                Context 'When desired state should be NodeAndDiskMajority' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should Be $mockQuorumType_NodeAndDiskMajority
                            $getTargetResourceResult.Resource  | Should Be $mockQuorumResourceName
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should Be $mockQuorumType_NodeAndDiskMajority
                            $getTargetResourceResult.Resource  | Should Be $mockQuorumResourceName
                        }
                    }
                }

                Context 'When desired state should be NodeAndFileShareMajority' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeAndFileShareMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should Be $mockQuorumType_NodeAndFileShareMajority
                            $getTargetResourceResult.Resource  | Should Be $mockQuorumFileShareWitnessPath
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should Be $mockQuorumType_NodeAndFileShareMajority
                            $getTargetResourceResult.Resource  | Should Be $mockQuorumFileShareWitnessPath
                        }
                    }
                }

                Context 'When desired state should be DiskOnly' {
                    BeforeEach {
                        $mockDynamicQuorumType = $mockQuorumType_DiskOnly
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.IsSingleInstance | Should Be $mockTestParameters.IsSingleInstance
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.Type | Should Be $mockQuorumType_DiskOnly
                        $getTargetResourceResult.Resource  | Should Be $mockQuorumResourceName
                    }
                }

                Context 'When quorum type is unknown' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Unknown
                        }

                        It 'Should throw the correct error message' {
                            { Get-TargetResource @mockTestParameters } | Should Throw ('Unknown quorum type: {0}' -f $mockQuorumType_Unknown)
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_Unknown
                        }

                        It 'Should throw the correct error message' {
                            { Get-TargetResource @mockTestParameters } | Should Throw ('Unknown quorum resource: {0}' -f '@{Name=Witness; OwnerGroup=Cluster Group; ResourceType=}')
                        }
                    }
                }
            }

            Context 'When the system is not in the desired state' {
            }
        }

        Describe 'xClusterQuorum\Test-TargetResource' {
            BeforeEach {
                Mock -CommandName 'Get-ClusterQuorum' -MockWith $mockGetClusterQuorum
                Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter -ParameterFilter $mockGetClusterParameter_ParameterFilter

                $mockTestParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is not in the desired state' {
                Context 'When quorum type should be NodeMajority' {
                    BeforeEach {
                        $mockTestParameters['Type'] = $mockQuorumType_NodeMajority
                        $mockTestParameters['Resource'] = $mockQuorumResourceName
                    }

                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeAndDiskMajority
                            $mockDynamicQuorumResourceName = $mockQuorumResourceName
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicQuorumResourceName = $mockQuorumResourceName

                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }
                }

                Context 'When quorum type is NodeMajority but the resource is not in desired state' {
                    BeforeEach {
                        $mockTestParameters['Type'] = $mockQuorumType_NodeMajority
                        $mockTestParameters['Resource'] = $mockQuorumResourceName
                    }

                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeMajority
                            $mockDynamicQuorumResourceName = 'Unknown'
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority

                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }
                }

                Context 'When desired state should be NodeAndDiskMajority' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }
                }

                Context 'When desired state should be NodeAndFileShareMajority' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeAndFileShareMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $false
                        }
                    }
                }

                Context 'When desired state should be DiskOnly' {
                    BeforeEach {
                        $mockDynamicQuorumType = $mockQuorumType_DiskOnly
                    }

                    It 'Should return the value $false' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters
                        $testTargetResourceResult | Should Be $false
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When quorum type is NodeMajority but the resource is not in desired state' {
                    BeforeEach {
                        $mockTestParameters['Type'] = $mockQuorumType_NodeMajority
                        $mockTestParameters['Resource'] = $mockQuorumResourceName
                    }

                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_NodeMajority
                            $mockDynamicQuorumResourceName = $mockQuorumResourceName
                        }

                        It 'Should return the value $true' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $true
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockTestParameters['Resource'] = $null

                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the value $true' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should Be $true
                        }
                    }
                }
            }
        }

        Describe 'xClusterQuorum\Set-TargetResource' {
            BeforeEach {
                $mockTestParameters = $mockDefaultParameters.Clone()
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    Mock -CommandName 'Set-ClusterQuorum' -MockWith $mockSetClusterQuorum `
                        -ParameterFilter $mockSetClusterQuorum_NoWitness_ParameterFilter

                    $mockTestParameters['Type'] = $mockQuorumType_NodeMajority

                    $mockDynamicSetClusterQuorum_ExcpectedQuorumType = $mockQuorumType_NodeMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should Not Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_NoWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    Mock -CommandName 'Set-ClusterQuorum' -MockWith $mockSetClusterQuorum `
                        -ParameterFilter $mockSetClusterQuorum_DiskWitness_ParameterFilter

                    $mockTestParameters['Type'] = $mockQuorumType_NodeAndDiskMajority
                    $mockTestParameters['Resource'] = $mockQuorumResourceName

                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                    $mockDynamicSetClusterQuorum_ExcpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should Not Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_DiskWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    Mock -CommandName 'Set-ClusterQuorum' -MockWith $mockSetClusterQuorum `
                        -ParameterFilter $mockSetClusterQuorum_FileShareWitness_ParameterFilter

                    $mockTestParameters['Type'] = $mockQuorumType_NodeAndFileShareMajority
                    $mockTestParameters['Resource'] = $mockQuorumResourceName

                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                    $mockDynamicSetClusterQuorum_ExcpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should Not Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_FileShareWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    Mock -CommandName 'Set-ClusterQuorum' -MockWith $mockSetClusterQuorum `
                        -ParameterFilter $mockSetClusterQuorum_DiskOnly_ParameterFilter

                    $mockTestParameters['Type'] = $mockQuorumType_DiskOnly
                    $mockTestParameters['Resource'] = $mockQuorumResourceName

                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                    $mockDynamicSetClusterQuorum_ExcpectedQuorumType = $mockQuorumType_DiskOnly
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should Not Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_DiskOnly_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
