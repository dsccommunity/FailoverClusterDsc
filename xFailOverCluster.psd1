@{

moduleVersion = '1.11.0.0'

GUID = '026e7fd8-06dd-41bc-b373-59366ab18679'

Author = 'Microsoft Corporation'

CompanyName = 'Microsoft Corporation'

Copyright = '(c) 2018 Microsoft Corporation. All rights reserved.'

Description = 'Module containing DSC resources used to configure Failover Clusters.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xFailOverCluster/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xFailOverCluster'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- Changes to xFailOverCluster
  - Update appveyor.yml to use the default template.
  - Added default template files .codecov.yml, .gitattributes, and .gitignore,
    and .vscode folder.
  - Added FailoverClusters2012.stubs.psm1 from Windows Server 2012 and
    renamed existing test stub file to FailoverClusters2016.stubs.psm1.
  - Modified Pester Describe blocks to include which version of the
    FailoverClusters module is being tested.
  - Modified Pester tests to run against 2012 and 2016 stubs in sequence.
- Changes to xCluster
  - Fixed cluster creation on Windows Server 2012 by checking if the New-Cluster command
    supports -Force before using it ([issue 188](https://github.com/PowerShell/xFailOverCluster/issues/188)).
- Changes to xClusterQuorum
  - Changed some internal parameter names from the Windows Server 2016 version aliases
    which are compatible with Windows Server 2012.
- Changes to xClusterNetwork
  - Fixed Set-TargetResource for Windows Server 2012 by removing call to Update method
    as it doesn"t exist on this version and updates automatically.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}






