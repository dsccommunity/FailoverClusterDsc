# Stubs

A stub function is function with just the skeleton of the original function
or cmdlet. Pester can use a stub function to have something to hook into
when a mock of a cmdlet or function is needed in a unit test. Stub functions
make it possible to run unit tests without having the actual module with
the cmdlet or function installed.

## How to

>**NOTE!** The stubs have been altered after that the modules have been
>generated. How they were altered is described in the below procedure.

Install the module 'Indented.StubCommand' from PowerShell Gallery.

```powershell
Install-Module Indented.StubCommand -Scope CurrentUser
```

Install the necessary features to get the modules to create stubs from.

```powershell
Add-WindowsFeature RSAT-Clustering-PowerShell
```

Create the stub modules in the module's `tests/Unit/Stubs` folder:

```powershell
$destinationFolder = 'tests/Unit/Stubs'

$functionBody = {
    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

New-StubModule -FromModule 'FailoverClusters' -Path $destinationFolder -FunctionBody $functionBody
```

Add `-WarningAction SilentlyContinue` to the `Add-Type` command to suppress
warnings in PowerShell 7.
