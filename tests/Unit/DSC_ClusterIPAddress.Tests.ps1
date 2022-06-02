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
                        OwnerGroup = 'Cluster Group'
                        ResourceType = 'IP Address'
                    }
                }

                Mock -CommandName Get-ClusterIPResourceParameters -MockWith {
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

                It "Should throw if the network of the IP address and subnet mask combination is not added to the cluster" {

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($LocalizedData.NonExistantClusterNetwork -f $mockTestParameters.IPAddress, $mockTestParameters.AddressMask) `
                        -ArgumentName 'IPAddress'

                    Mock -CommandName Test-ClusterNetwork -MockWith { $False }

                    {
                        Set-TargetResource @mockTestParameters
                    } | Should -Throw $errorRecord
                }

                It "Should not throw" {

                    Mock -CommandName Test-ClusterNetwork -MockWith { $True }
                    {
                        Set-TargetResource @mockTestParameters
                    } | Should -Not -Throw
                }
            }

            Context "IP address should be absent" {

                It "Should not throw when Absent" {

                    $mockTestParameters = @{
                        Ensure      = 'Absent'
                        IPAddress   = '192.168.1.41'
                        AddressMask = '255.255.255.0'
                    }

                    {
                        Set-TargetResource @mockTestParameters
                    }  | Should -Not -Throw
                }
            }
        }

        Describe "$script:DSCResourceName\Test-TargetResource" {
            Mock -CommandName Test-IPAddress

            Context "IP address should be Present" {

                $mockTestParameters = @{
                    Ensure      = 'Present'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                It "Should be false when IP address is not added but should be Present" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Present'
                            IPAddress   = $null
                            AddressMask = $null
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $false
                }

                It "Should be false when IP address is added but address mask does not match" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Present'
                            IPAddress   = '192.168.1.41'
                            AddressMask = '255.255.240.0'
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $false
                }

                It "Should be true when IP address is added and address masks match" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Present'
                            IPAddress   = '192.168.1.41'
                            AddressMask = '255.255.255.0'
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $true
                }
            }

            Context "IP address should be Absent" {

                $mockTestParameters = @{
                    Ensure      = 'Absent'
                    IPAddress   = '192.168.1.41'
                    AddressMask = '255.255.255.0'
                }

                It "Should be false when IP address is added but should be Absent" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Absent'
                            IPAddress   = '192.168.1.41'
                            AddressMask = '255.255.255.0'
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $false
                }

                It "Should be true when IP address is not and should be Absent" {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure      = 'Absent'
                            IPAddress   = $null
                            AddressMask = $null
                        }
                    }

                    Test-TargetResource @mockTestParameters | Should -Be $true
                }
            }
        }

        Describe "$script:DSCResourceName\Get-Subnet" {
            Mock -CommandName Test-IPAddress -MockWith {}

            $mockTestParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            It "Should return the correct subnet" {
                $result = Get-Subnet @mockTestParameters
                $result | Should -Be '192.168.1.0'
            }
        }

        Describe "$script:DSCResourceName\Add-ClusterIPAddressDependency" {
            $mockTestParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            Mock -CommandName Test-IPAddress
            Mock -CommandName Get-ClusterObject -MockWith {

                return @{
                    Name         = 'Cluster Name'
                    State        = 'Online'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'Network Name'
                }
            }

            Mock -CommandName Add-ClusterIPResource -MockWith { return 'IP Address 192.168.1.41' }

            Mock -CommandName Get-ClusterResource -MockWith {
                return @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Offline'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName Add-ClusterIPParameter

            Mock -CommandName Get-ClusterIPResource -MockWith {
                return @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Offline'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName New-ClusterIPDependencyExpression -MockWith {
                return '[IP Address 192.168.1.41]'
            }

            It "Should not throw" {
                Mock -CommandName Set-ClusterResourceDependency

                { Add-ClusterIPAddressDependency @mockTestParameters } | Should -Not -Throw
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterObject -Times 1
                Assert-MockCalled -CommandName Set-ClusterResourceDependency -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName Get-ClusterResource -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPParameter -Times 1
                Assert-MockCalled -CommandName Get-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName New-ClusterIPDependencyExpression -Times 1
            }

            It "Should throw the expected InvalidOperationException" {
                $errorRecord = "Exception thrown in Set-ClusterResourceDependency"

                Mock -CommandName Set-ClusterResourceDependency {
                    throw $errorRecord
                }

                { Add-ClusterIPAddressDependency @mockTestParameters } | Should -Throw $errorRecord
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterObject -Times 1
                Assert-MockCalled -CommandName Set-ClusterResourceDependency -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName Get-ClusterResource -Times 1
                Assert-MockCalled -CommandName Add-ClusterIPParameter -Times 1
                Assert-MockCalled -CommandName Get-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName New-ClusterIPDependencyExpression -Times 1
            }
        }

        Describe "$script:DSCResourceName\Remove-ClusterIPAddressDependency" {

            $mockTestParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            $mockCluster = @{
                Name         = 'Cluster Name'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'Network Name'
            }

            $mockIPResource = @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }

            Mock -CommandName Test-IPAddress

            Mock -CommandName Get-ClusterObject  -MockWith {
                return $mockCluster
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                return $mockIPResource
            }

            Mock -CommandName Remove-ClusterResource

            Mock -CommandName Get-ClusterIPResource -MockWith {
                return @{
                    Name         = 'IP Address 192.168.1.41'
                    State        = 'Offline'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName New-ClusterIPDependencyExpression -MockWith {
                return '[IP Address 192.168.1.41]'
            }

            It "Should not throw" {

                Mock -CommandName Set-ClusterResourceDependency

                { Remove-ClusterIPAddressDependency @mockTestParameters } | Should -Not -Throw
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterObject -Times 1
                Assert-MockCalled -CommandName Remove-ClusterResource -Times 1
                Assert-MockCalled -CommandName Get-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName New-ClusterIPDependencyExpression -Times 1
                Assert-MockCalled -CommandName Set-ClusterResourceDependency -Times 1

            }

            It "Should throw the expected InvalidOperationException" {
                $errorRecord = "Exception thrown in Set-ClusterResourceDependency"

                Mock -CommandName Set-ClusterResourceDependency { throw $errorRecord }

                { Remove-ClusterIPAddressDependency @mockTestParameters }| Should -Throw $errorRecord
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterObject -Times 1
                Assert-MockCalled -CommandName Remove-ClusterResource -Times 1
                Assert-MockCalled -CommandName Get-ClusterIPResource -Times 1
                Assert-MockCalled -CommandName New-ClusterIPDependencyExpression -Times 1
                Assert-MockCalled -CommandName Set-ClusterResourceDependency -Times 1
            }

        }

        Describe "$script:DSCResourceName\Test-ClusterIPAddressDependency" {
            $IPAddress = '192.168.1.41'

            Mock -CommandName Test-IPAddress

            It "Should return true when IP address is in dependency expression" {
                Mock -CommandName Get-ClusterResourceDependencyExpression -MockWith { return '[IP Address 192.168.1.41]' }
                Test-ClusterIPAddressDependency -IPAddress $IPAddress | Should -Be $true
                Assert-MockCalled -CommandName Test-IPAddress -Times 1
            }

            It "Should return false when IP address is not in dependency expression" {
                Mock -CommandName Get-ClusterResourceDependencyExpression -MockWith { return '[IP Address 192.168.1.60]' }
                Test-ClusterIPAddressDependency -IPAddress $IPAddress | Should -Be $false
                Assert-MockCalled -CommandName Test-IPAddress -Times 1
            }

            It "Should return true when IP address is in dependency expression" {
                Mock -CommandName Get-ClusterResourceDependencyExpression
                Test-ClusterIPAddressDependency -IPAddress $IPAddress | Should -Be $false
                Assert-MockCalled -CommandName Test-IPAddress -Times 1
            }
        }

        Describe "$script:DSCResourceName\Test-ClusterNetwork" {

            $mockTestParameters = @{
                IPAddress   = '192.168.1.41'
                AddressMask = '255.255.255.0'
            }

            $goodNetwork = '192.168.1.0'
            $badNetwork  = '10.10.0.0'

            Mock -CommandName Test-IPAddress
            Mock -CommandName Get-Subnet -MockWith { return $goodNetwork }

            It "Should return true when network is in cluster network list" {

                Mock -CommandName Get-ClusterNetworkList -MockWith {
                    return @{
                        Address     = $goodNetwork
                        AddressMask = $mockTestParameters.AddressMask
                    }
                }

                Test-ClusterNetwork @mockTestParameters | Should -Be $true
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterNetworkList -Times 1
                Assert-MockCalled -CommandName Get-Subnet -Times 1

            }

            It "Should return false when network is not in cluster network list" {
                Mock -CommandName Get-ClusterNetworkList -MockWith {
                    return @{
                        Address     = $badNetwork
                        AddressMask = $mockTestParameters.AddressMask
                    }
                }

                Test-ClusterNetwork @mockTestParameters | Should -Be $false
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterNetworkList -Times 1
                Assert-MockCalled -CommandName Get-Subnet -Times 1
            }
        }

        Describe "$script:DSCResourceName\Get-ClusterNetworkList" {

            $networks = New-Object -TypeName "System.Collections.Generic.List[PSCustomObject]"

            $oneNetwork = [PSCustomObject]@{
                Address     = '192.168.1.0'
                AddressMask = '255.255.255.0'
            }

            $twoNetwork = [PSCustomObject]@{
                Address     = '10.10.0.0'
                AddressMask = '255.255.0.0'
            }

            $networks.Add($oneNetwork)
            $networks.Add($twoNetwork)

            It "Should return the expected list when there is one cluster network" {
                Mock -CommandName Get-ClusterNetwork -MockWith {
                    $networks = New-Object -TypeName "System.Collections.Generic.List[PSCustomObject]"
                    $networks.Add($oneNetwork)
                    return $networks
                }

                $result = Get-ClusterNetworkList
                $result[0].Address     | Should -Be $networks[0].Address
                $result[0].AddressMask | Should -Be $networks[0].AddressMask

            }

            It "Should return the expected list when there are many cluster networks" {
                Mock -CommandName Get-ClusterNetwork -MockWith {
                    $networks = New-Object -TypeName "System.Collections.Generic.List[PSCustomObject]"
                    $networks.Add($oneNetwork)
                    $networks.Add($twoNetwork)
                    return $networks
                }

                $result = Get-ClusterNetworkList
                $result.Count          | Should -Be 2
                $result[0].Address     | Should -Be $networks[0].Address
                $result[0].AddressMask | Should -Be $networks[0].AddressMask
                $result[1].Address     | Should -Be $networks[1].Address
                $result[1].AddressMask | Should -Be $networks[1].AddressMask

            }

            It "Should return an empty list when there is one cluster network" {

                Mock -CommandName Get-ClusterNetwork -MockWith {
                    $networks = New-Object -TypeName "System.Collections.Generic.List[PSCustomObject]"
                    return $networks
                }

                (Get-ClusterNetworkList).Count | Should -BeExactly 0

            }

        }

        Describe "$script:DSCResourceName\Get-ClusterResourceDependencyExpression" {

            $dependencyExpression = '[IP Address 192.168.1.41]'

            It "Should return a cluster resource depedency string" {
                $mockData = @{
                    Name         = 'Cluster Name'
                    State        = 'Online'
                    OwnerGroup   = 'Cluster Group'
                    ResourceType = 'Network Name'
                }

                Mock -CommandName Get-ClusterResource -MockWith {
                    return $mockData
                }
                Mock -CommandName Get-ClusterResourceDependency -MockWith {
                    return @{
                        DependencyExpression = $dependencyExpression
                    }
                }

                Get-ClusterResourceDependencyExpression | Should -Be $dependencyExpression
            }

        }

        Describe "$script:DSCResourceName\Add-ClusterIPResource" {
            Mock -CommandName Test-IPAddress
            Mock -CommandName Add-ClusterResource

            $mockTestParameters = @{
                IPAddress  = '192.168.1.41'
                OwnerGroup = 'Cluster Group'
            }
            It "Should return the correct resource name" {
                Add-ClusterIPResource @mockTestParameters | Should -Be "IP Address $($mockTestParameters.IPAddress)"
            }

        }

        Describe "$script:DSCResourceName\Remove-ClusterIPResource" {
            Mock -CommandName Test-IPAddress


            $mockTestParameters = @{
                IPAddress  = '192.168.1.41'
                OwnerGroup = 'Cluster Group'
            }

            It "Should not throw" {
                Mock -CommandName Remove-ClusterResource
                { Remove-ClusterIPResource @mockTestParameters } | Should -Not -Throw
            }

            It "Should throw the expected exception" {
                $errorMessage = "Exception removing cluster resource"
                Mock -CommandName Remove-ClusterResource -MockWith {
                    throw $errorMessage
                }

                { Remove-ClusterIPResource @mockTestParameters } | Should -Throw $errorMessage
            }
        }

        Describe "$script:DSCResourceName\Get-ClusterIPResource" {
            $OwnerGroup = 'Cluster Group'

            $mockData = @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Offline'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                return $mockData
            }

            It "Should return the cluster's IP resources" {
                $return = Get-ClusterIPResource -OwnerGroup $OwnerGroup
                $return.Name         | Should -Be $mockData.Name
                $return.State        | Should -Be $mockData.State
                $return.OwnerGroup   | Should -Be $mockData.OwnerGroup
                $return.ResourceType | Should -Be $mockData.ResourceType
            }
        }

        Describe "$script:DSCResourceName\Add-ClusterIPParameter" {
            $mockTestParameters = @{
                IPAddressResourceName = 'IP Address 192.168.1.41'
                IPAddress             = '192.168.1.41'
                AddressMask           = '255.255.255.0'
            }

            class fake_cluster_parameter {
                [string] $IPAddressResourceName
                [string] $ResourceType
                [String] $Address
            }

            Mock -CommandName Test-IPAddress
            Mock -CommandName Get-ClusterResource -MockWith {
                return @{
                    Name = "IP Address $($mockTestParameters.Address)"
                    State = 'Online'
                    OwnerGroup = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName New-Object -MockWith {
                New-Object -TypeName 'fake_cluster_parameter'
                } `
                -ParameterFilter {
                    $TypeName -and
                    $TypeName -eq 'Microsoft.FailoverClusters.PowerShell.ClusterParameter'
                }

            It "Should not throw" {
                Mock -CommandName Set-ClusterParameter

                { Add-ClusterIPParameter @mockTestParameters } | Should -Not -Throw
            }

            It "Should should throw the expected exception" {
                $errorRecord = 'Exception setting cluster parameter'
                Mock -CommandName Set-ClusterParameter -MockWith {
                    throw $errorRecord
                }

                { Add-ClusterIPParameter @mockTestParameters } | Should -Throw $errorRecord
            }
        }

        #! This function is not used in the Resource
        Describe "$script:DSCResourceName\Remove-ClusterIPParameter" {

            $mockTestParameters = @{
                IPAddressResourceName = 'IP Address 192.168.1.41'
                IPAddress             = '192.168.1.41'
                AddressMask           = '255.255.255.0'
            }

            class fake_cluster_parameter {
                [string] $IPAddressResourceName
                [string] $ResourceType
                [String] $Address
            }

            Mock -CommandName Test-IPAddress
            Mock -CommandName Get-ClusterResource -MockWith {
                return @{
                    Name = "IP Address $($mockTestParameters.Address)"
                    State = 'Online'
                    OwnerGroup = 'Cluster Group'
                    ResourceType = 'IP Address'
                }
            }

            Mock -CommandName New-Object -MockWith {
                New-Object -TypeName 'fake_cluster_parameter'
                } `
                -ParameterFilter {
                    $TypeName -and
                    $TypeName -eq 'Microsoft.FailoverClusters.PowerShell.ClusterParameter'
                }

            It "Should not throw" {
                Mock -CommandName Set-ClusterParameter

                { Remove-ClusterIPParameter @mockTestParameters } | Should -Not -Throw
                Assert-MockCalled -CommandName Test-IPAddress -Times 2
                Assert-MockCalled -CommandName Get-ClusterResource -Times 1
                Assert-MockCalled -CommandName New-Object -Times 2
                Assert-MockCalled -CommandName Set-ClusterParameter -Times 1
            }

            It "Should throw the expected exception" {
                $errorRecord = 'Exception removing cluster parameter'
                Mock -CommandName Set-ClusterParameter -MockWith {
                    throw $errorRecord
                }

                { Remove-ClusterIPParameter @mockTestParameters } | Should -Throw $errorRecord

            }

        }

        Describe "$script:DSCResourceName\Test-IPAddress" {
            $goodIP = '192.168.1.41'
            $badIP  = '19.420.250.1'

            It "Should not throw" {
                {
                    Test-IPAddress -IPAddress $goodIP
                } | Should -Not -Throw
            }

            It "Should throw" {
                {
                    Test-IPAddress -IPAddress $badIP
                } | Should -Throw
            }

        }

        Describe "$script:DSCResourceName\New-ClusterIPDependencyExpression" {

            $oneClusterResource = 'IP Address 192.168.1.41'
            $twoClusterResource = @('IP Address 192.168.1.41', 'IP Address 172.19.114.98')
            $threeClusterResource = @('IP Address 192.168.1.41', 'IP Address 172.19.114.98', 'IP Address 10.10.45.41')

            It "Should return the correct dependency expression with one resource" {
                New-ClusterIPDependencyExpression -ClusterResource $oneClusterResource | Should -Be "[$oneClusterResource]"
            }

            It "Should return the correct dependency expression with two resources" {
                New-ClusterIPDependencyExpression -ClusterResource $twoClusterResource | Should -Be "[$($twoClusterResource[0])] or [$($twoClusterResource[1])]"
            }

            It "Should return the correct dependency expression with three resources" {
                New-ClusterIPDependencyExpression -ClusterResource $threeClusterResource  | Should -Be "[$($threeClusterResource[0])] or [$($threeClusterResource[1])] or [$($threeClusterResource[2])]"
            }

        }

        Describe "$script:DSCResourceName\Get-ClusterIPResource" {

            $ownerGroup = 'Cluster Group'
            $mockData = @{
                Name = 'IP Address 192.168.1.41'
                State = 'Online'
                OwnerGroup = 'Cluster Group'
                ResourceType = 'IP Address'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                return $mockData
            }

            It "Should return the expected hashtable" {
                $result = Get-ClusterIPResource -OwnerGroup $ownerGroup

                $result.Name | Should -Be $mockData.Name
                $result.State | Should -Be $mockData.State
                $result.OwnerGroup | Should -Be $mockData.OwnerGroup
                $result.ResourceType | Should -Be $mockData.ResourceType
            }

        }

        Describe "$script:DSCResourceName\Get-ClusterObject" {
            $mockData = @{
                Name         = 'Cluster Name'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'Network Name'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                return $mockData
            }

            It "Should return the expected data" {
                $result = Get-ClusterObject
                $result.Name         | Should -Be $mockData.Name
                $result.State        | Should -Be $mockData.State
                $result.OwnerGroup   | Should -Be $mockData.OwnerGroup
                $result.ResourceType | Should -Be $mockData.ResourceType

                Assert-MockCalled -CommandName Get-ClusterResource -Times 1
            }
        }

        Describe "$script:DSCResourceName\Get-ClusterIPResourceParameters" {

            $mockData = @{
                Name         = 'IP Address 192.168.1.41'
                State        = 'Online'
                OwnerGroup   = 'Cluster Group'
                ResourceType = 'IP Address'
            }

            $correctAnswer = @{
                Address     = '192.168.1.41'
                AddressMask = '255.255.255.0'
                Network     = '192.168.1.0'
            }

            Mock -CommandName Get-ClusterResource -MockWith {
                return $mockData
            }

            Mock -CommandName Get-ClusterParameter -MockWith {
                return $correctAnswer.Address
                } `
                -ParameterFilter {
                    $name -eq 'Address'
                }

            Mock -CommandName Get-ClusterParameter -MockWith {
                return $correctAnswer.AddressMask
                } `
                -ParameterFilter {
                    $name -eq 'SubnetMask'
                }

            Mock -CommandName Get-ClusterParameter -MockWith {
                return $correctAnswer.Network
                } `
                -ParameterFilter {
                    $name -eq 'Network'
                }

            It "Should return the correct hashtable" {
                $result = Get-ClusterIPResourceParameters -IPAddressResourceName $mockData.Name
                $result.Address     | Should -Be $correctAnswer.Address
                $result.AddressMask | Should -Be $correctAnswer.AddressMask
                $result.Network     | Should -Be $correctAnswer.Network
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}
