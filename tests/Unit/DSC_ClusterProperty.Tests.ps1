$script:DSCModuleName = 'FailoverClusterDsc'
$script:DSCResourceName = 'DSC_ClusterProperty'

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

try
{
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'DSC_ClusterProperty'

        Describe $script:DSCResourceName {
            Context "$($script:DSCResourceName)\Get-TargetResource" {
                Mock -CommandName Get-Cluster -ParameterFilter {$Name -eq 'Cluster1'} -MockWith {
                    [PSCustomObject] @{
                        SameSubnetDelay = 1000
                        SameSubnetThreshold = 5
                        CrossSubnetDelay = 1000
                        CrossSubnetThreshold = 5
                    }
                }

                It 'Returns a hashtable' {
                    Get-TargetResource -Name Cluster1 | Should -BeOfType [System.Collections.Hashtable]
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Returns a hashtable with cluster properties' {
                    (Get-TargetResource -Name Cluster1).Get_Item('SameSubnetDelay') | Should -Be '1000'
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }

            Context "$($script:DSCResourceName)\Set-TargetResource" {
                Mock -CommandName Get-Cluster -ParameterFilter {$Name -eq 'Cluster1'} -MockWith {
                    [PSCustomObject] @{
                        Description = ''
                        PreferredSite = ''
                        SameSubnetDelay = 1000
                        SameSubnetThreshold = 5
                        CrossSubnetDelay = 1000
                        CrossSubnetThreshold = 5
                    }
                }

                It 'Sets a single integer cluster property' {
                    Set-TargetResource -Name Cluster1 -SameSubnetDelay 2000 | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Sets multiple integer cluster properties' {
                    Set-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -SameSubnetThreshold 5 | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Sets a single string cluster property' {
                    Set-TargetResource -Name Cluster1 -Description 'Exchange DAG' | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Sets a single string cluster property to an empty string' {
                    Set-TargetResource -Name Cluster1 -Description '' | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Sets a multiple string cluster properties' {
                    Set-TargetResource -Name Cluster1 -Description 'Exchange DAG' -PreferredSite 'London' `
                    | Should -Be $null
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }

            Context "$($script:DSCResourceName)\Test-TargetResource" {
                Mock -CommandName Get-Cluster -ParameterFilter {$Name -eq 'Cluster1'} -MockWith {
                    [PSCustomObject] @{
                        AddEvictDelay = 60
                        BlockCacheSize = 1024
                        CrossSubnetDelay = 1000
                        CrossSubnetThreshold = 5
                        Description = ''
                        PreferredSite = 'Default-First-Site-Name'
                        SameSubnetDelay = 1000
                        SameSubnetThreshold = 5
                    }
                }

                It 'Checks a single integer cluster property and returns false if incorrect' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 2000 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks a single integer cluster property and returns true if correct' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 1000 | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks multiple integer cluster properties and returns false if incorrect' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 2000 -SameSubnetThreshold 6 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks multiple integer cluster properties and returns true if correct' {
                    Test-TargetResource -Name Cluster1 -SameSubnetDelay 1000 -SameSubnetThreshold 5 | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks a single string cluster property and returns false if incorrect' {
                    Test-TargetResource -Name Cluster1 -Description 'Exchange DAG' | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks a single string cluster property and returns true if correct' {
                    Test-TargetResource -Name Cluster1 -PreferredSite 'Default-First-Site-Name' | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks multiple string cluster properties and returns false if incorrect' {
                    Test-TargetResource -Name Cluster1 -Description 'Exchange DAG' -PreferredSite 'Default-First-Site-Name' `
                    | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks multiple string cluster properties and returns true if correct' {
                    Test-TargetResource -Name Cluster1 -Description '' -PreferredSite 'Default-First-Site-Name' `
                    | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks single integer cluster property and returns true if correct' {
                    Test-TargetResource -Name Cluster1 -BlockCacheSize 1024 | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Checks single integer cluster property and returns false if incorrect' {
                    Test-TargetResource -Name Cluster1 -BlockCacheSize 2048 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Handles checking multiple string and integer properties and returns true if correct' {
                    Test-TargetResource -Name Cluster1 -Description '' -PreferredSite 'Default-First-Site-Name' `
                    -AddEvictDelay 60 -SameSubnetDelay 1000 | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Handles checking multiple string and integer properties and returns false if incorrect' {
                    Test-TargetResource -Name Cluster1 -Description 'Exchange DAG' -PreferredSite 'Default-First-Site-Name' `
                    -AddEvictDelay 60 -SameSubnetDelay 1500 | Should -Be $false
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }

                It 'Handles checking properties against empty strings' {
                    Test-TargetResource -Name Cluster1 -Description '' | Should -Be $true
                    Assert-MockCalled -CommandName Get-Cluster -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
