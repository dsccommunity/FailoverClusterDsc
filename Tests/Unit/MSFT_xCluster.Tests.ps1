<#
    Suppressing this rule because a plain text password variable is used to mock the LogonUser static
    method and is required for the tests.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
param()

$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xCluster'

#region HEADER

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

#endregion HEADER

function Invoke-TestSetup
{
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'Unit') -ChildPath 'Stubs') -ChildPath 'FailoverClusters.stubs.psm1') -Global -Force
    Import-Module -Name (Join-Path -Path (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests') -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global -Force
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
        $mockAdministratorUserName = 'COMPANY\ClusterAdmin'
        $mockAdministratorPassword = ConvertTo-SecureString -String 'dummyPassW0rd' -AsPlainText -Force
        $mockAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($mockAdministratorUserName, $mockAdministratorPassword)

        $mockDomainName = 'domain.local'
        $mockServerName = $env:COMPUTERNAME
        $mockClusterName = 'CLUSTER001'
        $mockStaticIpAddress = '192.168.10.10'


        $mockGetCimInstance = {
            return [PSCustomObject] @{
                Domain = $mockDynamicDomainName
                Name   = $mockDynamicServerName
            }
        }

        $mockGetCimInstance_ParameterFilter = {
            $ClassName -eq 'Win32_ComputerSystem'
        }

        $mockGetCluster = {
            return [PSCustomObject] @{
                Domain = $mockDomainName
                Name   = $mockClusterName
            }
        }

        $mockGetCluster_ParameterFilter = {
            $Name -eq $mockDefaultParameters.Name -and $Domain -eq $mockDomainName
        }

        $mockGetClusterResource = {
            return @{
                Name         = 'Cluster IP Address'
                OwnerNode    = 'Cluster Group'
                State        = 'Online'
                ResourceType = 'IP Address'
            }
        }

        $mockGetClusterResource_ParameterFilter = {
            $Cluster -eq $mockClusterName -and $Name -eq 'Cluster IP Address'
        }

        $mockGetClusterParameter = {
            return @{
                Object = 'Cluster IP Address'
                Name   = 'Address'
                Value  = $mockStaticIpAddress
            }
        }

        $mockGetClusterNode = {
            return @(
                @{
                    Name  = $mockServerName
                    State = $mockDynamicClusterNodeState
                }
            )
        }

        $mockNewObjectWindowsIdentity = {
            return [PSCustomObject] @{} |
                Add-Member -MemberType ScriptMethod -Name Impersonate -Value {
                return [PSCustomObject] @{} |
                    Add-Member -MemberType ScriptMethod -Name Undo -Value {} -PassThru |
                    Add-Member -MemberType ScriptMethod -Name Dispose -Value {} -PassThru -Force
            } -PassThru -Force
        }

        $mockNewObjectWindowsIdentity_ParameterFilter = {
            $TypeName -eq 'Security.Principal.WindowsIdentity'
        }

        $mockDefaultParameters = @{
            Name                          = $mockClusterName
            StaticIPAddress               = $mockStaticIpAddress
            DomainAdministratorCredential = $mockAdministratorCredential
        }

        class MockLibImpersonation
        {
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

        [MockLibImpersonation]::ReturnValue = $true
        $mockLibImpersonationObject = [MockLibImpersonation]::New()

        Describe 'xCluster\Get-TargetResource' {
            BeforeAll {
                $mockGetTargetResourceParameters = $mockDefaultParameters.Clone()
                $mockGetTargetResourceParameters.Remove('StaticIPAddress')

                Mock -CommandName Add-Type -MockWith {
                    return $mockLibImpersonationObject
                }

                Mock -CommandName New-Object -MockWith $mockNewObjectWindowsIdentity -ParameterFilter $mockNewObjectWindowsIdentity_ParameterFilter -Verifiable
            }

            Context 'When the computers domain name cannot be evaluated' {
                It 'Should throw the correct error message' {
                    $mockDynamicDomainName = $null
                    $mockDynamicServerName = $mockServerName

                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable

                    $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TargetNodeDomainMissing
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw $mockCorrectErrorRecord
                }
            }

            Context 'When the cluster cannot be found' {
                It 'Should throw the correct error message' {
                    $mockDynamicDomainName = $mockDomainName
                    $mockDynamicServerName = $mockServerName

                    Mock -CommandName Get-Cluster -Verifiable
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable

                    $mockCorrectErrorRecord = Get-ObjectNotFoundException -Message ($script:localizedData.ClusterNameNotFound -f $mockClusterName)
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw $mockCorrectErrorRecord
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable
                    Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                    Mock -CommandName Get-ClusterResource -MockWith $mockGetClusterResource -ParameterFilter $mockGetClusterResource_ParameterFilter -Verifiable
                    Mock -CommandName Get-ClusterParameter -MockWith $mockGetClusterParameter -Verifiable
                }

                $mockDynamicDomainName = $mockDomainName
                $mockDynamicServerName = $mockServerName

                It 'Returns a [System.Collection.Hashtable] type' {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                    $getTargetResourceResult | Should -BeOfType [System.Collections.Hashtable]
                }

                It 'Returns current configuration' {
                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                    $getTargetResourceResult.Name             | Should -Be $mockDefaultParameters.Name
                    $getTargetResourceResult.StaticIPAddress  | Should -Be $mockDefaultParameters.StaticIPAddress
                    $getTargetResourceResult.IgnoreNetwork    | Should -BeNullOrEmpty
                }

                Context 'When IgnoreNetwork is passed' {
                    It 'Should returns IgnoreNetwork in the hash' {
                        $withIgnoreNetworkParameter = $mockDefaultParameters + @{
                            IgnoreNetwork = '10.0.2.0/24'
                        }

                        $getTargetResourceResult = Get-TargetResource @withIgnoreNetworkParameter
                        $getTargetResourceResult.IgnoreNetwork | Should -Be '10.0.2.0/24'
                    }
                }

                Assert-VerifiableMock
            }
        }

        Describe 'xCluster\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Add-Type -MockWith {
                    return $mockLibImpersonationObject
                }

                Mock -CommandName New-Object -MockWith $mockNewObjectWindowsIdentity -ParameterFilter $mockNewObjectWindowsIdentity_ParameterFilter -Verifiable
            }

            Context 'When computers domain name cannot be evaluated' {
                It 'Should throw the correct error message' {
                    $mockDynamicDomainName = $null
                    $mockDynamicServerName = $mockServerName

                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable

                    $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TargetNodeDomainMissing
                    { Set-TargetResource @mockDefaultParameters } | Should -Throw $mockCorrectErrorRecord
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock -CommandName New-Cluster -Verifiable
                    Mock -CommandName Remove-ClusterNode -Verifiable
                    Mock -CommandName Add-ClusterNode -Verifiable
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable
                }

                $mockDynamicDomainName = $mockDomainName
                $mockDynamicServerName = $mockServerName

                Context 'When the cluster does not exist' {
                    Context 'When Get-Cluster returns nothing' {
                        BeforeAll {
                            # This is used for the evaluation of that cluster do not exist.
                            Mock -CommandName Get-Cluster -ParameterFilter $mockGetCluster_ParameterFilter

                            # This is used to evaluate that cluster do exists after New-Cluster cmdlet has been run.
                            Mock -CommandName Get-Cluster -MockWith $mockGetCluster
                        }

                        Context 'When using static IP address' {
                            It 'Should call New-Cluster cmdlet using StaticAddress parameter' {
                                { Set-TargetResource @mockDefaultParameters } | Should Not Throw

                                Assert-MockCalled -CommandName New-Cluster -ParameterFilter {
                                    $StaticAddress -eq $mockStaticIpAddress
                                } -Exactly -Times 1 -Scope It

                                Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                            }
                        }

                        Context 'When assigned IP address from DHCP' {
                            It 'Should call New-Cluster cmdlet using StaticAddress parameter' {
                                $mockTestParameters = $mockDefaultParameters.Clone()
                                $mockTestParameters.Remove('StaticIPAddress')

                                { Set-TargetResource @mockTestParameters } | Should Not Throw

                                Assert-MockCalled -CommandName New-Cluster -ParameterFilter {
                                    $null -eq $StaticAddress
                                } -Exactly -Times 1 -Scope It

                                Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                            }
                        }


                        Context 'When IgnoreNetwork is passed as a single value' {
                            It 'Should call New-Cluster cmdlet with IgnoreNetwork parameter' {
                                $withIgnoreNetworkParameter = $mockDefaultParameters + @{
                                    IgnoreNetwork = '10.0.2.0/24'
                                }
                                { Set-TargetResource @withIgnoreNetworkParameter } | Should Not Throw

                                Assert-MockCalled -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                                    $IgnoreNetwork -eq '10.0.2.0/24'
                                }
                                Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                            }
                        }

                        Context 'When Nodes is passed' {
                            It 'Should call New-Cluster cmdlet with Node as an array' {
                                $withNodesParameter = $mockDefaultParameters + @{
                                    Nodes = ('foo','bar')
                                }
                                { Set-TargetResource @withNodesParameter } | Should Not Throw

                                Assert-MockCalled -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                                    $Node.Contains($env:COMPUTERNAME) -eq $true `
                                    -and $Node.Contains('foo') -eq $true `
                                    -and $Node.Contains('bar') -eq $true
                                }
                                Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                            }
                        }

                        Context 'When IgnoreNetwork is passed as an array' {
                            It 'Should call New-Cluster cmdlet with IgnoreNetwork parameter' {
                                $withIgnoreNetworkParameter = $mockDefaultParameters + @{ IgnoreNetwork = ('10.0.2.0/24', '192.168.4.0/24') }
                                { Set-TargetResource @withIgnoreNetworkParameter } | Should Not Throw

                                Assert-MockCalled -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                                    $IgnoreNetwork -eq '10.0.2.0/24' -and
                                    $IgnoreNetwork -eq '192.168.4.0/24'
                                }
                                Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                            }
                        }

                        Context 'When IgnoreNetwork is not passed' {
                            It 'Should call New-Cluster cmdlet without IgnoreNetwork parameter' {
                                { Set-TargetResource @mockDefaultParameters } | Should Not Throw

                                Assert-MockCalled -CommandName New-Cluster -Exactly -Times 1 -Scope It -ParameterFilter {
                                    $IgnoreNetwork -eq $null
                                }
                                Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                                Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                            }
                        }
                    }

                    Context 'When Get-Cluster throws an error' {
                        It 'Should call New-Cluster cmdlet' {
                            # This is used for the evaluation of that cluster do not exist.
                            Mock -CommandName Get-Cluster -MockWith {
                                throw 'Mock Get-Cluster throw error'
                            } -ParameterFilter $mockGetCluster_ParameterFilter

                            # This is used to evaluate that cluster do exists after New-Cluster cmdlet has been run.
                            Mock -CommandName Get-Cluster -MockWith $mockGetCluster

                            { Set-TargetResource @mockDefaultParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName New-Cluster -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When the cluster does not exist, and New-Cluster is run, but no cluster can be found after' {
                    It 'Should throw the correct error message' {
                        Mock -CommandName Get-Cluster

                        $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.FailedCreatingCluster
                        { Set-TargetResource @mockDefaultParameters } | Should -Throw $mockCorrectErrorRecord

                        Assert-MockCalled -CommandName New-Cluster -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }
                }

                Context 'When the cluster exist but the node is not part of the cluster' {
                    It 'Should call Add-ClusterNode cmdlet' {
                        Mock -CommandName Get-ClusterNode
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter

                        { Set-TargetResource @mockDefaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-Cluster -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the cluster exist and the node is down' {
                    BeforeEach {
                        Mock -CommandName Get-ClusterNode -MockWith $mockGetClusterNode
                    }

                    $mockDynamicClusterNodeState = 'Down'

                    It 'Should call both Remove-ClusterNode and Add-ClusterNode cmdlet' {
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter

                        { Set-TargetResource @mockDefaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-Cluster -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-ClusterNode -Verifiable
                    Mock -CommandName New-Cluster -Verifiable
                    Mock -CommandName Remove-ClusterNode -Verifiable
                    Mock -CommandName Add-ClusterNode -Verifiable
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable
                    Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                    Mock -CommandName Get-ClusterParameter -MockWith $mockGetClusterParameter -Verifiable

                    Mock -CommandName Get-ClusterResource -MockWith {
                        @{
                            Name         = 'Resource1'
                            State        = 'Online'
                            OwnerGroup   = 'ClusterGroup1'
                            ResourceType = 'type1'
                        }
                    } -Verifiable
                }

                $mockDynamicDomainName = $mockDomainName
                $mockDynamicServerName = $mockServerName

                Context 'When the node already exist' {
                    # This test is skipped because due to a logic error it's not possible to test this (issue #79)
                    It 'Should not call any of the cluster cmdlets' -Skip {
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable

                        { Set-TargetResource @mockDefaultParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName New-Cluster -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Remove-ClusterNode -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Add-ClusterNode -Exactly -Times 0 -Scope It
                    }

                    Assert-VerifiableMock
                }
            }
        }

        Describe 'xCluster\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Add-Type -MockWith {
                    return $mockLibImpersonationObject
                }

                Mock -CommandName New-Object -MockWith $mockNewObjectWindowsIdentity -ParameterFilter $mockNewObjectWindowsIdentity_ParameterFilter -Verifiable
            }

            Context 'When computers domain name cannot be evaluated' {
                It 'Should throw the correct error message' {
                    $mockDynamicDomainName = $null
                    $mockDynamicServerName = $mockServerName

                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable

                    $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TargetNodeDomainMissing
                    { Test-TargetResource @mockDefaultParameters } | Should -Throw $mockCorrectErrorRecord
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable
                }

                $mockDynamicDomainName = $mockDomainName
                $mockDynamicServerName = $mockServerName

                Context 'When the cluster does not exist' {
                    It 'Should return $false' {
                        Mock -CommandName Get-Cluster -Verifiable

                        $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                        $testTargetResourceResult | Should -Be $false
                    }

                    Assert-VerifiableMock
                }

                Context 'When the Get-Cluster throws an error' {
                    It 'Should return $false' {
                        Mock -CommandName Get-Cluster -MockWith {
                            throw 'Mock Get-Cluster throw error'
                        } -Verifiable

                        $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                        $testTargetResourceResult | Should -Be $false
                    }

                    Assert-VerifiableMock
                }

                Context 'When the node does not exist' {
                    It 'Should return $false' {
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                        Mock -CommandName Get-ClusterNode -Verifiable

                        $testTargetResourceResult = Test-TargetResource @mockDefaultParameters

                        $testTargetResourceResult | Should -Be $false
                    }

                    Assert-VerifiableMock
                }

                Context 'When the node do exist, but is down' {
                    BeforeEach {
                        Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                        Mock -CommandName Get-ClusterNode -MockWith $mockGetClusterNode
                    }

                    $mockDynamicClusterNodeState = 'Down'

                    It 'Should return $false' {
                        $testTargetResourceResult = Test-TargetResource @mockDefaultParameters

                        $testTargetResourceResult | Should -Be $false
                    }

                    Assert-VerifiableMock
                }

            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    Mock -CommandName Get-ClusterNode -MockWith $mockGetClusterNode -Verifiable
                    Mock -CommandName Get-CimInstance -MockWith $mockGetCimInstance -ParameterFilter $mockGetCimInstance_ParameterFilter -Verifiable
                    Mock -CommandName Get-Cluster -MockWith $mockGetCluster -ParameterFilter $mockGetCluster_ParameterFilter -Verifiable
                }

                $mockDynamicDomainName = $mockDomainName
                $mockDynamicServerName = $mockServerName
                $mockDynamicClusterNodeState = 'Up'

                Context 'When the node already exist' {
                    It 'Should return $true' {
                        $testTargetResourceResult = Test-TargetResource @mockDefaultParameters
                        $testTargetResourceResult | Should -Be $true
                    }

                    Assert-VerifiableMock
                }
            }
        }

        [MockLibImpersonation]::ReturnValue = $false
        $mockLibImpersonationObject = [MockLibImpersonation]::New()

        Describe 'xCluster\Set-ImpersonateAs' -Tag 'Helper' {
            Context 'When impersonating credentials fails' {
                It 'Should throw the correct error message' {
                    Mock -CommandName Add-Type -MockWith {
                        return $mockLibImpersonationObject
                    }

                    $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.UnableToImpersonateUser -f $mockAdministratorCredential.GetNetworkCredential().UserName)
                    { Set-ImpersonateAs -Credential $mockAdministratorCredential } | Should -Throw $mockCorrectErrorRecord
                }
            }
        }

        Describe 'xCluster\Close-UserToken' -Tag 'Helper' {
            Context 'When closing user token fails' {
                It 'Should throw the correct error message' {
                    Mock -CommandName Add-Type -MockWith {
                        return $mockLibImpersonationObject
                    } -Verifiable

                    $mockToken = [System.IntPtr]::New(12345)

                    $mockCorrectErrorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.UnableToCloseToken -f $mockToken.ToString())
                    { Close-UserToken -Token $mockToken } | Should -Throw $mockCorrectErrorRecord
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
