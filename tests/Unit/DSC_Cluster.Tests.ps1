# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
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
    $script:DSCResourceName = 'DSC_Cluster'

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
    Context 'When the computers domain name cannot be evaluated' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSCustomObject] @{
                    Domain = $null
                    Name   = (Get-ComputerName)
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name                          = 'CLUSTER001'
                    DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\ClusterAdmin',
                        $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                    )
                }

                $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TargetNodeDomainMissing

                { Get-TargetResource @mockParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When the cluster cannot be found' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }

            Mock -CommandName Get-Cluster
            Mock -CommandName Set-ImpersonateAs
        }

        It 'Should returns the cluster name' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name                          = 'CLUSTER001'
                    DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\ClusterAdmin',
                        $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                    )
                }

                $result = Get-TargetResource @mockParameters

                $result.Name | Should -Be $mockParameters.Name
                $result.StaticIPAddress | Should -BeNullOrEmpty
                $result.IgnoreNetwork | Should -BeNullOrEmpty
                $result.DomainAdministratorCredential | Should -Be $mockParameters.DomainAdministratorCredential
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }

            Mock -CommandName Get-Cluster -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = 'CLUSTER001'
                }
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'Cluster IP Address'
                    OwnerNode    = 'Cluster Group'
                    State        = 'Online'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                return @{
                    Object = 'Cluster IP Address'
                    Name   = 'Address'
                    Value  = '192.168.10.10'
                }
            }

            Mock -CommandName Close-UserToken
            Mock -CommandName Set-ImpersonateAs -MockWith {
                $oldToken = [System.IntPtr]::Zero

                $context = New-Object -TypeName System.Object |
                    Add-Member -MemberType ScriptMethod -Name Undo -Value { return } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod -Name Dispose -Value { return } -PassThru -Force

                $newToken = [System.IntPtr]::new(12345)

                return $oldToken, $context, $newToken
            }
        }

        It 'Should return the current configuration' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name                          = 'CLUSTER001'
                    StaticIPAddress               = '192.168.10.10'
                    DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\ClusterAdmin',
                        $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                    )
                }

                $result = Get-TargetResource @mockParameters

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Name | Should -Be $mockParameters.Name
                $result.StaticIPAddress | Should -Be $mockParameters.StaticIPAddress
                $result.IgnoreNetwork | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterParameter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Close-UserToken -Exactly -Times 1 -Scope It
        }

        Context 'When IgnoreNetwork is passed' {
            It 'Should returns IgnoreNetwork in the hash' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        IgnoreNetwork                 = '10.0.2.0/24'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    $result = Get-TargetResource @mockParameters
                    $result.IgnoreNetwork | Should -Be '10.0.2.0/24'
                }
            }
        }

        Context 'When no DomainAdministratorCredential is provided' {
            It 'Should not call Set-ImpersonateAs' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0


                    $mockParameters = @{
                        Name            = 'CLUSTER001'
                        StaticIPAddress = '192.168.10.10'
                    }

                    $result = Get-TargetResource @mockParameters
                    $result.DomainAdministratorCredential | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 0 -Scope It
            }
        }
    }
}

Describe 'Cluster\Set-TargetResource' -Tag 'Set' {
    Context 'When computers domain name cannot be evaluated' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                return [PSCustomObject] @{
                    Domain = $null
                    Name   = (Get-ComputerName)
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name                          = 'CLUSTER001'
                    StaticIPAddress               = '192.168.10.10'
                    DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\ClusterAdmin',
                        $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                    )
                }

                $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TargetNodeDomainMissing

                { Set-TargetResource @mockParameters } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName New-Cluster
            Mock -CommandName Remove-ClusterNode
            Mock -CommandName Add-ClusterNode
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }

            Mock -CommandName Set-ImpersonateAs -MockWith {
                $context = New-MockObject -Type System.Object -Methods @{
                    Undo    = { return }
                    Dispose = { return }
                }

                $newToken = [System.IntPtr]::new(12345)

                $newToken, $context, $newToken
            }

            Mock -CommandName Close-UserToken
        }

        Context 'When the cluster does not exist' {
            Context 'When Get-Cluster returns nothing' {
                BeforeAll {
                    # This is used for the evaluation of that cluster do not exist.
                    Mock -CommandName Get-Cluster -ParameterFilter {
                        $Name -eq 'CLUSTER001' -and
                        $Domain -eq 'domain.local'
                    }

                    # This is used to evaluate that cluster do exists after New-Cluster cmdlet has been run.
                    Mock -CommandName Get-Cluster -MockWith {
                        [PSCustomObject] @{
                            Domain = 'domain.local'
                            Name   = 'CLUSTER001'
                        }
                    }
                }

                Context 'When using static IP address' {
                    It 'Should call New-Cluster cmdlet using StaticAddress parameter' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockParameters = @{
                                Name                          = 'CLUSTER001'
                                StaticIPAddress               = '192.168.10.10'
                                DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                    'COMPANY\ClusterAdmin',
                                    $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                                )
                            }

                            { Set-TargetResource @mockParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName New-Cluster -ParameterFilter {
                            $StaticAddress -eq '192.168.10.10'
                        } -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When assigned IP address from DHCP' {
                    It 'Should call New-Cluster cmdlet using StaticAddress parameter' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockParameters = @{
                                Name                          = 'CLUSTER001'
                                DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                    'COMPANY\ClusterAdmin',
                                    $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                                )
                            }

                            { Set-TargetResource @mockParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName New-Cluster -ParameterFilter {
                            $null -eq $StaticAddress
                        } -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }


                Context 'When IgnoreNetwork is passed as a single value' {
                    It 'Should call New-Cluster cmdlet with IgnoreNetwork parameter' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockParameters = @{
                                Name                          = 'CLUSTER001'
                                StaticIPAddress               = '192.168.10.10'
                                IgnoreNetwork                 = '10.0.2.0/24'
                                DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                    'COMPANY\ClusterAdmin',
                                    $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                                )
                            }

                            { Set-TargetResource @mockParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                            $IgnoreNetwork -eq '10.0.2.0/24'
                        }

                        Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When IgnoreNetwork is passed as an array' {
                    It 'Should call New-Cluster cmdlet with IgnoreNetwork parameter' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockParameters = @{
                                Name                          = 'CLUSTER001'
                                StaticIPAddress               = '192.168.10.10'
                                IgnoreNetwork                 = ('10.0.2.0/24', '192.168.4.0/24')
                                DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                    'COMPANY\ClusterAdmin',
                                    $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                                )
                            }

                            { Set-TargetResource @mockParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                            $IgnoreNetwork -eq '10.0.2.0/24' -and
                            $IgnoreNetwork -eq '192.168.4.0/24'
                        }

                        Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When IgnoreNetwork is not passed' {
                    It 'Should call New-Cluster cmdlet without IgnoreNetwork parameter' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockParameters = @{
                                Name                          = 'CLUSTER001'
                                StaticIPAddress               = '192.168.10.10'
                                DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                    'COMPANY\ClusterAdmin',
                                    $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                                )
                            }

                            { Set-TargetResource @mockParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                            $IgnoreNetwork -eq $null
                        }
                        Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When no DomainAdministratorCredential is provided' {
                    It 'Should not call Set-ImpersonateAs' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $mockParameters = @{
                                Name            = 'CLUSTER001'
                                StaticIPAddress = '192.168.10.10'
                            }

                            { Set-TargetResource @mockParameters } | Should -Not -Throw
                        }

                        Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName New-Cluster -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When Get-Cluster throws an error' {
                BeforeAll {
                    # This is used for the evaluation of that cluster do not exist.
                    Mock -CommandName Get-Cluster -MockWith {
                        throw 'Mock Get-Cluster throw error'
                    } -ParameterFilter {
                        $Name -eq 'CLUSTER001' -and $Domain -eq 'domain.local'
                    }

                    # This is used to evaluate that cluster do exists after New-Cluster cmdlet has been run.
                    Mock -CommandName Get-Cluster -MockWith {
                        [PSCustomObject] @{
                            Domain = 'domain.local'
                            Name   = 'CLUSTER001'
                        }
                    }
                }

                It 'Should call New-Cluster cmdlet' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            Name                          = 'CLUSTER001'
                            StaticIPAddress               = '192.168.10.10'
                            DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                'COMPANY\ClusterAdmin',
                                $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                            )
                        }

                        { Set-TargetResource @mockParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName New-Cluster -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When the cluster does not exist, and New-Cluster is run, but no cluster can be found after' {
            BeforeAll {
                Mock -CommandName Get-Cluster
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.FailedCreatingCluster

                    { Set-TargetResource @mockParameters } | Should -Throw $errorRecord
                }

                Should -Invoke -CommandName New-Cluster -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
            }
        }

        Context 'When the cluster exist but the node is not part of the cluster' {
            BeforeAll {
                Mock -CommandName Get-ClusterNode
                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                } -ParameterFilter {
                    $Name -eq 'CLUSTER001' -and $Domain -eq 'domain.local'
                }
            }

            It 'Should call Add-ClusterNode cmdlet' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName New-Cluster -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 1 -Scope It
            }

            Context 'When no DomainAdministratorCredential is provided' {
                It 'Should not call Set-ImpersonateAs' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            Name            = 'CLUSTER001'
                            StaticIPAddress = '192.168.10.10'
                        }

                        { Set-TargetResource @mockParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName New-Cluster -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the cluster exist and the node is down' {
            BeforeAll {
                Mock -CommandName Get-ClusterNode -MockWith {
                    @(
                        @{
                            Name  = (Get-ComputerName)
                            State = 'Down'
                        }
                    )
                }

                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                } -ParameterFilter {
                    $Name -eq 'CLUSTER001' -and $Domain -eq 'domain.local'
                }
            }

            It 'Should call both Remove-ClusterNode and Add-ClusterNode cmdlet' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }


                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName New-Cluster -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 1 -Scope It
            }

            It 'Should not call Remove-ClusterNode when KeepDownedNodesInCluster is True' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                        KeepDownedNodesInCluster      = $true
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName New-Cluster -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClusterNode
            Mock -CommandName New-Cluster
            Mock -CommandName Remove-ClusterNode
            Mock -CommandName Add-ClusterNode
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }

            Mock -CommandName Get-Cluster -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = 'CLUSTER001'
                }
            } -ParameterFilter {
                $Name -eq 'CLUSTER001' -and $Domain -eq 'domain.local'
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                @{
                    Object = 'Cluster IP Address'
                    Name   = 'Address'
                    Value  = '192.168.10.10'
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

            Mock -CommandName Set-ImpersonateAs -MockWith {
                $context = New-MockObject -Type System.Object -Methods @{
                    Undo    = { return }
                    Dispose = { return }
                }

                $newToken = [System.IntPtr]::new(12345)

                $newToken, $context, $newToken
            }
        }

        Context 'When the node already exist' {
            BeforeAll {
                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                } -ParameterFilter {
                    $Name -eq 'CLUSTER001' -and $Domain -eq 'domain.local'
                }
            }

            # This test is skipped because due to a logic error it's not possible to test this (issue #79)
            It 'Should not call any of the cluster cmdlets' -Skip:$true {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName New-Cluster -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
            }
        }

        Context 'When no DomainAdministratorCredential is provided' {
            It 'Should not call Set-ImpersonateAs' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name            = 'CLUSTER001'
                        StaticIPAddress = '192.168.10.10'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 0 -Scope It
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
                    Name   = (Get-ComputerName)
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name                          = 'CLUSTER001'
                    StaticIPAddress               = '192.168.10.10'
                    DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('COMPANY\ClusterAdmin', $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force))
                }

                $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TargetNodeDomainMissing

                { Test-TargetResource @mockParameters } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When no DomainAdministratorCredential is provided' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }

            Mock -CommandName Get-Cluster -MockWith {
                return [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = 'CLUSTER001'
                }
            }

            Mock -CommandName Set-ImpersonateAs -MockWith { 0 }
        }

        It 'Should not call Set-ImpersonateAs' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Name            = 'CLUSTER001'
                    StaticIPAddress = '192.168.10.10'
                }

                Test-TargetResource @mockParameters
            }

            Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }
        }

        Context 'When the cluster does not exist' {
            BeforeAll {
                Mock -CommandName Get-Cluster
                Mock -CommandName Set-ImpersonateAs -MockWith { 0 }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Get-Cluster throws an error' {
            BeforeAll {
                Mock -CommandName Get-Cluster -MockWith {
                    throw 'Mock Get-Cluster throw error'
                }

                Mock -CommandName Set-ImpersonateAs -MockWith { 0 }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the node does not exist' {
            BeforeAll {
                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                }

                Mock -CommandName Set-ImpersonateAs -MockWith {
                    $context = New-MockObject -Type System.Object -Methods @{
                        Undo    = { return }
                        Dispose = { return }
                    }

                    $newToken = [System.IntPtr]::new(12345)

                    $newToken, $context, $newToken
                }

                Mock -CommandName Close-UserToken
                Mock -CommandName Get-ClusterNode
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ClusterNode -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the node do exist, but is down' {
            BeforeAll {
                Mock -CommandName Get-Cluster -MockWith {
                    [PSCustomObject] @{
                        Domain = 'domain.local'
                        Name   = 'CLUSTER001'
                    }
                }

                Mock -CommandName Set-ImpersonateAs -MockWith { 0 }
                Mock -CommandName Get-ClusterNode -MockWith {
                    @(
                        @{
                            Name  = (Get-ComputerName)
                            State = 'Down'
                        }
                    )
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ClusterNode -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClusterNode -MockWith {
                @(
                    @{
                        Name  = (Get-ComputerName)
                        State = 'Up'
                    }
                )
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = (Get-ComputerName)
                }
            }

            Mock -CommandName Get-Cluster -MockWith {
                [PSCustomObject] @{
                    Domain = 'domain.local'
                    Name   = 'CLUSTER001'
                }
            }

            Mock -CommandName Set-ImpersonateAs -MockWith { 0 }
        }

        Context 'When the node already exists' {
            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Name                          = 'CLUSTER001'
                        StaticIPAddress               = '192.168.10.10'
                        DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            'COMPANY\ClusterAdmin',
                            $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                        )
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-ImpersonateAs -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-ClusterNode -Exactly -Times 1 -Scope It
            }

            Context 'When node exists and is in a Paused state' {
                BeforeAll {
                    Mock -CommandName Get-ClusterNode -MockWith {
                        @(
                            @{
                                Name  = (Get-ComputerName)
                                State = 'Paused'
                            }
                        )
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockParameters = @{
                            Name                          = 'CLUSTER001'
                            StaticIPAddress               = '192.168.10.10'
                            DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                                'COMPANY\ClusterAdmin',
                                $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                            )
                        }

                        Test-TargetResource @mockParameters | Should -BeTrue
                    }
                }
            }
        }
    }
}

Describe 'Cluster\Get-ImpersonateLib' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Add-Type -MockWith {
            return New-MockObject -Type System.Object -Methods @{
                Undo    = { return }
                Dispose = { return }
            }
        }
    }

    Context 'When the type is already loaded' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:ImpersonateLib = $true
            }
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-ImpersonateLib } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-Type -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the type is not loaded' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:ImpersonateLib = $null
            }
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-ImpersonateLib } | Should -Not -Throw
            }

            Should -Invoke -CommandName Add-Type -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'Cluster\Set-ImpersonateAs' -Tag 'Helper' {
    Context 'When impersonating credentials fails' {
        BeforeAll {
            Mock -CommandName Get-ImpersonateLib -MockWith {
                class MockLibImpersonation
                {
                    MockLibImpersonation()
                    {
                    }

                    static [bool] $ReturnValue = $false

                    static [bool]LogonUser(
                        [string] $userName,
                        [string] $domain,
                        [string] $password,
                        [int] $logonType,
                        [int] $logonProvider,
                        [ref] $token
                    )
                    {
                        return [MockLibImpersonation]::ReturnValue
                    }

                    static [bool]CloseHandle([System.IntPtr]$Token)
                    {
                        return [MockLibImpersonation]::ReturnValue
                    }
                }

                $mockLib = [MockLibImpersonation]::new()
                return $mockLib
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\ClusterAdmin',
                        $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                    )
                }

                $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.UnableToImpersonateUser -f
                    $mockParameters.Credential.GetNetworkCredential().UserName
                )

                { Set-ImpersonateAs @mockParameters } | Should -Throw $mockCorrectErrorRecord
            }

            Should -Invoke -CommandName Get-ImpersonateLib -Exactly -Times 1 -Scope It
        }
    }

    Context 'When impersonating credentials succeeds' {
        BeforeAll {
            Mock -CommandName Get-ImpersonateLib -MockWith {
                class MockLibImpersonation
                {
                    MockLibImpersonation()
                    {
                    }

                    static [bool] $ReturnValue = $true

                    static [bool]LogonUser(
                        [string] $userName,
                        [string] $domain,
                        [string] $password,
                        [int] $logonType,
                        [int] $logonProvider,
                        [ref] $token
                    )
                    {
                        return [MockLibImpersonation]::ReturnValue
                    }

                    static [bool]CloseHandle([System.IntPtr]$Token)
                    {
                        return [MockLibImpersonation]::ReturnValue
                    }
                }

                $mockLib = [MockLibImpersonation]::new()
                return $mockLib
            }

            Mock -CommandName New-Object -MockWith {
                return New-MockObject -Type System.Object -Methods @{
                    Impersonate = { return @{} }
                }
            } -ParameterFilter {
                $TypeName -eq 'Security.Principal.WindowsIdentity'
            }
        }

        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\ClusterAdmin',
                        $(ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force)
                    )
                }

                { Set-ImpersonateAs @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-ImpersonateLib -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'Cluster\Close-UserToken' -Tag 'Helper' {
    Context 'When closing user token fails' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-ImpersonateLib -MockWith {
                    class MockLibImpersonation
                    {
                        MockLibImpersonation()
                        {
                        }

                        static [bool] $ReturnValue = $false

                        static [bool]LogonUser(
                            [string] $userName,
                            [string] $domain,
                            [string] $password,
                            [int] $logonType,
                            [int] $logonProvider,
                            [ref] $token
                        )
                        {
                            return [MockLibImpersonation]::ReturnValue
                        }

                        static [bool]CloseHandle([System.IntPtr]$Token)
                        {
                            return [MockLibImpersonation]::ReturnValue
                        }
                    }

                    $mockLib = [MockLibImpersonation]::new()
                    return $mockLib
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Token = [System.IntPtr]::New(12345)
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.UnableToCloseToken -f $mockParameters.Token.ToString())

                { Close-UserToken @mockParameters } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Get-ImpersonateLib -Exactly -Times 1 -Scope It
        }
    }

    Context 'When closing user token succeeds' {
        BeforeAll {
            Mock -CommandName Get-ImpersonateLib -MockWith {
                class MockLibImpersonation
                {
                    MockLibImpersonation()
                    {
                    }

                    static [bool] $ReturnValue = $true

                    static [bool]LogonUser(
                        [string] $userName,
                        [string] $domain,
                        [string] $password,
                        [int] $logonType,
                        [int] $logonProvider,
                        [ref] $token
                    )
                    {
                        return [MockLibImpersonation]::ReturnValue
                    }

                    static [bool]CloseHandle([System.IntPtr]$Token)
                    {
                        return [MockLibImpersonation]::ReturnValue
                    }
                }

                $mockLib = [MockLibImpersonation]::new()
                return $mockLib
            }
        }

        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Token = [System.IntPtr]::New(12345)
                }

                { Close-UserToken @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-ImpersonateLib -Exactly -Times 1 -Scope It
        }
    }
}
