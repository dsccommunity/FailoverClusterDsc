$script:DSCModuleName = 'FailoverClusterDsc'
$script:DSCResourceName = 'DSC_ClusterIPAddress'

function Invoke-TestSetup
{
    param
    (
    )

    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "Stubs\FailoverClusters$ModuleVersion.stubs.psm1") -Global -Force
    # $global:moduleVersion = $ModuleVersion
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    Remove-Variable -Name moduleVersion -Scope Global -ErrorAction SilentlyContinue
}

try {
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        $script:DSCResourceName = 'DSC_ClusterIPAddress'
        Describe "$script:DSCResourceName\Get-TargetResource" {
            Mock -CommandName Test-IPAddress

            Context 'When the IP address is added to the cluster' {

                Mock -CommandName Get-ClusterResource -MockWith {
                    return @{
                        Name = "IP Address $($mockTestParameters.Address)"
                        State = 'Online'
                        OnwerGroup = 'Cluster Group'
                        ResourceType = 'IP Address'
                    }
                }

                Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
                    return @{
                        Address     = $mockTestParameters.IPAddress
                        AddressMask = $mockTestParameters.AddressMask
                        Network     = '192.168.1.1'
                    }
                }

                Context 'When Ensure is set to ''Present'' and the IP Address is added to the cluster' {
                    $mockTestParameters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    It 'Should return the correct hashtable' {
                        $result = Get-TargetResource @mockTestParameters

                        $result.Ensure      | Should -Be $mockTestParameters.Ensure
                        $result.IPAddress   | Should -Be $mockTestParameters.IPAddress
                        $result.AddressMask | Should -Be $mockTestParameters.AddressMask
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the IP Address is added to the cluster' {
                    $mockTestParameters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    It 'Should return the correct hashtable' {
                        $result = Get-TargetResource @mockTestParameters

                        $result.Ensure      | Should -Be $mockTestParameters.Ensure
                        $result.IPAddress   | Should -Be $mockTestParameters.IPAddress
                        $result.AddressMask | Should -Be $mockTestParameters.AddressMask
                    }
                }
            }

            Context 'When the IP address is not added to the cluster' {

                Mock -CommandName Get-ClusterResource -MockWith {
                    return @{}
                }

                Mock -CommandName Get-ClusterIPResource -MockWith {
                    return @{}
                }

                Context 'When Ensure is set to ''Present'' but the IP Address is not added to the cluster' {
                    $mockTestParameters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    It 'Should return an empty hashtable' {
                        $result = Get-TargetResource @mockTestParameters
                        $result.Ensure      | Should -Be $mockTestParameters.Ensure
                        $result.IPAddress   | Should -BeNullOrEmpty
                        $result.AddressMask | Should -BeNullOrEmpty
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the IP Address is not added to the cluster' {
                    $mockTestParameters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    It 'Should return an empty hashtable' {
                        $result = Get-TargetResource @mockTestParameters
                        $result.Ensure      | Should -Be 'Absent'
                        $result.IPAddress   | Should -BeNullOrEmpty
                        $result.AddressMask | Should -BeNullOrEmpty
                    }
                }
            }
        }

        Describe "$script:DSCResourceName\Set-TargetResource" {
            Mock -CommandName Test-IPAddress
            Mock -CommandName Add-ClusterIPAddressDependency
            Mock -CommandName Remove-ClusterIPAddressDependency

            Context "IP address should be present" {

                $mockTestParameters = @{
                    Ensure      = 'Present'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                It "Should throw if the network of the IP address and subnet mask combination is not added to the cluster" {

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.NonExistantClusterNetwork -f $mockTestParameters.IPAddress, $mockTestParameters.AddressMask) `
                        -ArgumentName 'IPAddress'

                    Mock -CommandName Test-ClusterNetwork -MockWith { $False }

                    {
                        Set-TargetResource @mockTestParameters
                    } | Should -Throw $errorRecord
                }

                It "Should not throw" {

                    Mock -CommandName Test-ClusterNetwork -MockWith { $True }
                    {
                        Set-TargetResource @mockTestParameters
                    } | Should -Not -Throw
                }
            }

            Context "IP address should be absent" {

                It "Should not throw when Absent" {

                    $mockTestParameters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    {
                        Set-TargetResource @mockTestParameters
                    }  | Should -Not -Throw
                }
            }
        }

        Describe "$script:DSCResourceName\Test-TargetResource" {
            Mock -CommandName Test-IPAddress

            Context "IP address should be Present" {

                $mockTestParameters = @{
                    Ensure      = 'Present'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                It "Should be false when IP address is not added but should be Present" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Present'
                            IPAddress   = $null
                            AddressMask = $null
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $false
                }

                It "Should be false when IP address is added but address mask does not match" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Present'
                            IPAddress   = '192.168.1.41'
                            AddressMask = '255.255.240.0'
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $false
                }

                It "Should be true when IP address is added and address masks match" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Present'
                            IPAddress   = '192.168.1.41'
                            AddressMask = '255.255.255.0'
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $true
                }
            }

            Context "IP address should be Absent" {

                $mockTestParameters = @{
                    Ensure      = 'Absent'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                It "Should be false when IP address is added but should be Absent" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Absent'
                            IPAddress   = '192.168.1.41'
                            AddressMask = '255.255.255.0'
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $false
                }

                It "Should be true when IP address is not and should be Absent" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Absent'
                            IPAddress   = $null
                            AddressMask = $null
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $true
                }
            }
        }

        Describe "$script:DSCResourceName\Get-Subnet" {
            Mock -CommandName Test-IPAddress -MockWith {}

            $mockTestParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            It "Should return the correct subnet" {
                $result = Get-Subnet @mockTestParameters
                $result | Should -Be '192.168.1.0'
            }
        }

        Describe "$script:DSCResourceName\Add-ClusterIPAddressDependency" {
            $mockTestParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            Mock -CommandName Test-IPAddress -MockWith {}
            Mock -CommandName Get-ClusterObject -MockWith {
                return @{
                    Name         = "Cluster Name"
                    State        = "Online"
                    OwnerGroup   = "Cluster Group"
                    ResourceType = "Network Name"
                }
            }

            Mock -CommandName Add-ClusterIPResource -MockWith { return 'IP Address 192.168.1.41' }
            Mock -CommandName Get-ClusterResource -MockWith {
                return @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Offline'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

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

            It "Should not throw" {
                Mock -CommandName Set-ClusterResourceDependency

                Add-ClusterIPAddressDependency @mockTestParameters | Should -Not -Throw
                Assert-MockCalled -CommandName Set-ClusterResourceDependency -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName Get-ClusterResource -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPParameter -Times 1
                Assert-MockCalled -CommandName Get-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName New-ClusterIPDependencyExpression -Times 1
            }

            It "Should throw the expected InvalidOperationException" {
                $errorRecord = "Exception thrown in Set-ClusterResourceDependency"

                Mock -CommandName Set-ClusterResourceDependency { throw $errorRecord }

                Mock -CommandName New-InvalidOperationException -MockWith {
                    throw $errorRecord
                }

                Add-ClusterIPAddressDependency @mockTestParameters | Should -Throw $errorRecord
                Assert-MockCalled -CommandName Set-ClusterResourceDependency -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName Get-ClusterResource -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPParameter -Times 1
                Assert-MockCalled -CommandName Get-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName New-ClusterIPDependencyExpression -Times 1
                Assert-MockCalled -CommandName New-InvalidOperationException -Times 1
            }
        }

        Describe "$script:DSCResourceName\Remove-ClusterIPAddressDependency" {

        }

        Describe "$script:DSCResourceName\Test-ClusterIPAddressDependency" {

        }

        Describe "$script:DSCResourceName\Test-ClusterNetwork" {

        }

        Describe "$script:DSCResourceName\Get-ClusterNetworkList" {

        }

        Describe "$script:DSCResourceName\Get-ClusterDependencyExpression" {

        }

        Describe "$script:DSCResourceName\Add-ClusterIPResource" {

        }

        Describe "$script:DSCResourceName\Remove-ClusterIPResource" {

        }

        Describe "$script:DSCResourceName\Get-ClusterIPResource" {

        }

        Describe "$script:DSCResourceName\Add-ClusterIPParameter" {

        }

        Describe "$script:DSCResourceName\Remove-ClusterIPParameter" {

        }

        Describe "$script:DSCResourceName\Test-IPAddress" {

        }

        Describe "$script:DSCResourceName\New-ClusterIPDependencyExpression" {

        }

        Describe "$script:DSCResourceName\Get-ClusterIPResource" {

        }

        Describe "$script:DSCResourceName\Get-ClusterOwnerGroup" {

        }
    }
}
finally {
    Invoke-TestCleanup
}
