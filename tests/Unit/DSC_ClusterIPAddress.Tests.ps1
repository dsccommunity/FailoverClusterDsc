$script:DSCModuleName = 'FailoverClusterDsc'
$script:DSCResourceName = 'DSC_ClusterIPAddress'

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
