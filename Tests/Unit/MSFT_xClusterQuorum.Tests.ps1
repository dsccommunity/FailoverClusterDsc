$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xClusterQuorum'

#region Header

# Unit Test Template Version: 1.3.0
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
        $mockQuorumType_NodeAndCloudMajority = 'NodeAndCloudMajority'
        $mockQuorumType_Unknown = 'Unknown'

        $mockQuorumTypeDisplayName = 'File Share Quorum Witness'

        $mockQuorumResourceName = 'Witness'
        $mockQuorumFileShareWitnessPath = '\\FILE01\CLUSTER01'
        $mockQuorumAccountName = 'AccountName'
        $mockQuorumAccessKey = 'USRuD354YbOHkPI35SUVyMj2W3odWekMIEdj3n2qAbc0yzqwpMwH-+M+GHJ27OuA5FkTxsbBF9qGc6r6UM3ipg=='

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

            switch ($mockDynamicExpectedQuorumType)
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
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = $mockDynamicQuorumTypeDisplayName
                }

                $mockQuorumType_NodeAndCloudMajority
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Cloud Witness'
                }

                $mockQuorumType_Unknown
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Unknown'
                }
            }

            $getClusterQuorumReturnValue
        }

        $mockGetClusterParameter_SharePath = {
            @(
                [PSCustomObject] @{
                    ClusterObject = $mockDynamicQuorumTypeDisplayName
                    Name          = 'SharePath'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = $mockQuorumFileShareWitnessPath
                }
            )
        }

        $mockGetClusterParameter_SharePath_ParameterFilter = {
            $Name -eq 'SharePath'
        }

        $mockGetClusterParameter_AccountName = {
            @(
                [PSCustomObject] @{
                    ClusterObject = 'File Share Witness'
                    Name          = 'AccountName'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = $mockQuorumAccountName
                }
            )
        }

        $mockGetClusterParameter_AccountName_ParameterFilter = {
            $Name -eq 'AccountName'
        }

        $mockSetClusterQuorum_NoWitness_ParameterFilter = {
            $NoWitness -eq $true
        }

        $mockSetClusterQuorum_DiskWitness_ParameterFilter = {
            $DiskWitness -eq $mockQuorumResourceName
        }

        $mockSetClusterQuorum_FileShareWitness_ParameterFilter = {
            $FileShareWitness -eq $mockQuorumResourceName
        }

        $mockSetClusterQuorum_DiskOnly_ParameterFilter = {
            $DiskOnly -eq $mockQuorumResourceName
        }

        $mockSetClusterQuorum_CloudWitness_ParameterFilter = {
            $CloudWitness -eq $true `
            -and $AccountName -eq $mockQuorumAccountName `
            -and $AccessKey -eq $mockQuorumAccessKey
        }

        $mockDefaultParameters = @{
            IsSingleInstance = 'Yes'
        }

        Describe 'xClusterQuorum\Get-TargetResource' {
            BeforeEach {
                Mock -CommandName 'Get-ClusterQuorum' -MockWith $mockGetClusterQuorum
                Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter_SharePath -ParameterFilter $mockGetClusterParameter_SharePath_ParameterFilter
                Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter_AccountName -ParameterFilter $mockGetClusterParameter_AccountName_ParameterFilter

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
                            $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeMajority
                            $getTargetResourceResult.Resource  | Should -Be $mockQuorumResourceName
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeMajority
                            $getTargetResourceResult.Resource  | Should -BeNullorEmpty
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
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeAndDiskMajority
                            $getTargetResourceResult.Resource  | Should -Be $mockQuorumResourceName
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeAndDiskMajority
                            $getTargetResourceResult.Resource  | Should -Be $mockQuorumResourceName
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
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeAndFileShareMajority
                            $getTargetResourceResult.Resource  | Should -Be $mockQuorumFileShareWitnessPath
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority
                            $mockDynamicQuorumTypeDisplayName = $mockQuorumTypeDisplayName
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeAndFileShareMajority
                            $getTargetResourceResult.Resource  | Should -Be $mockQuorumFileShareWitnessPath
                        }
                    }
                }

                Context 'When desired state should be NodeAndCloudMajority' {
                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndCloudMajority
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Type | Should -Be $mockQuorumType_NodeAndCloudMajority
                            $getTargetResourceResult.Resource  | Should -Be $mockQuorumAccountName
                        }
                    }
                }

                Context 'When desired state should be DiskOnly' {
                    BeforeEach {
                        $mockDynamicQuorumType = $mockQuorumType_DiskOnly
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.IsSingleInstance | Should -Be $mockTestParameters.IsSingleInstance
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters
                        $getTargetResourceResult.Type | Should -Be $mockQuorumType_DiskOnly
                        $getTargetResourceResult.Resource  | Should -Be $mockQuorumResourceName
                    }
                }

                Context 'When quorum type is unknown' {
                    Context 'When target node is Windows Server 2012 R2' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Unknown
                        }

                        It 'Should throw the correct error message' {
                            { Get-TargetResource @mockTestParameters } | Should -Throw ('Unknown quorum type: {0}' -f $mockQuorumType_Unknown)
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExpectedQuorumType = $mockQuorumType_Unknown
                        }

                        It 'Should throw the correct error message' {
                            { Get-TargetResource @mockTestParameters } | Should -Throw ('Unknown quorum resource: {0}' -f '@{Name=Witness; OwnerGroup=Cluster Group; ResourceType=}')
                        }
                    }
                }
            }
        }

        Describe 'xClusterQuorum\Test-TargetResource' {
            BeforeEach {
                Mock -CommandName 'Get-ClusterQuorum' -MockWith $mockGetClusterQuorum
                Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter_SharePath -ParameterFilter $mockGetClusterParameter_SharePath_ParameterFilter
                Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter_AccountName -ParameterFilter $mockGetClusterParameter_AccountName_ParameterFilter

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
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicQuorumResourceName = $mockQuorumResourceName

                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
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
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority

                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
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
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
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
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority
                            $mockDynamicQuorumTypeDisplayName = $mockQuorumTypeDisplayName
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
                        }
                    }
                }

                Context 'When desired state should be NodeAndCloudMajority' {
                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority

                            $mockTestParameters['Type'] = $mockQuorumType_NodeAndCloudMajority
                            $mockTestParameters['Resource'] = $mockQuorumAccountName
                            $mockTestParameters['StorageAccountAccessKey'] = $mockQuorumAccessKey
                        }

                        It 'Should return the value $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $false
                        }
                    }
                }

                Context 'When desired state should be DiskOnly' {
                    BeforeEach {
                        $mockDynamicQuorumType = $mockQuorumType_DiskOnly
                    }

                    It 'Should return the value $false' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters
                        $testTargetResourceResult | Should -Be $false
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
                            $testTargetResourceResult | Should -Be $true
                        }
                    }

                    Context 'When target node is Windows Server 2016 and newer' {
                        BeforeEach {
                            $mockDynamicQuorumType = $mockQuorumType_Majority
                            $mockTestParameters['Resource'] = $null

                            $mockDynamicExpectedQuorumType = $mockQuorumType_NodeMajority
                        }

                        It 'Should return the value $true' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameters
                            $testTargetResourceResult | Should -Be $true
                        }
                    }

                    Context 'When desired state should be NodeAndCloudMajority' {
                        Context 'When target node is Windows Server 2016 and newer' {
                            BeforeEach {
                                $mockDynamicQuorumType = $mockQuorumType_Majority
                                $mockDynamicExcpectedQuorumType = $mockQuorumType_NodeAndCloudMajority

                                $mockTestParameters['Type'] = $mockQuorumType_NodeAndCloudMajority
                                $mockTestParameters['Resource'] = $mockQuorumAccountName
                                $mockTestParameters['StorageAccountAccessKey'] = $mockQuorumAccessKey
                            }

                            It 'Should return the value $false' {
                                $testTargetResourceResult = Test-TargetResource @mockTestParameters
                                $testTargetResourceResult | Should -Be $true
                            }
                        }
                    }
                }
            }
        }

        Describe 'xClusterQuorum\Set-TargetResource' {
            BeforeEach {
                Mock -CommandName 'Set-ClusterQuorum'

                $mockTestParameters = $mockDefaultParameters.Clone()
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    $mockTestParameters['Type'] = $mockQuorumType_NodeMajority

                    $mockDynamicSetClusterQuorum_ExpectedQuorumType = $mockQuorumType_NodeMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should -Not -Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_NoWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    $mockTestParameters['Type'] = $mockQuorumType_NodeAndDiskMajority
                    $mockTestParameters['Resource'] = $mockQuorumResourceName

                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                    $mockDynamicSetClusterQuorum_ExpectedQuorumType = $mockQuorumType_NodeAndDiskMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should -Not -Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_DiskWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    $mockTestParameters['Type'] = $mockQuorumType_NodeAndFileShareMajority
                    $mockTestParameters['Resource'] = $mockQuorumResourceName

                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                    $mockDynamicSetClusterQuorum_ExpectedQuorumType = $mockQuorumType_NodeAndFileShareMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should -Not -Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_FileShareWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeAndCloudMajority' {
                BeforeEach {
                    $mockTestParameters['Type'] = $mockQuorumType_NodeAndCloudMajority
                    $mockTestParameters['Resource'] = $mockQuorumAccountName
                    $mockTestParameters['StorageAccountAccessKey'] = $mockQuorumAccessKey

                    $mockDynamicQuorumResourceName = $mockQuorumAccountName
                    $mockDynamicSetClusterQuorum_ExpectedQuorumType = $mockQuorumType_NodeAndCloudMajority
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should -Not -Throw

                    Assert-MockCalled -CommandName 'Set-ClusterQuorum' `
                                      -ParameterFilter $mockSetClusterQuorum_CloudWitness_ParameterFilter `
                                      -Exactly -Times 1 -Scope It
                }
            }

            Context 'When quorum type should be NodeMajority' {
                BeforeEach {
                    $mockTestParameters['Type'] = $mockQuorumType_DiskOnly
                    $mockTestParameters['Resource'] = $mockQuorumResourceName

                    $mockDynamicQuorumResourceName = $mockQuorumResourceName
                    $mockDynamicSetClusterQuorum_ExpectedQuorumType = $mockQuorumType_DiskOnly
                }

                It 'Should set the quorum in the cluster without throwing an error' {
                    { Set-TargetResource @mockTestParameters } |  Should -Not -Throw

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
