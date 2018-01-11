$script:DSCModuleName = 'xFailOverCluster'
$script:DSCResourceName = 'MSFT_xClusterProperty'

#region Header

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}


Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

try
{
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_xClusterThresholds'
        Describe $script:DSCResourceName {
            Context "$($script:DSCResourceName)\Get-TargetResource" {
                Mock -CommandName Get-Cluster -ParameterFilter {$Name -eq "Cluster1"} -MockWith {
                    [PSCustomObject] @{
                        SameSubnetDelay = 1000
                        SameSubnetThreshold = 5
                        CrossSubnetDelay = 1000
                        CrossSubnetThreshold = 5
                    }
                }

                It 'Returns a hashtable' {
                    (Get-TargetResource -Name Cluster1).GetType().Name | Should -Be 'Hashtable'
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Returns a hashtable with cluster properties' {
                    ((Get-TargetResource -Name Cluster1).GetEnumerator() | Where-Object {$_.Name -eq "SameSubnetDelay"}).Value `
                    | Should -Be '1000'
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }

            Context "$($script:DSCResourceName)\Test-TargetResource" {
                Mock -CommandName Get-Cluster -ParameterFilter {$Name -eq "Cluster1"} -MockWith {
                    [PSCustomObject] @{
                        SameSubnetDelay = 1000
                        SameSubnetThreshold = 5
                        CrossSubnetDelay = 1000
                        CrossSubnetThreshold = 5
                    }
                }

                It 'Returns true when cluster properties match parameters' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 1000 -SameSubnetThreshold 5 -CrossSubnetDelay 1000 `
                    -CrossSubnetThreshold 5 | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Returns false when one cluster property does not match parameters' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -SameSubnetThreshold 5 -CrossSubnetDelay 1000 `
                    -CrossSubnetThreshold 5 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Returns false when two cluster properties do not match parameters' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -SameSubnetThreshold 20 -CrossSubnetDelay 1000 `
                    -CrossSubnetThreshold 5 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Does not produce an exception when one property is not specified' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -CrossSubnetDelay 1000 -CrossSubnetThreshold 5 `
                    | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Does not produce an exception when two properties are not specified' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -CrossSubnetThreshold 5 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }

            Context "$($script:DSCResourceName)\Set-TargetResource" {
                Mock -CommandName Get-Cluster -ParameterFilter {$Name -eq "Cluster1"} -MockWith {
                    [PSCustomObject] @{
                        SameSubnetDelay = 1000
                        SameSubnetThreshold = 5
                        CrossSubnetDelay = 1000
                        CrossSubnetThreshold = 5
                    }
                }

                It 'Sets a single cluster property' {
                    Set-TargetResource -Name Cluster1 -SameSubnetDelay 2000 | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Sets multiple cluster properties' {
                    Set-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -SameSubnetThreshold 5 | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 2 -Scope It
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
