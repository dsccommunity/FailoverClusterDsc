
if (!$PSScriptRoot)
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
$ModuleName = 'MSFT_xClusterDisk'

if((Get-CimInstance -ClassName 'Win32_OperatingSystem').ProductType -ne 1)
{
    # For server operating system
    if (-not (Get-WindowsFeature -Name RSAT-Clustering-PowerShell).Installed)
    {
        Add-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction Stop
    }
}
else
{
    # For client operating system
    if ((Get-WindowsOptionalFeature -Online -FeatureName 'RSATClient-Features-Clustering').State -ne 'Enabled')
    {
        Enable-WindowsOptionalFeature -Online -FeatureName 'RSATClient-Features-Clustering' -ErrorAction Stop
    }
}

Import-Module (Join-Path -Path $RootPath -ChildPath "DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe 'xClusterDisk' {

    InModuleScope $ModuleName {

        Mock Get-ClusterActiveDisk -ModuleName $ModuleName {
            New-Object -TypeName PSObject -Property @{
                Guid     = '00000000-0000-0000-0000-000000000001'
                Label    = 'Cluster Disk 1'
                Resource = New-Object -TypeName PSObject -Property @{
                    Name     = 'Cluster Disk 1'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru
            }
            New-Object -TypeName PSObject -Property @{
                Guid     = '00000000-0000-0000-0000-000000000002'
                Label    = 'Witness'
                Resource = New-Object -TypeName PSObject -Property @{
                    Name     = 'Witness'
                } | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru
            }
        }

        Context 'Validate Get-TargetResource method' {

            It 'should return a [System.Collection.Hashtable] type' {

                # Arrange
                $expectedType = 'System.Collections.Hashtable'

                # Act
                $result = Get-TargetResource -Guid '00000000-0000-0000-0000-000000000001'

                # Assert
                $result | Should BeOfType $expectedType
            }

            It 'should return configuration for an present disk (Cluster Disk 1)' {

                # Arrange
                $expectedEnsure = 'Present'
                $expectedGuid   = '00000000-0000-0000-0000-000000000001'
                $expectedLabel  = 'Cluster Disk 1'

                # Act
                $result = Get-TargetResource -Guid $expectedGuid

                # Assert
                $result.Guid   | Should Be $expectedGuid
                $result.Ensure | Should Be $expectedEnsure
                $result.Label  | Should Be $expectedLabel
            }

            It 'should return configuration for an present disk (Witness)' {

                # Arrange
                $expectedEnsure = 'Present'
                $expectedGuid   = '00000000-0000-0000-0000-000000000002'
                $expectedLabel  = 'Witness'

                # Act
                $result = Get-TargetResource -Guid $expectedGuid

                # Assert
                $result.Guid   | Should Be $expectedGuid
                $result.Ensure | Should Be $expectedEnsure
                $result.Label  | Should Be $expectedLabel
            }

            It 'should return configuration for an absent disk' {

                # Arrange
                $expectedEnsure = 'Absent'
                $expectedGuid   = '00000000-0000-0000-0000-000000000003'

                # Act
                $result = Get-TargetResource -Guid $expectedGuid

                # Assert
                $result.Guid   | Should Be $expectedGuid
                $result.Ensure | Should Be $expectedEnsure
            }
        }

        Context 'Validate Set-TargetResource method' {

            Mock Get-ClusterAvailableDisk -ModuleName $ModuleName {
                New-Object -TypeName PSObject -ArgumentList @{
                    Name       = 'Cluster Disk 3'
                    Number     = '3'
                    Size       = '107374182400'
                    Id         = '00000000-0000-0000-0000-000000000003'
                    Cluster    = 'CLUSTER01'
                    Partitions = @()
                }
            }

            Mock Add-ClusterDisk -ModuleName $ModuleName -Verifiable { }

            Mock Remove-ClusterResource -ModuleName $ModuleName -Verifiable { }

            It 'should return a [void] type' {

                # Arrange

                # Act
                $result = Set-TargetResource -Guid '00000000-0000-0000-0000-000000000001'

                # Assert
                $result | Should BeNullOrEmpty
            }

            It 'should add a new disk to the cluster' {

                # Arrange
                $actualEnsure = 'Present'
                $actualGuid   = '00000000-0000-0000-0000-000000000003'

                # Act
                $result = Set-TargetResource -Ensure $actualEnsure -Guid $actualGuid

                # Assert
                Assert-MockCalled Add-ClusterDisk -Exactly 1 -Scope It
            }

            It 'should remove an existing disk from the cluster' {

                # Arrange
                $actualEnsure = 'Absent'
                $actualGuid   = '00000000-0000-0000-0000-000000000001'

                # Act
                $result = Set-TargetResource -Ensure $actualEnsure -Guid $actualGuid

                # Assert
                Assert-MockCalled Remove-ClusterResource -Exactly 1 -Scope It
            }
        }

        Context 'Validate Test-TargetResource method' {

            It 'should return a [System.Boolean] type' {

                # Arrange
                $expectedType = 'System.Boolean'

                # Act
                $result = Test-TargetResource -Guid '00000000-0000-0000-0000-000000000001'

                # Assert
                $result | Should BeOfType $expectedType
            }

            It 'should return $true for a desired present disk' {

                # Arrange
                $actualEnsure = 'Present'
                $actualGuid   = '00000000-0000-0000-0000-000000000001'

                # Act
                $result = Test-TargetResource -Ensure $actualEnsure -Guid $actualGuid

                # Assert
                $result | Should Be $true
            }

            It 'should return $true for a desired absent disk' {

                # Arrange
                $actualEnsure = 'Absent'
                $actualGuid   = '00000000-0000-0000-0000-000000000003'

                # Act
                $result = Test-TargetResource -Ensure $actualEnsure -Guid $actualGuid

                # Assert
                $result | Should Be $true
            }

            It 'should return $false for a disk which is absent but should be present' {

                # Arrange
                $actualEnsure = 'Present'
                $actualGuid   = '00000000-0000-0000-0000-000000000003'

                # Act
                $result = Test-TargetResource -Ensure $actualEnsure -Guid $actualGuid

                # Assert
                $result | Should Be $false
            }

            It 'should return $false for a disk which is present but should be absent' {

                # Arrange
                $actualEnsure = 'Absent'
                $actualGuid   = '00000000-0000-0000-0000-000000000002'

                # Act
                $result = Test-TargetResource -Ensure $actualEnsure -Guid $actualGuid

                # Assert
                $result | Should Be $false
            }

            It 'should return $true for a matching label' {

                # Arrange
                $actualEnsure = 'Present'
                $actualGuid   = '00000000-0000-0000-0000-000000000002'
                $actualLabel  = 'Witness'

                # Act
                $result = Test-TargetResource -Ensure $actualEnsure -Guid $actualGuid -Label $actualLabel

                # Assert
                $result | Should Be $true
            }

            It 'should return $false for a incorrect label' {

                # Arrange
                $actualEnsure = 'Present'
                $actualGuid   = '00000000-0000-0000-0000-000000000002'
                $actualLabel  = 'Cluster Disk 2'

                # Act
                $result = Test-TargetResource -Ensure $actualEnsure -Guid $actualGuid -Label $actualLabel

                # Assert
                $result | Should Be $false
            }
        }
    }
}
