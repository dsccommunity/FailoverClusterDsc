$script:DSCModuleName = 'FailoverClusterDsc'
$script:DSCResourceName = 'MSFT_ClusterDisk'

function Invoke-TestSetup
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ModuleVersion
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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "Stubs\FailoverClusters$ModuleVersion.stubs.psm1") -Global -Force
    $global:moduleVersion = $ModuleVersion
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    Remove-Variable -Name moduleVersion -Scope Global -ErrorAction SilentlyContinue
}

foreach ($moduleVersion in @('2012', '2016'))
{
    Invoke-TestSetup -ModuleVersion $moduleVersion

    try
    {
        InModuleScope $script:dscResourceName {
            $mockDiskNumber = '1'
            $mockDiskId = '{0182f270-e2b8-4579-8c0a-176e0e05c30c}'
            $mockDiskLabel = 'First Data'

            $mockNewDisk_Number = '2'
            $mockNewDisk_Id = '{5182f370-e2b8-4579-8caa-176e0e05c323}'
            $mockNewDisk_Label = 'Second Data'

            $mockDisk_WrongLabel = 'Wrong Label'

            $mockTestParameter_ShouldBePresentAndDiskExist = @{
                Number = $mockDiskNumber
                Ensure = 'Present'
                Label  = $mockDiskLabel
            }

            $mockTestParameter_ShouldBeAbsentButDiskExist = @{
                Number = $mockDiskNumber
                Ensure = 'Absent'
                Label  = $mockDiskLabel
            }

            $mockTestParameter_ShouldBePresentButDiskDoesNotExist = @{
                Number = $mockNewDisk_Number
                Ensure = 'Present'
                Label  = $mockNewDisk_Label
            }

            $mockTestParameter_ShouldBeAbsentAndDiskDoesNotExist = @{
                Number = '3'
                Ensure = 'Absent'
                Label  = 'Third Data'
            }

            $mockTestParameter_ShouldBePresentAndDiskExistButWrongLabel = @{
                Number = $mockDiskNumber
                Ensure = 'Present'
                Label  = $mockDisk_WrongLabel
            }

            $mockCimInstance = {
                switch ($Filter)
                {
                    "Number = $mockDiskNumber"
                    {
                        [PSCustomObject] @{
                            Name = $mockDiskLabel
                            Id   = $mockDiskId
                        }
                    }

                    default
                    {
                        $null
                    }
                }
            }

            $mockCimInstance_ParameterFilter = {
                $ClassName -eq 'MSCluster_Disk' -and $Namespace -eq 'Root\MSCluster'
            }

            $mockClusterResource = {
                @(
                    [PSCustomObject] @{
                        Name         = $mockDiskLabel
                        ResourceType = 'Physical Disk'
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru

                    [PSCustomObject] @{
                        Name         = $mockNewDisk_Label
                        ResourceType = 'Physical Disk'
                    } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru
                )
            }

            $mockGetClusterParameter = {
                switch ($InputObject.Name)
                {
                    $mockDiskLabel
                    {
                        [PSCustomObject] @{
                            Value = $mockDiskId
                        }
                    }

                    $mockNewDisk_Label
                    {
                        [PSCustomObject] @{
                            Value = $mockNewDisk_Id
                        }
                    }
                }
            }

            $mockGetClusterParameter_ParameterFilter = {
                $Name -eq 'DiskIdGuid'
            }

            $mockGetClusterAvailableDisk = {
                @(
                    [PSCustomObject] @{
                        Number = $mockNewDisk_Number
                    }
                )
            }
            Describe "ClusterDisk_$moduleVersion\Get-TargetResource" {
                BeforeAll {
                    Mock -CommandName 'Get-CimInstance' -MockWith $mockCimInstance -ParameterFilter $mockCimInstance_ParameterFilter
                    Mock -CommandName 'Get-ClusterResource' -MockWith $mockClusterResource
                    Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter -ParameterFilter $mockGetClusterParameter_ParameterFilter
                }

                Context 'When the system is not in the desired state' {
                    Context 'When Ensure is set to ''Present'' but the disk is not present' {
                        BeforeEach {
                            $mockTestParameters = @{
                                Number = $mockNewDisk_Number
                            }
                        }

                        It 'Should return the correct type' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Number | Should -Be $mockTestParameters.Number
                        }

                        It 'Should return the disk as absent' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Ensure | Should -Be 'Absent'
                            $getTargetResourceResult.Label | Should -BeNullOrEmpty
                        }
                    }

                    Context 'When Ensure is set to ''Absent'' and the disk is present' {
                        BeforeEach {
                            $mockTestParameters = @{
                                Number = $mockDiskNumber
                            }
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Number | Should -Be $mockTestParameters.Number
                        }

                        It 'Should return the disk as present' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Ensure | Should -Be 'Present'
                            $getTargetResourceResult.Label | Should -Be $mockDiskLabel
                        }
                    }

                    Context 'When Ensure is set to ''Present'' and the disk is present but has the wrong label' {
                        BeforeEach {
                            $mockTestParameters = @{
                                Number = $mockDiskNumber
                            }
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Number | Should -Be $mockTestParameters.Number
                        }

                        It 'Should return the correct value for property Ensure' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Ensure | Should -Be 'Present'
                        }

                        It 'Should return the correct value for property Label' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Label | Should -Not -Be $mockDisk_WrongLabel
                            $getTargetResourceResult.Label | Should -Be $mockDiskLabel
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    Context 'When Ensure is set to ''Present'' and the disk is present' {
                        BeforeEach {
                            $mockTestParameters = @{
                                Number = $mockDiskNumber
                            }
                        }

                        It 'Should return the correct type' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Number | Should -Be $mockTestParameters.Number
                            $getTargetResourceResult.Ensure | Should -Be 'Present'
                            $getTargetResourceResult.Label | Should -Be $mockDiskLabel
                        }
                    }

                    Context 'When Ensure is set to ''Absent'' and the disk is not present' {
                        BeforeEach {
                            $mockTestParameters = @{
                                Number = $mockNewDisk_Number
                            }
                        }

                        It 'Should return the same values as passed as parameters' {
                            $getTargetResourceResult = Get-TargetResource @mockTestParameters
                            $getTargetResourceResult.Number | Should -Be $mockTestParameters.Number
                            $getTargetResourceResult.Ensure | Should -Be 'Absent'
                            $getTargetResourceResult.Label | Should -BeNullOrEmpty
                        }
                    }
                }
            }

            Describe "ClusterDisk_$moduleVersion\Test-TargetResource" {
                BeforeAll {
                    Mock -CommandName 'Get-CimInstance' -MockWith $mockCimInstance -ParameterFilter $mockCimInstance_ParameterFilter
                    Mock -CommandName 'Get-ClusterResource' -MockWith $mockClusterResource
                    Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter -ParameterFilter $mockGetClusterParameter_ParameterFilter
                }

                Context 'When the system is not in the desired state' {
                    Context 'When Ensure is set to ''Present'' but the disk is not present' {
                        It 'Should return $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameter_ShouldBePresentButDiskDoesNotExist
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When Ensure is set to ''Absent'' and the disk is present' {
                        It 'Should return $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameter_ShouldBeAbsentButDiskExist
                            $testTargetResourceResult | Should -Be $false
                        }
                    }

                    Context 'When Ensure is set to ''Present'' and the disk is present but has the wrong label' {
                        It 'Should return $false' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameter_ShouldBePresentAndDiskExistButWrongLabel
                            $testTargetResourceResult | Should -Be $false
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    Context 'When Ensure is set to ''Present'' and the disk is present' {
                        It 'Should return $true' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameter_ShouldBePresentAndDiskExist
                            $testTargetResourceResult | Should -Be $true
                        }
                    }

                    Context 'When Ensure is set to ''Absent'' and the disk is not present' {
                        It 'Should return $true' {
                            $testTargetResourceResult = Test-TargetResource @mockTestParameter_ShouldBeAbsentAndDiskDoesNotExist
                            $testTargetResourceResult | Should -Be $true
                        }
                    }
                }
            }

            Describe "ClusterDisk_$moduleVersion\Set-TargetResource" {
                BeforeAll {
                    Mock -CommandName 'Get-CimInstance' -MockWith {
                        [PSCustomObject] @{
                            Name = $mockNewDisk_Label
                            Id   = $mockNewDisk_Id
                        }
                    }

                    Mock -CommandName 'Get-ClusterResource' -MockWith $mockClusterResource
                    Mock -CommandName 'Get-ClusterParameter' -MockWith $mockGetClusterParameter -ParameterFilter $mockGetClusterParameter_ParameterFilter
                    Mock -CommandName 'Get-ClusterAvailableDisk' -MockWith $mockGetClusterAvailableDisk
                    Mock -CommandName 'Add-ClusterDisk'
                    Mock -CommandName 'Remove-ClusterResource'
                }

                Context 'When the system is not in the desired state' {
                    Context 'When Ensure is set to ''Present'' but the disk is not present' {
                        BeforeEach {
                            Mock -CommandName 'Get-TargetResource' -MockWith {
                                @{
                                    Number = $mockNewDisk_Number
                                    Ensure = 'Absent'
                                    Label  = $null
                                }
                            }
                        }

                        It 'Should add the disk to the cluster' {
                            { Set-TargetResource @mockTestParameter_ShouldBePresentButDiskDoesNotExist } | Should -Not -Throw

                            Assert-MockCalled -CommandName Add-ClusterDisk -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Remove-ClusterResource -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When Ensure is set to ''Absent'' and the disk is present' {
                        BeforeEach {
                            Mock -CommandName 'Get-TargetResource' -MockWith {
                                @{
                                    Number = $mockDiskNumber
                                    Ensure = 'Present'
                                    Label  = $mockDiskLabel
                                }
                            }
                        }

                        It 'Should remove the disk from the cluster' {
                            { Set-TargetResource @mockTestParameter_ShouldBeAbsentButDiskExist } | Should -Not -Throw

                            Assert-MockCalled -CommandName Add-ClusterDisk -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Remove-ClusterResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the system is in the desired state' {
                    Context 'When Ensure is set to ''Present'' and the disk is present' {
                        BeforeEach {
                            Mock -CommandName 'Get-TargetResource' -MockWith {
                                @{
                                    Number = $mockDiskNumber
                                    Ensure = 'Present'
                                    Label  = $mockDiskLabel
                                }
                            }
                        }

                        It 'Should not call any cluster cmdlets' {
                            { Set-TargetResource @mockTestParameter_ShouldBePresentAndDiskExist } | Should -Not -Throw

                            Assert-MockCalled -CommandName Add-ClusterDisk -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Remove-ClusterResource -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When Ensure is set to ''Absent'' and the disk is not present' {
                        BeforeEach {
                            Mock -CommandName 'Get-TargetResource' -MockWith {
                                @{
                                    Number = $mockDiskNumber
                                    Ensure = 'Absent'
                                    Label  = $mockDiskLabel
                                }
                            }
                        }

                        It 'Should not call any cluster cmdlets' {
                            { Set-TargetResource @mockTestParameter_ShouldBeAbsentAndDiskDoesNotExist } | Should -Not -Throw

                            Assert-MockCalled -CommandName Add-ClusterDisk -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Remove-ClusterResource -Exactly -Times 0 -Scope It
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
}
