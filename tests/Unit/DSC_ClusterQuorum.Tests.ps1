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
    $script:DSCResourceName = 'DSC_ClusterQuorum'

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

Describe 'ClusterQuorum\Get-TargetResource' -Tag 'Get' {
    BeforeEach {
        Mock -CommandName Get-ClusterQuorum -MockWith {
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
                'NodeMajority'
                {
                    $getClusterQuorumReturnValue.QuorumResource = $null
                }

                'NodeAndDiskMajority'
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Physical Disk'
                }

                'NodeAndFileShareMajority'
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = $mockDynamicQuorumTypeDisplayName
                }

                'NodeAndCloudMajority'
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Cloud Witness'
                }

                'Unknown'
                {
                    $getClusterQuorumReturnValue.QuorumResource.ResourceType.DisplayName = 'Unknown'
                }
            }

            $getClusterQuorumReturnValue
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            @(
                [PSCustomObject] @{
                    ClusterObject = $mockDynamicQuorumTypeDisplayName
                    Name          = 'SharePath'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = '\\FILE01\CLUSTER01'
                }
            )
        } -ParameterFilter {
            $Name -eq 'SharePath'
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            @(
                [PSCustomObject] @{
                    ClusterObject = 'File Share Witness'
                    Name          = 'AccountName'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = 'AccountName'
                }
            )
        } -ParameterFilter {
            $Name -eq 'AccountName'
        }
    }

    Context 'When the system is either in the desired state or not in the desired state' {
        BeforeAll {
            $mockDynamicQuorumResourceName = 'Witness'
        }

        Context 'When quorum type should be NodeMajority' {
            BeforeAll {
                $mockDynamicQuorumType = 'Majority'
                $mockDynamicExpectedQuorumType = 'NodeMajority'
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.IsSingleInstance | Should -Be $mockParameters.IsSingleInstance
                    $result.Type | Should -Be 'NodeMajority'
                    $result.Resource | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When desired state should be NodeAndDiskMajority' {
            BeforeAll {
                $mockDynamicQuorumType = 'Majority'
                $mockDynamicExpectedQuorumType = 'NodeAndDiskMajority'
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.IsSingleInstance | Should -Be $mockParameters.IsSingleInstance
                    $result.Type | Should -Be 'NodeAndDiskMajority'
                    $result.Resource | Should -Be 'Witness'
                }
            }
        }

        Context 'When desired state should be NodeAndFileShareMajority' {
            BeforeAll {
                $mockDynamicQuorumType = 'Majority'
                $mockDynamicExpectedQuorumType = 'NodeAndFileShareMajority'
                $mockDynamicQuorumTypeDisplayName = 'File Share Quorum Witness'
            }


            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.IsSingleInstance | Should -Be $mockParameters.IsSingleInstance
                    $result.Type | Should -Be 'NodeAndFileShareMajority'
                    $result.Resource | Should -Be '\\FILE01\CLUSTER01'
                }
            }
        }

        Context 'When desired state should be NodeAndCloudMajority' {
            BeforeAll {
                $mockDynamicQuorumType = 'Majority'
                $mockDynamicExpectedQuorumType = 'NodeAndCloudMajority'
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.IsSingleInstance | Should -Be $mockParameters.IsSingleInstance
                    $result.Type | Should -Be 'NodeAndCloudMajority'
                    $result.Resource | Should -Be 'AccountName'
                }
            }
        }

        Context 'When desired state should be DiskOnly' {
            BeforeAll {
                $mockDynamicQuorumType = 'DiskOnly'
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.IsSingleInstance | Should -Be $mockParameters.IsSingleInstance
                    $result.Type | Should -Be 'DiskOnly'
                    $result.Resource | Should -Be 'Witness'
                }
            }
        }

        Context 'When quorum type is unknown' {
            BeforeAll {
                $mockDynamicQuorumType = 'Majority'
                $mockDynamicExpectedQuorumType = 'Unknown'
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                    }

                    { Get-TargetResource @mockParameters } | Should -Throw ('Unknown quorum resource: {0}' -f '@{Name=Witness; OwnerGroup=Cluster Group; ResourceType=}')
                }
            }
        }
    }
}

Describe 'ClusterQuorum\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is not in the desired state' {
        Context 'When quorum type should be NodeMajority' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeAndDiskMajority'
                            Resource         = 'Witness'
                        }
                    }
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeMajority'
                            Resource         = 'Witness'
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }
                }
            }
        }

        Context 'When quorum type is NodeMajority but the resource is not in desired state' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'Majority'
                            Resource         = 'Witness'
                        }
                    }
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeMajority'
                            Resource         = 'Witness'
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }
                }
            }
        }

        Context 'When desired state should be NodeAndDiskMajority' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'Majority'
                            Resource         = 'Witness'
                        }
                    }
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeAndDiskMajority'
                            Resource         = 'Witness'
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }
                }
            }
        }

        Context 'When desired state should be NodeAndFileShareMajority' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'Majority'
                            Resource         = 'Witness'
                        }
                    }
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeAndFileShareMajority'
                            Resource         = 'Witness'
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }
                }
            }
        }

        Context 'When desired state should be NodeAndCloudMajority' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeMajority'
                            Resource         = 'Witness'
                        }
                    }
                }

                It 'Should return the value $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance        = 'Yes'
                            Type                    = 'NodeAndCloudMajority'
                            Resource                = 'AccountName'
                            StorageAccountAccessKey = 'USRuD354YbOHkPI35SUVyMj2W3odWekMIEdj3n2qAbc0yzqwpMwH-+M+GHJ27OuA5FkTxsbBF9qGc6r6UM3ipg=='
                        }

                        Test-TargetResource @mockParameters | Should -BeFalse
                    }
                }
            }
        }

        Context 'When desired state should be DiskOnly' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance = 'Yes'
                        Type             = 'DiskOnly'
                        Resource         = 'Witness'
                    }
                }
            }

            It 'Should return the value $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IsSingleInstance = 'Yes'
                        Type             = 'NodeMajority'
                        Resource         = 'Witness'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When quorum type is NodeMajority but the resource is not in desired state' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeMajority'
                            Resource         = 'Witness'
                        }
                    }
                }

                It 'Should return the value $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeMajority'
                            Resource         = 'Witness'
                        }

                        Test-TargetResource @mockParameters | Should -BeTrue
                    }
                }
            }
        }

        Context 'When desired state should be NodeAndCloudMajority' {
            Context 'When target node is Windows Server 2016 and newer' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            IsSingleInstance = 'Yes'
                            Type             = 'NodeAndCloudMajority'
                            Resource         = 'AccountName'
                        }
                    }
                }

                It 'Should return the value $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            IsSingleInstance        = 'Yes'
                            Type                    = 'NodeAndCloudMajority'
                            Resource                = 'AccountName'
                            StorageAccountAccessKey = 'USRuD354YbOHkPI35SUVyMj2W3odWekMIEdj3n2qAbc0yzqwpMwH-+M+GHJ27OuA5FkTxsbBF9qGc6r6UM3ipg=='
                        }

                        Test-TargetResource @mockParameters | Should -BeTrue
                    }
                }
            }
        }
    }
}

Describe 'ClusterQuorum\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Set-ClusterQuorum
    }

    Context 'When quorum type should be NodeMajority' {
        It 'Should set the quorum in the cluster without throwing an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IsSingleInstance = 'Yes'
                    Type             = 'NodeMajority'
                }

                { Set-TargetResource @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-ClusterQuorum -ParameterFilter {
                $NoWitness -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When quorum type should be NodeAndDiskMajority' {
        It 'Should set the quorum in the cluster without throwing an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IsSingleInstance = 'Yes'
                    Type             = 'NodeAndDiskMajority'
                    Resource         = 'Witness'
                }

                { Set-TargetResource @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-ClusterQuorum -ParameterFilter {
                $DiskWitness -eq 'Witness'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When quorum type should be NodeAndFileShareMajority' {
        It 'Should set the quorum in the cluster without throwing an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IsSingleInstance = 'Yes'
                    Type             = 'NodeAndFileShareMajority'
                    Resource         = 'Witness'
                }

                { Set-TargetResource @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-ClusterQuorum -ParameterFilter {
                $FileShareWitness -eq 'Witness'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When quorum type should be NodeAndCloudMajority' {
        BeforeAll {
            $mockDynamicQuorumResourceName = 'AccountName'
        }

        It 'Should set the quorum in the cluster without throwing an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IsSingleInstance        = 'Yes'
                    Type                    = 'NodeAndCloudMajority'
                    Resource                = 'AccountName'
                    StorageAccountAccessKey = 'USRuD354YbOHkPI35SUVyMj2W3odWekMIEdj3n2qAbc0yzqwpMwH-+M+GHJ27OuA5FkTxsbBF9qGc6r6UM3ipg=='
                }

                { Set-TargetResource @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-ClusterQuorum -ParameterFilter {
                $CloudWitness -eq $true -and
                $null -ne $AccountName -and
                $null -ne $AccessKey
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When quorum type should be DiskOnly' {
        It 'Should set the quorum in the cluster without throwing an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IsSingleInstance = 'Yes'
                    Type             = 'DiskOnly'
                    Resource         = 'Witness'
                }

                { Set-TargetResource @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-ClusterQuorum -ParameterFilter {
                $DiskOnly -eq 'Witness'
            } -Exactly -Times 1 -Scope It
        }
    }
}
