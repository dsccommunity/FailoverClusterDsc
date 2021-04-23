$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This method is used to converted Distinguished Name to a Simple Name.

    .PARAMETER CurrentValues
        Distinguished Name to be converted to a Simple Name
#>

function Convert-DistinguishedNameToSimpleName {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'returnValue')]
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $DistinguishedName
    )

    $returnValue = $DistinguishedName

    if ($DistinguishedName -match '^(\s*CN\s*=\w*)((\s*,\s*OU\s*=\w*)*)((\s*,\s*DC\s*=\w*)*)$') {
        $returnValue = ((($DistinguishedName -split ',')[0]) -split '=')[1]
    }

    return $returnValue
}