$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xClusterPreferredOwner'

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
        $mockPreferredOwnerNode1 = 'Node1'
        $mockPreferredOwnerNode2 = 'Node2'
        $mockPreferredOwnerNode3 = 'Node3'
        $mockDesiredPreferredOwnerNodes = @($mockPreferredOwnerNode1, $mockPreferredOwnerNode2)
        $mockAllPreferredOwnerNodes = @($mockPreferredOwnerNode1, $mockPreferredOwnerNode2, $mockPreferredOwnerNode3)

        $mockWrongPreferredOwnerNode1 = 'Node4'
        $mockWrongPreferredOwnerNode2 = 'Node5'
        $mockWrongPreferredOwnerNodes = @($mockWrongPreferredOwnerNode1, $mockWrongPreferredOwnerNode2)

        $mockKnownClusterResourceName = 'Resource1'
        $mockUnknownClusterResourceName = 'UnknownResource'

        $mockDefaultTestParameters = @{
            ClusterGroup = 'ClusterGroup1'
            ClusterName  = 'ClusterName1'
        }

        $mockTestParameters_Present_DesiredPreferredOwners = $mockDefaultTestParameters.Clone()
        $mockTestParameters_Present_DesiredPreferredOwners += @{
            Nodes            = $mockDesiredPreferredOwnerNodes
            ClusterResources = $mockKnownClusterResourceName
            Ensure           = 'Present'
        }

        $mockTestParameters_Present_AllPreferredOwners = $mockDefaultTestParameters.Clone()
        $mockTestParameters_Present_AllPreferredOwners += @{
            Nodes            = $mockAllPreferredOwnerNodes
            ClusterResources = $mockKnownClusterResourceName
            Ensure           = 'Present'
        }

        $mockTestParameters_Present_WrongPreferredOwnerNodes = $mockDefaultTestParameters.Clone()
        $mockTestParameters_Present_WrongPreferredOwnerNodes += @{
            Nodes            = $mockWrongPreferredOwnerNodes
            ClusterResources = $mockKnownClusterResourceName
            Ensure           = 'Present'
        }

        $mockTestParameters_Present_WrongClusterResources = $mockDefaultTestParameters.Clone()
        $mockTestParameters_Present_WrongClusterResources += @{
            Nodes            = $mockDesiredPreferredOwnerNodes
            ClusterResources = $mockUnknownClusterResourceName
            Ensure           = 'Present'
        }

        $mockTestParameters_Absent_ButPreferredOwnersExist = $mockDefaultTestParameters.Clone()
        $mockTestParameters_Absent_ButPreferredOwnersExist += @{
            Nodes            = $mockDesiredPreferredOwnerNodes
            ClusterResources = $mockKnownClusterResourceName
            Ensure           = 'Absent'
        }

        $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist = $mockDefaultTestParameters.Clone()
        $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist += @{
            Nodes            = $mockWrongPreferredOwnerNodes
            ClusterResources = $mockKnownClusterResourceName
            Ensure           = 'Absent'
        }

        $mockGetClusterGroup = {
            @{
                Name      = 'ClusterGroup1'
                OwnerNode = 'Node1'
                State     = 'Online'
            }
        }

        $mockGetClusterGroup_ParameterFilter = {
            $Cluster -eq 'ClusterName1'
        }

        $GetClusterOwnerNode = {
            @{
                ClusterObject = 'ClusterName1'
                OwnerNodes    = @(
                    @{name = $mockPreferredOwnerNode1}
                    @{name = $mockPreferredOwnerNode2}
                    @{name = $mockPreferredOwnerNode3}
                )
            }
        }

        $mockGetClusterNode = {
            @{
                Name = $mockDesiredPreferredOwnerNodes
            }
        }

        $mockGetClusterResource = {
            @{
                Name         = $mockKnownClusterResourceName
                State        = 'Online'
                OwnerGroup   = 'ClusterGroup1'
                ResourceType = 'type1'
            }
        }

        Describe 'xClusterDisk\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName 'Get-ClusterGroup' -ParameterFilter $mockGetClusterGroup_ParameterFilter -MockWith $mockGetClusterGroup
                Mock -CommandName 'Get-ClusterOwnerNode' -MockWith $GetClusterOwnerNode
                Mock -CommandName 'Get-ClusterNode' -MockWith $mockGetClusterNode
                Mock -CommandName 'Get-ClusterResource' -MockWith $mockGetClusterResource
            }

            Context 'When the system is not in the desired state' {
                Context 'When Ensure is set to ''Present'' but the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the correct type' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_WrongPreferredOwnerNodes
                        $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_WrongPreferredOwnerNodes
                        $getTargetResourceResult.ClusterGroup | Should -Be $mockTestParameters_Present_WrongPreferredOwnerNodes.ClusterGroup
                        $getTargetResourceResult.ClusterName  | Should -Be $mockTestParameters_Present_WrongPreferredOwnerNodes.ClusterName
                        $getTargetResourceResult.Ensure       | Should -Be $mockTestParameters_Present_WrongPreferredOwnerNodes.Ensure
                    }

                    It 'Should return the wrong preferred owner nodes and the right cluster resources' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_WrongPreferredOwnerNodes
                        $getTargetResourceResult.Nodes            | Should -Not -Be $mockTestParameters_Present_WrongPreferredOwnerNodes.Nodes
                        $getTargetResourceResult.ClusterResources | Should -Be $mockTestParameters_Present_WrongPreferredOwnerNodes.ClusterResources
                    }
                }

                Context 'When Ensure is set to ''Present'' but the preferred owner is a possible owner of the cluster nodes but the cluster resources is missing' {
                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_WrongClusterResources
                        $getTargetResourceResult.ClusterGroup | Should -Be $mockTestParameters_Present_WrongClusterResources.ClusterGroup
                        $getTargetResourceResult.ClusterName  | Should -Be $mockTestParameters_Present_WrongClusterResources.ClusterName
                        $getTargetResourceResult.Ensure       | Should -Be $mockTestParameters_Present_WrongClusterResources.Ensure
                    }

                    It 'Should return the correct preferred owner nodes and the wrong cluster resources' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_WrongClusterResources
                        $getTargetResourceResult.Nodes            | Should -Be $mockAllPreferredOwnerNodes
                        $getTargetResourceResult.ClusterResources | Should -Be $mockTestParameters_Present_WrongClusterResources.ClusterResources
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the preferred owner is still a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Absent_ButPreferredOwnersExist
                        $getTargetResourceResult.ClusterGroup | Should -Be $mockTestParameters_Absent_ButPreferredOwnersExist.ClusterGroup
                        $getTargetResourceResult.ClusterName  | Should -Be $mockTestParameters_Absent_ButPreferredOwnersExist.ClusterName
                        $getTargetResourceResult.Ensure       | Should -Be $mockTestParameters_Absent_ButPreferredOwnersExist.Ensure
                    }

                    It 'Should return the correct preferred owner nodes and the wrong cluster resources' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Absent_ButPreferredOwnersExist
                        $getTargetResourceResult.Nodes            | Should -Be $mockAllPreferredOwnerNodes
                        $getTargetResourceResult.ClusterResources | Should -Be $mockTestParameters_Absent_ButPreferredOwnersExist.ClusterResources
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When Ensure is set to ''Present'' and the preferred owner is a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_DesiredPreferredOwners
                        $getTargetResourceResult.ClusterGroup | Should -Be $mockTestParameters_Present_DesiredPreferredOwners.ClusterGroup
                        $getTargetResourceResult.ClusterName  | Should -Be $mockTestParameters_Present_DesiredPreferredOwners.ClusterName
                        $getTargetResourceResult.Ensure       | Should -Be $mockTestParameters_Present_DesiredPreferredOwners.Ensure
                    }

                    It 'Should return the right preferred owner nodes and the right cluster resources' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Present_DesiredPreferredOwners
                        $getTargetResourceResult.Nodes            | Should -Be $mockAllPreferredOwnerNodes
                        $getTargetResourceResult.ClusterResources | Should -Be $mockTestParameters_Present_DesiredPreferredOwners.ClusterResources
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Absent_AndPreferredOwnersDoesNotExist
                        $getTargetResourceResult.ClusterGroup | Should -Be $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist.ClusterGroup
                        $getTargetResourceResult.ClusterName  | Should -Be $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist.ClusterName
                        $getTargetResourceResult.Ensure       | Should -Be $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist.Ensure
                    }

                    It 'Should return the correct preferred owner nodes and the wrong cluster resources' {
                        $getTargetResourceResult = Get-TargetResource @mockTestParameters_Absent_AndPreferredOwnersDoesNotExist
                        $getTargetResourceResult.Nodes            | Should -Not -Be $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist.Nodes
                        $getTargetResourceResult.ClusterResources | Should -Be $mockTestParameters_Absent_AndPreferredOwnersDoesNotExist.ClusterResources
                    }
                }
            }
        }

        Describe 'xClusterDisk\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName 'Get-ClusterGroup' -ParameterFilter $mockGetClusterGroup_ParameterFilter -MockWith $mockGetClusterGroup
                Mock -CommandName 'Get-ClusterOwnerNode' -MockWith $GetClusterOwnerNode
                Mock -CommandName 'Get-ClusterNode' -MockWith $mockGetClusterNode
                Mock -CommandName 'Get-ClusterResource' -MockWith $mockGetClusterResource
            }

            Context 'When the system is not in the desired state' {
                Context 'When Ensure is set to ''Present'' but the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the result as $false ' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters_Present_WrongPreferredOwnerNodes
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                # This test is skipped due to a logic error in the code that needs to be fixed (issue #94).
                Context 'When Ensure is set to ''Present'' but the preferred owner is a possible owner of the cluster nodes but the cluster resources is missing' {
                    It 'Should return the result as $false ' -Skip {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters_Present_WrongClusterResources
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the preferred owner is still a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the result as $false ' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters_Absent_ButPreferredOwnersExist
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Context 'When Ensure is set to ''Present'' and the preferred owners is a possible owners of the cluster nodes and the cluster resources, but there are one additional preferred owner on the nodes that should not be present' {
                    It 'Should return the result as $false ' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters_Present_DesiredPreferredOwners
                        $testTargetResourceResult | Should -Be $false
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When Ensure is set to ''Present'' and the preferred owner is a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the result as $true ' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters_Present_AllPreferredOwners
                        $testTargetResourceResult | Should -Be $true
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should return the result as $true ' {
                        $testTargetResourceResult = Test-TargetResource @mockTestParameters_Absent_AndPreferredOwnersDoesNotExist
                        $testTargetResourceResult | Should -Be $true
                    }
                }
            }
        }

        Describe 'xClusterDisk\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName 'Get-ClusterGroup' -ParameterFilter $mockGetClusterGroup_ParameterFilter -MockWith $mockGetClusterGroup
                Mock -CommandName 'Get-ClusterOwnerNode' -MockWith $GetClusterOwnerNode
                Mock -CommandName 'Get-ClusterNode' -MockWith $mockGetClusterNode
                Mock -CommandName 'Get-ClusterResource' -MockWith $mockGetClusterResource
                Mock -CommandName 'Set-ClusterOwnerNode'
                Mock -CommandName 'Move-ClusterGroup'
            }

            Context 'When the system is not in the desired state' {
                Context 'When Ensure is set to ''Present'' but the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should set the preferred owners' {
                        { Set-TargetResource @mockTestParameters_Present_WrongPreferredOwnerNodes } | Should -Not -Throw

                        # Called three times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                        Assert-MockCalled -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                        # Moves the cluster group to the target node (issue #64 open).
                        Assert-MockCalled -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Ensure is set to ''Present'' but the preferred owner is a possible owner of the cluster nodes but the cluster resources is missing' {
                    It 'Should set the preferred owners' {
                        { Set-TargetResource @mockTestParameters_Present_WrongClusterResources } | Should -Not -Throw

                        # Called two times, one times for each node (2 nodes), and not called for cluster resource because cluster resource is missing.
                        Assert-MockCalled -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 2 -Scope It

                        # Moves the cluster group to the target node (issue #64 open).
                        Assert-MockCalled -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the preferred owner is still a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should remove the preferred owners, leaving one preferred owner' {
                        { Set-TargetResource @mockTestParameters_Absent_ButPreferredOwnersExist } | Should -Not -Throw

                        # Called two times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                        Assert-MockCalled -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                        # Moves the cluster group to the target node (issue #64 open).
                        Assert-MockCalled -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                # This tests wrongly calls Set-ClusterOwnerNode and Move-ClusterGroup. See issue #97.
                Context 'When Ensure is set to ''Present'' and the preferred owner is a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should do nothing' {
                        { Set-TargetResource @mockTestParameters_Present_AllPreferredOwners } | Should -Not -Throw

                        # Called two times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                        Assert-MockCalled -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                        # Moves the cluster group to the target node (issue #64 open).
                        Assert-MockCalled -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
                    }
                }

                # This tests wrongly calls Set-ClusterOwnerNode and Move-ClusterGroup. See issue #97.
                Context 'When Ensure is set to ''Absent'' and the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
                    It 'Should do nothing' {
                        { Set-TargetResource @mockTestParameters_Absent_AndPreferredOwnersDoesNotExist } | Should -Not -Throw

                        # Called two times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                        Assert-MockCalled -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                        # Moves the cluster group to the target node (issue #64 open).
                        Assert-MockCalled -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
