<#
    .SYNOPSIS
        Generates a file containing function stubs of all cmdlets from the module
        given as a parameter.

    .PARAMETER ModuleName
        The name of the module to load and generate stubs from. This module must
        exist on the computer where this function is ran.

    .PARAMETER Path
         Path to where to write the stubs file. The filename will be generated
         from the module name.

    .PARAMETER Description
         Optional. Additional text to further describe the stubs and will be
         added to the comment-based help, in the generated file, under the
         Description keyword.
         If this is set to an array of strings, each string will be added on a
         separate row.

    .PARAMETER ReplaceType
         Optional. An array of strings containing names of types to replace with
         the type [Object]. Allow use of wildcard character '*'.

    .EXAMPLE
        $writeModuleStubFileParameters = @{
            ModuleName = 'FailoverClusters'
            Path = 'C:\Source'
            Description = '@('Text row 1','Text row 2')
            ReplaceType = 'Microsoft.FailoverClusters.*'
        }

        Write-ModuleStubFile @writeModuleStubFileParameters
#>
function Write-ModuleStubFile
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String[]]
        $Description,

        [Parameter()]
        [System.String[]]
        $ReplaceType
    )

    $module = Get-Module $ModuleName -ListAvailable
    Import-Module $module -DisableNameChecking -Force

    $cmdletToStub = Get-Command -Module $module -CommandType 'Cmdlet'

    $cmdletToStub | ForEach-Object -Begin {
            $operatingSystemInformation = Get-CimInstance -class Win32_OperatingSystem

            "<#"
            "    .SYNOPSIS"
            "        This is stub cmdlets for the module $($module.Name) which can be used in"
            "        Pester unit tests to be able to test code without having the actual module installed."
            if ($Description)
            {
                ""
                "    .DESCRIPTION"
                "        $($Description -join "`r`n        ")"
            }
            ""
            "    .NOTES"
            "        Generated from module $($module.Name) (version $($module.Version.ToString())), on"
            "        operating system $($operatingSystemInformation.Caption) $($operatingSystemInformation.OSArchitecture) ($($operatingSystemInformation.Version))"
            "#>"
            ""
            "<#"
            "    Suppressing this rule because these functions are from an external module"
            "    and are only being used as stubs."
            "#>"
            "[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]"
            "param()"
            ""
        } -Process {
            $signature = $null
            $command = $_
            $endOfDefinition = $false
            $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $command
            $definition = [System.Management.Automation.ProxyCommand]::Create($metadata)
            foreach ($line in $definition -split "`n")
            {
                # Replaces any type the in the $ReplaceType variable with the Object type.
                $ReplaceType | ForEach-Object -Process {
                    $line = $line -replace "\[$_\]", '[Object]'
                }

                $line = $line -replace 'SupportsShouldProcess=\$true, ', ''

                if ( $line.Contains( '})' ) )
                {
                    $line = $line.Remove( $line.Length - 2 )
                    $endOfDefinition = $true
                }

                if ( $line.Trim() -ne '' )
                {
                    $signature += "    $line"
                }
                else
                {
                    $signature += $line
                }

                if ( $endOfDefinition )
                {
                    $signature += "`n   )"
                    break
                }
            }

            "function $($command.Name) {"
            "$signature"
            ""
            "   throw '{0}: StubNotImplemented' -f $`MyInvocation.MyCommand"
            "}"
            ""
        } | Out-String | Out-File (Join-Path -Path $Path -ChildPath "$($ModuleName).stubs.psm1") -Encoding utf8 -Append
}
