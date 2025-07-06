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
    $script:DSCResourceName = 'DSC_ClusterPreferredOwner'

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

Describe 'ClusterPreferredOwner\Get-TargetResource' -Tag 'Get' {
    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClusterGroup -ParameterFilter {
                $Cluster -eq 'ClusterName1'
            } -MockWith {
                @{
                    Name      = 'ClusterGroup1'
                    OwnerNode = 'Node1'
                    State     = 'Online'
                }
            }

            Mock -CommandName Get-ClusterOwnerNode -MockWith {
                @{
                    ClusterObject = 'ClusterName1'
                    OwnerNodes    = @(
                        @{ name = 'Node1' }
                        @{ name = 'Node2' }
                        @{ name = 'Node3' }
                    )
                }
            }

            Mock -CommandName Get-ClusterNode -MockWith {
                @{
                    Name = @('Node1', 'Node2')
                }
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'Resource1'
                    State        = 'Online'
                    OwnerGroup   = 'ClusterGroup1'
                    ResourceType = 'type1'
                }
            }
        }

        Context 'When Ensure is set to ''Present'' but the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node4', 'Node5')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.ClusterGroup | Should -Be $mockParameters.ClusterGroup
                    $result.ClusterName | Should -Be $mockParameters.ClusterName
                    $result.Ensure | Should -Be $mockParameters.Ensure

                    $result.Nodes | Should -Not -Contain $mockParameters.Nodes
                    $result.ClusterResources | Should -Be $mockParameters.ClusterResources
                }
            }
        }

        Context 'When Ensure is set to ''Present'' but the preferred owner is a possible owner of the cluster nodes but the cluster resources is missing' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'UnknownResource'
                        Ensure           = 'Present'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.ClusterGroup | Should -Be $mockParameters.ClusterGroup
                    $result.ClusterName | Should -Be $mockParameters.ClusterName
                    $result.Ensure | Should -Be $mockParameters.Ensure

                    $result.Nodes | Should -Be @('Node1', 'Node2', 'Node3')
                    $result.ClusterResources | Should -Be $mockParameters.ClusterResources
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the preferred owner is still a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Absent'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.ClusterGroup | Should -Be $mockParameters.ClusterGroup
                    $result.ClusterName | Should -Be $mockParameters.ClusterName
                    $result.Ensure | Should -Be $mockParameters.Ensure

                    $result.Nodes | Should -Be @('Node1', 'Node2', 'Node3')
                    $result.ClusterResources | Should -Be $mockParameters.ClusterResources
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClusterGroup -ParameterFilter {
                $Cluster -eq 'ClusterName1'
            } -MockWith {
                @{
                    Name      = 'ClusterGroup1'
                    OwnerNode = 'Node1'
                    State     = 'Online'
                }
            }

            Mock -CommandName Get-ClusterOwnerNode -MockWith {
                @{
                    ClusterObject = 'ClusterName1'
                    OwnerNodes    = @(
                        @{ name = 'Node1' }
                        @{ name = 'Node2' }
                        @{ name = 'Node3' }
                    )
                }
            }

            Mock -CommandName Get-ClusterNode -MockWith {
                @{
                    Name = @('Node1', 'Node2')
                }
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'Resource1'
                    State        = 'Online'
                    OwnerGroup   = 'ClusterGroup1'
                    ResourceType = 'type1'
                }
            }
        }

        Context 'When Ensure is set to ''Present'' and the preferred owner is a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.ClusterGroup | Should -Be $mockParameters.ClusterGroup
                    $result.ClusterName | Should -Be $mockParameters.ClusterName
                    $result.Ensure | Should -Be $mockParameters.Ensure

                    $result.Nodes | Should -Be @('Node1', 'Node2', 'Node3')
                    $result.ClusterResources | Should -Be $mockParameters.ClusterResources
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node4', 'Node5')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Absent'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.ClusterGroup | Should -Be $mockParameters.ClusterGroup
                    $result.ClusterName | Should -Be $mockParameters.ClusterName
                    $result.Ensure | Should -Be $mockParameters.Ensure
                    $result.Nodes | Should -Not -Be $mockParameters.Nodes
                    $result.ClusterResources | Should -Be $mockParameters.ClusterResources
                }
            }
        }
    }
}

Describe 'ClusterPreferredOwner\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    ClusterGroup     = 'ClusterGroup1'
                    ClusterName      = 'ClusterName1'
                    Nodes            = @('Node1', 'Node2')
                    ClusterResources = 'Resource1'
                    Ensure           = 'Present'
                }
            }
        }

        Context 'When Ensure is set to ''Present'' but the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node4', 'Node5')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        # This test is skipped due to a logic error in the code that needs to be fixed (issue #94).
        Context 'When Ensure is set to ''Present'' but the preferred owner is a possible owner of the cluster nodes but the cluster resources is missing' {
            It 'Should return the result as $false' -Skip {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'UnknownResource'
                        Ensure           = 'Present'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the preferred owner is still a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Absent'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When Ensure is set to ''Present'' and the preferred owners is a possible owners of the cluster nodes and the cluster resources, but there are one additional preferred owner on the nodes that should not be present' {
            It 'Should return the result as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2', 'Node3')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    ClusterGroup     = 'ClusterGroup1'
                    ClusterName      = 'ClusterName1'
                    Nodes            = @('Node1', 'Node2', 'Node3')
                    ClusterResources = 'Resource1'
                    Ensure           = 'Present'
                }
            }
        }

        Context 'When Ensure is set to ''Present'' and the preferred owner is a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the result as $true ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2', 'Node3')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
            It 'Should return the result as $true ' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node4', 'Node5')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Absent'
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }
            }
        }
    }
}

Describe 'ClusterPreferredOwner\Set-TargetResource' -Tag 'Set' {
    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClusterGroup -ParameterFilter {
                $Cluster -eq 'ClusterName1'
            } -MockWith {
                @{
                    Name      = 'ClusterGroup1'
                    OwnerNode = 'Node1'
                    State     = 'Online'
                }
            }

            Mock -CommandName Get-ClusterOwnerNode -MockWith {
                @{
                    ClusterObject = 'ClusterName1'
                    OwnerNodes    = @(
                        @{ name = 'Node1' }
                        @{ name = 'Node2' }
                        @{ name = 'Node3' }
                    )
                }
            }

            Mock -CommandName Get-ClusterNode -MockWith {
                @{
                    Name = @('Node1', 'Node2')
                }
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'Resource1'
                    State        = 'Online'
                    OwnerGroup   = 'ClusterGroup1'
                    ResourceType = 'type1'
                }
            }

            Mock -CommandName Set-ClusterOwnerNode
            Mock -CommandName Move-ClusterGroup
        }

        Context 'When Ensure is set to ''Present'' but the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
            It 'Should set the preferred owners' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node4', 'Node5')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                # Called three times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                Should -Invoke -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                # Moves the cluster group to the target node (issue #64 open).
                Should -Invoke -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Ensure is set to ''Present'' but the preferred owner is a possible owner of the cluster nodes but the cluster resources is missing' {
            It 'Should set the preferred owners' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'UnknownResource'
                        Ensure           = 'Present'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                # Called two times, one times for each node (2 nodes), and not called for cluster resource because cluster resource is missing.
                Should -Invoke -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 2 -Scope It

                # Moves the cluster group to the target node (issue #64 open).
                Should -Invoke -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Ensure is set to ''Absent'' and the preferred owner is still a possible owner of the cluster nodes and the cluster resources' {
            It 'Should remove the preferred owners, leaving one preferred owner' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Absent'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                # Called two times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                Should -Invoke -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                # Moves the cluster group to the target node (issue #64 open).
                Should -Invoke -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClusterGroup -ParameterFilter {
                $Cluster -eq 'ClusterName1'
            } -MockWith {
                @{
                    Name      = 'ClusterGroup1'
                    OwnerNode = 'Node1'
                    State     = 'Online'
                }
            }

            Mock -CommandName Get-ClusterOwnerNode -MockWith {
                @{
                    ClusterObject = 'ClusterName1'
                    OwnerNodes    = @(
                        @{ name = 'Node1' }
                        @{ name = 'Node2' }
                        @{ name = 'Node3' }
                    )
                }
            }

            Mock -CommandName Get-ClusterNode -MockWith {
                @{
                    Name = @('Node1', 'Node2')
                }
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'Resource1'
                    State        = 'Online'
                    OwnerGroup   = 'ClusterGroup1'
                    ResourceType = 'type1'
                }
            }

            Mock -CommandName Set-ClusterOwnerNode
            Mock -CommandName Move-ClusterGroup
        }

        # This tests wrongly calls Set-ClusterOwnerNode and Move-ClusterGroup. See issue #97.
        Context 'When Ensure is set to ''Present'' and the preferred owner is a possible owner of the cluster nodes and the cluster resources' {
            It 'Should do nothing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node1', 'Node2', 'Node3')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Present'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                # Called two times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                Should -Invoke -CommandName Set-ClusterOwnerNode -Exactly -Times 3 -Scope It

                # Moves the cluster group to the target node (issue #64 open).
                Should -Invoke -CommandName Move-ClusterGroup -Exactly -Times 1 -Scope It
            }
        }

        # This tests wrongly calls Set-ClusterOwnerNode and Move-ClusterGroup. See issue #97.
        Context 'When Ensure is set to ''Absent'' and the preferred owner is not a possible owner of the cluster nodes and the cluster resources' {
            It 'Should do nothing' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        ClusterGroup     = 'ClusterGroup1'
                        ClusterName      = 'ClusterName1'
                        Nodes            = @('Node4', 'Node5')
                        ClusterResources = 'Resource1'
                        Ensure           = 'Absent'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                # Called two times, one times for each node (2 nodes), and one time for each cluster resource (1 resource).
                Should -Invoke -CommandName 'Set-ClusterOwnerNode' -Exactly -Times 3 -Scope It

                # Moves the cluster group to the target node (issue #64 open).
                Should -Invoke -CommandName 'Move-ClusterGroup' -Exactly -Times 1 -Scope It
            }
        }
    }
}
