[CmdletBinding()]
param
(
)

if (!$PSScriptRoot)
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
$ModuleName = 'MSFT_xClusterQuorum'

try
{
    if (-not (Get-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction Stop).Installed)
    {
        Add-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction Stop
    }
}
catch
{
    Write-Warning $_
}

Import-Module (Join-Path -Path $RootPath -ChildPath "DSCResources\$ModuleName\$ModuleName.psm1") -Force


## General test for the xClusterQuorum resource

Describe 'xClusterQuorum' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndDiskMajority'
            Resource         = 'Witness'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumResource = 'Witness'
                QuorumType     = 'NodeAndDiskMajority'
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns a [System.Collection.Hashtable] type' {

                $Result = Get-TargetResource @TestParameter

                $Result -is [System.Collections.Hashtable] | Should Be $true
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Returns nothing' {

                $Result = Set-TargetResource @TestParameter

                $Result -eq $null | Should Be $true
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Returns a [System.Boolean] type' {

                $Result = Test-TargetResource @TestParameter

                $Result -is [System.Boolean] | Should Be $true
            }
        }
    }
}


## Test NodeMajority quorum type

Describe 'xClusterQuorum (NodeMajority / WS2012R2)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeMajority'
            Resource         = ''
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'NodeMajority'
                QuorumResource = $null
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $NoWitness -eq $true } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $NoWitness -eq $true } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}

Describe 'xClusterQuorum (NodeMajority / WS2016Prev)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeMajority'
            Resource         = ''
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'Majority'
                QuorumResource = $null
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $NoWitness -eq $true } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $NoWitness -eq $true } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}


## Test NodeAndDiskMajority quorum type

Describe 'xClusterQuorum (NodeAndDiskMajority / WS2012R2)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndDiskMajority'
            Resource         = 'Witness'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'NodeAndDiskMajority'
                QuorumResource = [PSCustomObject] @{
                    Name           = 'Witness'
                    OwnerGroup     = 'Cluster Group'
                    ResourceType   = [PSCustomObject] @{
                        DisplayName    = 'Physical Disk'
                    }
                }
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskWitness -eq 'Witness' } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskWitness -eq 'Witness' } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}

Describe 'xClusterQuorum (NodeAndDiskMajority / WS2016Prev)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndDiskMajority'
            Resource         = 'Witness'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'Majority'
                QuorumResource = [PSCustomObject] @{
                    Name           = 'Witness'
                    OwnerGroup     = 'Cluster Group'
                    ResourceType   = [PSCustomObject] @{
                        DisplayName    = 'Physical Disk'
                    }
                }
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskWitness -eq 'Witness' } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskWitness -eq 'Witness' } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}


## Test NodeAndFileShareMajority quorum type

Describe 'xClusterQuorum (NodeAndFileShareMajority / WS2012R2)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndFileShareMajority'
            Resource         = '\\FILE01\CLUSTER01'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'NodeAndFileShareMajority'
                QuorumResource = [PSCustomObject] @{
                    Name           = 'File Share Witness'
                    OwnerGroup     = 'Cluster Group'
                    ResourceType   = [PSCustomObject] @{
                        DisplayName    = 'File Share Witness'
                    }
                }
            }
        }
        
        Mock -CommandName 'Get-ClusterParameter' -ParameterFilter { $Name -eq 'SharePath' } -MockWith {
            @(
                [PSCustomObject] @{
                    ClusterObject = 'File Share Witness'
                    Name          = 'SharePath'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = '\\FILE01\CLUSTER01'
                }
            )
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $FileShareWitness -eq '\\FILE01\CLUSTER01' } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $FileShareWitness -eq '\\FILE01\CLUSTER01' } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}

Describe 'xClusterQuorum (NodeAndFileShareMajority / WS2016Prev)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'NodeAndFileShareMajority'
            Resource         = '\\FILE01\CLUSTER01'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'Majority'
                QuorumResource = [PSCustomObject] @{
                    Name           = 'File Share Witness'
                    OwnerGroup     = 'Cluster Group'
                    ResourceType   = [PSCustomObject] @{
                        DisplayName    = 'File Share Witness'
                    }
                }
            }
        }
        
        Mock -CommandName 'Get-ClusterParameter' -ParameterFilter { $Name -eq 'SharePath' } -MockWith {
            @(
                [PSCustomObject] @{
                    ClusterObject = 'File Share Witness'
                    Name          = 'SharePath'
                    IsReadOnly    = 'False'
                    ParameterType = 'String'
                    Value         = '\\FILE01\CLUSTER01'
                }
            )
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $FileShareWitness -eq '\\FILE01\CLUSTER01' } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $FileShareWitness -eq '\\FILE01\CLUSTER01' } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}


## Test DiskOnly quorum type

Describe 'xClusterQuorum (NodeAndDiskMajority / WS2012R2)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'DiskOnly'
            Resource         = 'Witness'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'DiskOnly'
                QuorumResource = [PSCustomObject] @{
                    Name           = 'Witness'
                    OwnerGroup     = 'Cluster Group'
                    ResourceType   = [PSCustomObject] @{
                        DisplayName    = 'Physical Disk'
                    }
                }
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskOnly -eq 'Witness' } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskOnly -eq 'Witness' } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}

Describe 'xClusterQuorum (NodeAndDiskMajority / WS2016Prev)' {

    InModuleScope $ModuleName {
    
        $TestParameter = @{
            IsSingleInstance = 'Yes'
            Type             = 'DiskOnly'
            Resource         = 'Witness'
        }

        Mock -CommandName 'Get-ClusterQuorum' -MockWith {
            [PSCustomObject] @{
                Cluster        = 'CLUSTER01'
                QuorumType     = 'DiskOnly'
                QuorumResource = [PSCustomObject] @{
                    Name           = 'Witness'
                    OwnerGroup     = 'Cluster Group'
                    ResourceType   = [PSCustomObject] @{
                        DisplayName    = 'Physical Disk'
                    }
                }
            }
        }

        Mock -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskOnly -eq 'Witness' } -MockWith {
        }
        
        Context 'Validate Get-TargetResource method' {

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter

                $Result.IsSingleInstance | Should Be $TestParameter.IsSingleInstance
                $Result.Type             | Should Be $TestParameter.Type
                $Result.Resource         | Should Be $TestParameter.Resource
            }
        }
        
        Context 'Validate Set-TargetResource method' {

            It 'Set the new configuration' {

                $Result = Set-TargetResource @TestParameter

                Assert-MockCalled -CommandName 'Set-ClusterQuorum' -ParameterFilter { $DiskOnly -eq 'Witness' } -Times 1
            }
        }
        
        Context 'Validate Test-TargetResource method' {

            It 'Check the current configuration' {

                $Result = Test-TargetResource @TestParameter

                $Result | Should Be $true
            }
        }
    }
}

