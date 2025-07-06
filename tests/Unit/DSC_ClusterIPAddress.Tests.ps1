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
    $script:DSCResourceName = 'DSC_ClusterIPAddress'

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

Describe 'DSC_ClusterIPAddress\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
    }

    Context 'When the IP address is added to the cluster' {
        BeforeAll {
            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Online'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                @{
                    Address     = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                    Network     = '192.168.1.1'
                }
            }
        }

        Context 'When Ensure is set to ''Present'' and the IP Address is added to the cluster' {
            It 'Should return the correct hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.Ensure | Should -Be 'Present'
                    $result.IPAddress | Should -Be $mockParameters.IPAddress
                    $result.AddressMask | Should -Be $mockParameters.AddressMask
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the IP Address is added to the cluster' {
            It 'Should return the correct hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.Ensure | Should -Be 'Present'
                    $result.IPAddress | Should -Be $mockParameters.IPAddress
                    $result.AddressMask | Should -Be $mockParameters.AddressMask
                }
            }
        }
    }

    Context 'When the IP address is not added to the cluster' {
        BeforeAll {
            Mock -CommandName Get-ClusterResource
            Mock -CommandName Get-ClusterIPResource
        }

        Context 'When Ensure is set to ''Present'' but the IP Address is not added to the cluster' {
            It 'Should return an empty hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $result = Get-TargetResource @mockParameters
                    $result.Ensure | Should -Be 'Absent'
                    $result.IPAddress | Should -BeNullOrEmpty
                    $result.AddressMask | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Ensure is set to ''Absent'' and the IP Address is not added to the cluster' {
            It 'Should return an empty hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $result = Get-TargetResource @mockParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.IPAddress | Should -BeNullOrEmpty
                    $result.AddressMask | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'DSC_ClusterIPAddress\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
        Mock -CommandName Add-ClusterIPAddressDependency
        Mock -CommandName Remove-ClusterIPAddressDependency
    }

    Context 'IP address should be present' {
        Context 'When the IP cannot be added to the cluster' {
            BeforeAll {
                Mock -CommandName Test-ClusterNetwork -MockWith { $false }
            }

            It 'Should throw if the network of the IP address and subnet mask combination is not added to the cluster' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $errorRecord = Get-InvalidArgumentRecord -Message ($script:localizedData.NonExistentClusterNetwork -f
                        $mockParameters.IPAddress,
                        $mockParameters.AddressMask
                    ) -ArgumentName 'IPAddress'

                    { Set-TargetResource @mockParameters } | Should -Throw -ExpectedMessage $errorRecord
                }

                Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Test-ClusterNetwork -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the cluster IP does not exist' {
            BeforeAll {
                Mock -CommandName Test-ClusterNetwork -MockWith { $true }
            }

            It 'Should not throw' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    { Set-TargetResource @mockParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Test-ClusterNetwork -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-ClusterIPAddressDependency -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When IP Address should be absent' {
        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    Ensure      = 'Absent'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                { Set-TargetResource @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Remove-ClusterIPAddressDependency -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_ClusterIPAddress\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
    }

    Context 'IP address should be Present' {
        Context 'When IP address is not added but should be Present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure      = 'Present'
                        IPAddress   = $null
                        AddressMask = $null
                    }
                }
            }

            It 'Should be false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When IP address is added but address mask does not match' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.240.0'
                    }
                }
            }

            It 'Should be false' {

                $mockParameters = @{
                    Ensure      = 'Present'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                Test-TargetResource @mockParameters | Should -BeFalse
            }
        }

        Context 'When IP address is added and address masks match' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }
                }
            }

            It 'Should be true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }
            }
        }
    }

    Context 'IP address should be Absent' {
        Context 'When IP address is added but should be Absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }
                }
            }

            It 'Should be false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    Test-TargetResource @mockParameters | Should -BeFalse
                }
            }
        }

        Context 'When IP address is not and should be Absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure      = 'Absent'
                        IPAddress   = $null
                        AddressMask = $null
                    }
                }
            }

            It 'Should be true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParameters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    Test-TargetResource @mockParameters | Should -BeTrue
                }
            }
        }
    }
}

Describe 'DSC_ClusterIPAddress\Get-Subnet' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
    }

    It 'Should return the correct subnet' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            Get-Subnet @mockParameters | Should -Be '192.168.1.0'
        }
    }
}

Describe 'DSC_ClusterIPAddress\Add-ClusterIPAddressDependency' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
        Mock -CommandName Get-ClusterObject -MockWith {
            @{
                Name         = 'Cluster Name'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'Network Name'
            }
        }

        Mock -CommandName Add-ClusterIPResource -MockWith { return 'IP Address 192.168.1.41' }
        Mock -CommandName Get-ClusterResource -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }

        Mock -CommandName Add-ClusterIPParameter
        Mock -CommandName Get-ClusterIPResource -MockWith {
            return @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }

        Mock -CommandName New-ClusterIPDependencyExpression -MockWith {
            return '[IP Address 192.168.1.41]'
        }
    }

    Context 'When adding the IP address is successful' {
        BeforeAll {
            Mock -CommandName Set-ClusterResourceDependency
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                { Add-ClusterIPAddressDependency @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ClusterResourceDependency -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-ClusterIPParameter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-ClusterIPDependencyExpression -Exactly -Times 1 -Scope It
        }
    }

    Context 'When adding the IP address fails' {
        BeforeAll {
            Mock -CommandName Set-ClusterResourceDependency {
                throw 'Exception thrown in Set-ClusterResourceDependency'
            }
        }

        It 'Should throw the expected InvalidOperationException' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                { Add-ClusterIPAddressDependency @mockParameters } | Should -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ClusterResourceDependency -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-ClusterIPParameter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-ClusterIPDependencyExpression -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_ClusterIPAddress\Remove-ClusterIPAddressDependency' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
        Mock -CommandName Get-ClusterObject  -MockWith {
            @{
                Name         = 'Cluster Name'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'Network Name'
            }
        }

        Mock -CommandName Get-ClusterIPResourceFromIPAddress -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }

        Mock -CommandName Remove-ClusterResource
        Mock -CommandName Get-ClusterIPResource -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }

        Mock -CommandName New-ClusterIPDependencyExpression -MockWith {
            '[IP Address 192.168.1.41]'
        }
    }

    Context 'When removing the IP address is successful' {
        BeforeAll {
            Mock -CommandName Set-ClusterResourceDependency
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                { Remove-ClusterIPAddressDependency @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResourceFromIPAddress -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-ClusterIPDependencyExpression -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ClusterResourceDependency -Exactly -Times 1 -Scope It
        }
    }

    Context 'When removing the IP address fails' {
        BeforeAll {
            Mock -CommandName Set-ClusterResourceDependency { throw 'Exception thrown in Set-ClusterResourceDependency' }
        }

        It 'Should throw the expected InvalidOperationException' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                { Remove-ClusterIPAddressDependency @mockParameters } | Should -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResourceFromIPAddress -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-ClusterIPDependencyExpression -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ClusterResourceDependency -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_ClusterIPAddress\Test-ClusterNetwork' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
        Mock -CommandName Get-Subnet -MockWith { '192.168.1.0' }
    }

    Context 'When network is in cluster network list' {
        BeforeAll {
            Mock -CommandName Get-ClusterNetworkList -MockWith {
                @{
                    Address     = '192.168.1.0'
                    AddressMask = '255.255.255.0'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                Test-ClusterNetwork @mockParameters | Should -BeTrue
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterNetworkList -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Subnet -Exactly -Times 1 -Scope It
        }
    }

    Context 'When network is not in cluster network list' {
        BeforeAll {
            Mock -CommandName Get-ClusterNetworkList -MockWith {
                @{
                    Address     = '10.10.0.0'
                    AddressMask = '255.255.255.0'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                Test-ClusterNetwork @mockParameters | Should -BeFalse
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterNetworkList -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Subnet -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_ClusterIPAddress\Get-ClusterNetworkList' -Tag 'Helper' {
    Context 'when there is one cluster network' {
        BeforeAll {
            Mock -CommandName Get-ClusterNetwork -MockWith {
                @(
                    [PSCustomObject]@{
                        Address     = '192.168.1.0'
                        AddressMask = '255.255.255.0'
                    }
                )
            }
        }

        It 'Should return the expected list' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ClusterNetworkList

                $result[0].Address | Should -Be '192.168.1.0'
                $result[0].AddressMask | Should -Be '255.255.255.0'
            }
        }
    }

    Context 'When there are many cluster networks' {
        BeforeAll {
            Mock -CommandName Get-ClusterNetwork -MockWith {
                @(
                    [PSCustomObject]@{
                        Address     = '192.168.1.0'
                        AddressMask = '255.255.255.0'
                    }

                    [PSCustomObject]@{
                        Address     = '10.10.0.0'
                        AddressMask = '255.255.0.0'
                    }
                )
            }
        }

        It 'Should return the expected list' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-ClusterNetworkList

                $result.Count | Should -Be 2
                $result[0].Address | Should -Be '192.168.1.0'
                $result[0].AddressMask | Should -Be '255.255.255.0'
                $result[1].Address | Should -Be '10.10.0.0'
                $result[1].AddressMask | Should -Be '255.255.0.0'
            }
        }
    }

    It 'Should return an empty list when there is one cluster network' {

        Mock -CommandName Get-ClusterNetwork -MockWith {
            $networks = New-Object -TypeName 'System.Collections.Generic.List[PSCustomObject]'
            return $networks
        }

                (Get-ClusterNetworkList).Count | Should -BeExactly 0
    }
}

Describe 'DSC_ClusterIPAddress\Add-ClusterIPResource' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
        Mock -CommandName Add-ClusterResource
    }

    It 'Should return the correct resource name' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                IPAddress  = '192.168.1.41'
                OwnerGroup = 'Cluster Group'
            }

            Add-ClusterIPResource @mockParameters | Should -Be "IP Address $($mockParameters.IPAddress)"
        }
    }
}

Describe 'DSC_ClusterIPAddress\Get-ClusterIPResource' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-ClusterResource -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }
    }

    It "Should return the cluster's IP resources" {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $return = Get-ClusterIPResource -OwnerGroup 'Cluster Group'

            $return.Name | Should -Be 'IP Address 192.168.1.41'
            $return.State | Should -Be 'Offline'
            $return.OwnerGroup | Should -Be 'Cluster Group'
            $return.ResourceType | Should -Be 'IP Address'
        }
    }
}

Describe 'DSC_ClusterIPAddress\Add-ClusterIPParameter' -Tag 'Helper' {
    BeforeAll {
        class fake_cluster_parameter
        {
            [string] $IPAddressResourceName
            [string] $ResourceType
            [String] $Address
        }

        Mock -CommandName Test-IPAddress
        Mock -CommandName Get-ClusterResource -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }

        Mock -CommandName New-Object -MockWith {
            New-Object -TypeName 'fake_cluster_parameter'
        } -ParameterFilter {
            $TypeName -and
            $TypeName -eq 'Microsoft.FailoverClusters.PowerShell.ClusterParameter'
        }
    }

    Context 'When adding the IP was successful' {
        BeforeAll {
            Mock -CommandName Set-ClusterParameter
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddressResourceName = 'IP Address 192.168.1.41'
                    IPAddress             = '192.168.1.41'
                    AddressMask           = '255.255.255.0'
                }

                { Add-ClusterIPParameter @mockParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ClusterParameter -Exactly -Times 2 -Scope It
        }
    }

    Context 'When adding the IP failed' {
        BeforeAll {
            Mock -CommandName Set-ClusterParameter -MockWith {
                throw 'Exception setting cluster parameter'
            }
        }

        It 'Should should throw the expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddressResourceName = 'IP Address 192.168.1.41'
                    IPAddress             = '192.168.1.41'
                    AddressMask           = '255.255.255.0'
                }

                { Add-ClusterIPParameter @mockParameters } | Should -Throw
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-ClusterParameter -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_ClusterIPAddress\Test-IPAddress' -Tag 'Helper' {
    It 'Should not throw' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Test-IPAddress -IPAddress '192.168.1.41' } | Should -Not -Throw
        }
    }

    It 'Should throw' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Test-IPAddress -IPAddress '19.420.250.1' } | Should -Throw
        }
    }
}

Describe 'DSC_ClusterIPAddress\New-ClusterIPDependencyExpression' -Tag 'Helper' {
    It 'Should return the correct dependency expression with one resource' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                ClusterResource = 'IP Address 192.168.1.41'
            }

            New-ClusterIPDependencyExpression @mockParameters | Should -Be '[IP Address 192.168.1.41]'
        }
    }

    It 'Should return the correct dependency expression with two resources' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                ClusterResource = @('IP Address 192.168.1.41', 'IP Address 172.19.114.98')
            }

            New-ClusterIPDependencyExpression @mockParameters | Should -Be '[IP Address 192.168.1.41] or [IP Address 172.19.114.98]'
        }
    }

    It 'Should return the correct dependency expression with three resources' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                ClusterResource = @('IP Address 192.168.1.41', 'IP Address 172.19.114.98', 'IP Address 10.10.45.41')
            }

            New-ClusterIPDependencyExpression @mockParameters | Should -Be '[IP Address 192.168.1.41] or [IP Address 172.19.114.98] or [IP Address 10.10.45.41]'
        }
    }
}

Describe 'DSC_ClusterIPAddress\Get-ClusterIPResource' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-ClusterResource -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }
    }

    It 'Should return the expected hashtable' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                OwnerGroup = 'Cluster Group'
            }

            $result = Get-ClusterIPResource @mockParameters

            $result.Name | Should -Be 'IP Address 192.168.1.41'
            $result.State | Should -Be 'Online'
            $result.OwnerGroup | Should -Be 'Cluster Group'
            $result.ResourceType | Should -Be 'IP Address'
        }
    }
}

Describe 'DSC_ClusterIPAddress\Get-ClusterObject' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-ClusterResource -MockWith {
            @{
                Name         = 'Cluster Name'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'Network Name'
            }
        }
    }

    It 'Should return the expected data' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-ClusterObject
            $result.Name | Should -Be 'Cluster Name'
            $result.State | Should -Be 'Online'
            $result.OwnerGroup | Should -Be 'Cluster Group'
            $result.ResourceType | Should -Be 'Network Name'
        }

        Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
    }
}

Describe 'DSC_ClusterIPAddress\Get-ClusterIPResourceParameters' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-ClusterResource -MockWith {
            @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            @{
                Value = '192.168.1.41'
            }
        } -ParameterFilter {
            $name -and
            $name -eq 'Address'
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            @{
                Value = '255.255.255.0'
            }
        } -ParameterFilter {
            $name -and
            $name -eq 'SubnetMask'
        }

        Mock -CommandName Get-ClusterParameter -MockWith {
            @{
                Value = '192.168.1.0'
            }
        } -ParameterFilter {
            $name -and
            $name -eq 'Network'
        }

        Mock -CommandName New-Object -MockWith {
            New-Object -TypeName 'fake_adsi_searcher'
        } -ParameterFilter {
            $TypeName -and
            $TypeName -eq 'System.DirectoryServices.DirectorySearcher'
        }
    }

    It 'Should return the correct result' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $mockParameters = @{
                IPAddressResourceName = 'IP Address 192.168.1.41'
            }

            $result = Get-ClusterIPResourceParameters @mockParameters

            $result.Address | Should -Be '192.168.1.41'
            $result.AddressMask | Should -Be '255.255.255.0'
            $result.Network | Should -Be '192.168.1.0'
        }
    }
}

Describe 'DSC_ClusterIPAddress\Get-ClusterIPResourceFromIPAddress' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Test-IPAddress
        Mock -CommandName Get-ClusterObject -MockWith {
            return @{
                Name         = 'Cluster Name'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'Network Name'
            }
        }

        $mockIpAddress = '192.168.1.41'
    }

    Context 'When one IP resource is returned' {
        BeforeAll {
            Mock -CommandName Get-ClusterIPResource -MockWith {
                @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Online'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                @{
                    Address     = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                    Network     = '192.168.1.1'
                }
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Online'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress = '192.168.1.41'
                }

                $result = Get-ClusterIPResourceFromIPAddress @mockParameters

                $result.Name | Should -Be 'IP Address 192.168.1.41'
                $result.State | Should -Be 'Online'
                $result.OwnerGroup | Should -Be 'Cluster Group'
                $result.ResourceType | Should -Be 'IP Address'
            }

            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResourceParameters -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When multiple IP Resources are returned' {
        BeforeAll {
            Mock -CommandName Get-ClusterIPResource -MockWith {
                @(
                    @{
                        Name         = 'IP Address 192.168.1.41'
                        State        = 'Online'
                        OwnerGroup   = 'Cluster Group'
                        ResourceType = 'IP Address'
                    },
                    @{
                        Name         = 'Cluster IP Address'
                        State        = 'Online'
                        OwnerGroup   = 'Cluster Group'
                        ResourceType = 'IP Address'
                    }
                )
            }

            Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                @{
                    Address     = '192.168.1.14'
                    AddressMask = '255.255.255.0'
                    Network     = '192.168.1.1'
                }
            } -ParameterFilter {
                $IPAddressResourceName -and
                $IPAddressResourceName -eq 'Cluster IP Address'
            }

            Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                @{
                    Address     = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                    Network     = '192.168.1.1'
                }
            } -ParameterFilter {
                $IPAddressResourceName -and
                $IPAddressResourceName -eq 'IP Address 192.168.1.41'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Online'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress = '192.168.1.41'
                }

                $result = Get-ClusterIPResourceFromIPAddress @mockParameters

                $result.Name | Should -Be 'IP Address 192.168.1.41'
                $result.State | Should -Be 'Online'
                $result.OwnerGroup | Should -Be 'Cluster Group'
                $result.ResourceType | Should -Be 'IP Address'
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResourceParameters -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-ClusterResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the IP address is not joined to the cluster' {
        BeforeAll {
            Mock -CommandName Get-ClusterIPResource -MockWith {
                @(
                    @{
                        Name         = 'Cluster IP Address One'
                        State        = 'Online'
                        OwnerGroup   = 'Cluster Group'
                        ResourceType = 'IP Address'
                    },
                    @{
                        Name         = 'Cluster IP Address Two'
                        State        = 'Online'
                        OwnerGroup   = 'Cluster Group'
                        ResourceType = 'IP Address'
                    }
                )
            }

            Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                @{
                    Address     = '192.168.1.14'
                    AddressMask = '255.255.255.0'
                    Network     = '192.168.1.1'
                }
            } -ParameterFilter {
                $IPAddressResourceName -and
                $IPAddressResourceName -eq 'Cluster IP Address One'
            }

            Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                @{
                    Address     = '192.168.1.15'
                    AddressMask = '255.255.255.0'
                    Network     = '192.168.1.1'
                }
            } -ParameterFilter {
                $IPAddressResourceName -and
                $IPAddressResourceName -eq 'Cluster IP Address Two'
            }

            Mock -CommandName Get-ClusterResource
        }

        It 'Should return null' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters = @{
                    IPAddress = '192.168.1.41'
                }

                Get-ClusterIPResourceFromIPAddress @mockParameters | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Test-IPAddress -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterObject -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ClusterIPResourceParameters -Exactly -Times 2 -Scope It
        }
    }
}
