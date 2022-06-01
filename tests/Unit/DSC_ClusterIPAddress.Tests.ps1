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

                Mock -CommandName Get-ClusterIPResource -MockWith {
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

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.NonExistantClusterNetwork -f $IPAddress, $SubnetMask) `
                    -ArgumentName 'IPAddress', 'SubnetMask'

                Mock -CommandName Test-ClusterNetwork -MockWith { $False }

                It "Should throw if the network of the IP address and subnet mask combination is not added to the cluster" {

                    Set-TargetResource @mockTestParameters | Should -Throw $errorRecord
                }

                $mockTestParameters = @{
                    Ensure      = 'Present'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                Mock -CommandName Test-ClusterNetwork -MockWith { $True }

                It "Should not throw" {

                    Set-TargetResource @mockTestParameters | Should -Not -Throw
                }
            }

            Context "IP address should be absent" {
                # $mockTestParameters = @{
                #     Ensure      = 'Absent'
                #     IPAddress   = '192.168.1.41'
                #     AddressMask = '255.255.255.0'
                # }



                # Set-TargetResource @mockTestParameters | Should -Not -Throw

            }

            # Present
            ## Should throw if Test-ClusterNetwork is false : New-InvalidArgumentException -Message ($script:localizedData.NonExistantClusterNetwork -f $IPAddress,$AddressMask)
            ## Should Not throw
            # Absent
            ## Should not throw
        }

        Describe "$script:DSCResourceName\Test-TargetResource" {
            Mock -CommandName Test-IPAddress
            # Present
            ## Should throw if $ipResource.IPAddress is null or empty
            ## False if $ipResource.ipaddress -ne $ipaddress
            ## False if $ipResource.AddressMask -ne $AddressMask
            ## True if $ipResource.ipaddress -e1 $ipaddress
            ## True if $ipResource.AddressMask -eq $AddressMask
            # Absent
            ## Should throw if $ipResource.IPAddress is NOT null or empty
            ## True if $ipResource.IPAddress -eq $null
            ## False if -ne $null
        }
    }
}
finally {
    Invoke-TestCleanup
}
