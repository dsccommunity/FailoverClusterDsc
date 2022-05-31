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
        Describe "$script:dscModuleName\Get-TargetResource" {
            Mock -CommandName Test-IPAddress -MockWith {
                return $True
            }

            Context 'When the system is in the desired state' {
                $mockTestParmaters = @{
                    Ensure      = 'Absent'
                    Address     = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                Context 'When Ensure is set to ''Absent'' and the IP Address is not added to the cluster' {
                    Mock -CommandName Get-ClusterResource -MockWith {
                        return @{}
                    }

                    Mock -CommandName Get-ClusterIPResource -MockWith {
                        return @{}
                    }

                    It 'Should return an empty hashtable' {
                        Get-TargetResource @mockTestParameters | Should -Be @{}
                    }
                }

                Context 'When Ensure is set to ''Present'' and the IP Address is added to the cluster' {
                    $mockTestParmaters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $correctResult = @{
                        IPAddress   = $mockTestParameters.Address
                        AddressMask = $mockTestParameters.AddressMask
                        Ensure      = 'Present'
                    }

                    Mock -CommandName Get-ClusterResource -MockWith {
                        return @{
                            Name = "IP Address $($mockTestParameters.Address)"
                            State = 'Online'
                            OnwerGroup = 'Cluster Group'
                            ResourceType = 'IP Address'
                        }
                    }

                    Mock -CommandName Get-ClusterIPResource -MockWith {
                        return @{
                            Address     = $mockTestParameters.Address
                            AddressMask = $mockTestParameters.AddressMask
                            Network     = '192.168.1.1'
                        }
                    }
                    It 'Should return the correct hashtable' {
                        Get-TargetResource @mockTestParameters | Should -Be $correctResult
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When Ensure is set to ''Present'' but the IP Address is not added to the cluster' {
                    $mockTestParmaters = @{
                        Ensure      = 'Present'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    Mock -CommandName Get-ClusterResource -MockWith {
                        return @{}
                    }

                    Mock -CommandName Get-ClusterIPResource -MockWith {
                        return @{}
                    }

                    It 'Should return an empty hashtable' {
                        Get-TargetResource @mockTestParameters | Should -Be @{}
                    }
                }

                Context 'When Ensure is set to ''Absent'' and the IP Address is added to the cluster' {
                    $mockTestParmaters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    $correctResult = @{
                        IPAddress   = $mockTestParameters.Address
                        AddressMask = $mockTestParameters.AddressMask
                        Ensure      = 'Absent'
                    }

                    Mock -CommandName Get-ClusterResource -MockWith {
                        return @{
                            Name = "IP Address $($mockTestParameters.Address)"
                            State = 'Online'
                            OnwerGroup = 'Cluster Group'
                            ResourceType = 'IP Address'
                        }
                    }

                    Mock -CommandName Get-ClusterIPResource -MockWith {
                        return @{
                            Address     = $mockTestParameters.Address
                            AddressMask = $mockTestParameters.AddressMask
                            Network     = '192.168.1.1'
                        }
                    }
                    It 'Should return the correct hashtable' {
                        Get-TargetResource @mockTestParameters | Should -Be $correctResult
                    }
                }
            }
        }

        Describe "$script:dscModuleName\Set-TargetResource" {
        }

        Describe "$script:dscModuleName\Test-TargetResource" {
        }
    }
}
finally {
    Invoke-TestCleanup
}
