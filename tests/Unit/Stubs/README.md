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

$adTypeDefinition = @(
    @{
        ReplaceType = 'System\.Nullable`1\[Microsoft\.ActiveDirectory\.Management\.\w*\]'
        WithType    = 'System.Object'
    },
    @{
        ReplaceType = 'Microsoft\.ActiveDirectory\.Management\.Commands\.\w*'
        WithType    = 'System.Object'
    },
    @{
        ReplaceType = 'Microsoft\.ActiveDirectory\.Management\.\w*'
        WithType    = 'System.Object'
    }
)

New-StubModule -FromModule 'FailoverClusters' -Path $destinationFolder -FunctionBody $functionBody
    # -ReplaceTypeDefinition $adTypeDefinition

```

### ActiveDirectory Stub Customization

Some types that are referenced are not automatically created with
the cmdlet `New-StubModule`. Run the following, then the stub classes that
are outputted should be copied into the ActiveDirectory stub module that
was generated above, inside the namespace `Microsoft.ActiveDirectory.Management`.

```powershell
Import-Module ActiveDirectory
New-StubType -Type 'Microsoft.ActiveDirectory.Management.ADException' -ExcludeAddType
New-StubType -Type 'Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException' -ExcludeAddType
New-StubType -Type 'Microsoft.ActiveDirectory.Management.ADServerDownException' -ExcludeAddType
```

After the types are added, they need to make sure they inherit from `System.Exception`.
This must be done for each type created with `New-StubType`.

Example:

```csharp
public class ADIdentityNotFoundException : System.Exception
{
    ...
}
```

The stub class `Microsoft.ActiveDirectory.Management.ADDomainController`
cannot be generated fully since all properties that are returned from
`Get-ADDomainController` are not shown when using the type directly, e.g.
`$a = New-Object -TypeName 'Microsoft.ActiveDirectory.Management.ADDomainController'`.
To workaround this these properties below must be added manually to the stub
class `ADDomainController` in the namespace `Microsoft.ActiveDirectory.Management`.

```csharp
public class ADDomainController
{
    ...

    // Property
    ...
    public System.String ComputerObjectDN;
    public bool IsGlobalCatalog;
    public bool IsReadOnly;
    public Microsoft.ActiveDirectory.Management.ADOperationMasterRole[] OperationMasterRoles;
}
```

The parameter `DelegatedAdministratorAccountName` in ADDomainController resource
requires that the property `objectSid` is present when calling `Get-ADObject`,
which does not happen automatically.
To workaround this this property below must be added manually to the stub
class `ADObject` in the namespace `Microsoft.ActiveDirectory.Management`.

```csharp
public class ADObject
{
    ...

    // Property
    ...
    public System.Object objectSid;
}
```

The parameter `DelegatedAdministratorAccountName` in ADDomainController resource
requires that the property `ManagedBy` is present when calling `Get-ADComputer`,
which does not happen automatically.
To workaround this this property below must be added manually to the stub
class `ADComputer` in the namespace `Microsoft.ActiveDirectory.Management`.

```csharp
public class ADComputer
{
    ...

    // Property
    ...
    public System.String ManagedBy;
}
```

The helper function `Get-MembersToAddAndRemove` in ADDomainController resource
depends on the member (principal) property `SamAccountName` is returned
by the method `ToString()` and that is not automatically generated.
Update the stub class `ADPrincipal` constructor and add the method like this.

```csharp
    public class ADPrincipal
    {
        // Constructor
        ...
        public ADPrincipal(System.String identity) { SamAccountName = identity; }

        ...

        // Method
        public override string ToString()
        {
            return this.SamAccountName;
        }
    }
```

Replace all occurences of `System.Security.Principal.SecurityIdentifier` with
`System.Object` as `SecurityIdentifier` is not currently implemented in
PowerShell 7.

Add `-WarningAction SilentlyContinue` to the `Add-Type` command to suppress
warnings in PowerShell 7.
