[CmdletBinding()]
param
(
)

if (!$PSScriptRoot)
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
$ModuleName = 'MSFT_xCluster'

Add-WindowsFeature -Name RSAT-Clustering-PowerShell -ErrorAction SilentlyContinue
Import-Module (Join-Path -Path $RootPath -ChildPath "DSCResources\$ModuleName\$ModuleName.psm1") -Force

# General tests for the xCluster Resource
Describe 'xCluster' {

    InModuleScope $ModuleName {

        [Byte[]] $key = (1..16)
        $RootPath   = (Resolve-Path -Path "$PSScriptRoot\..").Path
        $TestPassword = Get-Content (Join-Path -path $RootPath -ChildPath "Tests\MSFT_xCluster.password.txt") | ConvertTo-SecureString -Key $key
        $TestCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'domain\administrator', $TestPassword

        $TestParameter = @{
            Name = 'CLUS001'
            StaticIPAddress = '192.168.10.10'
            DomainAdministratorCredential  = $TestCredential
        }

        Mock -CommandName 'Get-WmiObject' -ParameterFilter { $Class -eq 'Win32_ComputerSystem'} -MockWith {
            [PSCustomObject] @{
                Domain = 'domain.local'
                Name   = 'Server001'
            }
        }

        Mock -CommandName 'Get-Cluster' -ParameterFilter { $Name -eq $TestParameter.Name -and $Domain -eq 'domain.local'} -MockWith {
            [PSCustomObject] @{
                Domain = 'domain.local'
                Name   = $TestParameter.Name
            }
        }

        Mock -CommandName 'Get-ClusterGroup' -ParameterFilter {$Cluster -eq $TestParameter.Name} -MockWith {
            @{
                Name              = 'Cluster Group'
                OwnerNode         = 'Node1'
                State             = 'Online'
            }
        }

        Mock -CommandName 'Get-ClusterResource' -MockWith {
            @{
                Name              = 'Resource1'
                State             = 'Online'
                OwnerGroup        = 'ClusterGroup1'
                ResourceType      = 'type1'
            }
        }

        Mock -CommandName 'Get-ClusterParameter' -MockWith {
            @{
                Object = 'Cluster IP Address'
                Name = 'Address'
                Value = $TestParameter.StaticIPAddress
            }
        }

        Mock -CommandName 'Get-ClusterNode' {
            return $null  
        }

        Mock -CommandName 'New-Cluster' {
            return $null
        }

        Mock -CommandName 'Remove-ClusterNode' {
            return $null
        }

        Mock -CommandName 'Add-ClusterNode' {
            return $null
        }

        Context 'Validate Get-TargetResource method' {

            It 'Returns a [System.Collection.Hashtable] type' {

                $Result = Get-TargetResource @TestParameter

                $Result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Returns current configuration' {

                $Result = Get-TargetResource @TestParameter
                
                $Result.Name             | Should Be $TestParameter.Name     
                $Result.StaticIPAddress  | Should Be $TestParameter.StaticIPAddress 
    
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
