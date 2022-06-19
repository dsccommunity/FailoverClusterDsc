$script:dscModuleName = 'FailoverClusterDsc'
$script:subModuleName = 'FailoverClusterDsc.Common'

$script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

$script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

Describe 'FailoverClusterDsc.Common\Convert-DistinguishedNameToSimpleName' -Tag 'Convert-DistinguishedNameToSimpleName' {
    Context 'When passing a distinguished name' {
        It 'Should return the expected cluster name' {
            Convert-DistinguishedNameToSimpleName -DistinguishedName 'CN=CLUSTER1,OU=BUSINESS,DC=RANDOM,DC=LOCAL' |
                Should -Be 'CLUSTER1'
        }
    }

    Context 'When passing a cluster name' {
        It 'Should return the expected cluster name' {
            Convert-DistinguishedNameToSimpleName -DistinguishedName 'CLUSTER2' |
                Should -Be 'CLUSTER2'
        }
    }
}
