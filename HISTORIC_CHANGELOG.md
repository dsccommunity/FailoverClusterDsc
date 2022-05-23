# Historic change log for FailOverClusterDsc

The release notes in the PowerShell Module manifest cannot exceed 10000
characters. Due to a bug in the CI deploy pipeline this is not handled.
This file is to temporary move the older change log history to keep the
change log short.

## [1.13.0.0] - 2019-09-19

### Changed

- Updated the xCluster *test* method to return true if a node is joined to the cluster but is in a **Paused** state.

## [1.12.0.0] - 2019-01-10

### Changed

- Explicitly removed extra hidden files from release package

## [1.11.0.0] - 2018-10-25

### Changed

- Changes to xFailOverCluster
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
    supports -Force before using it ([issue #188](https://github.com/PowerShell/xFailOverCluster/issues/188)).
- Changes to xClusterQuorum
  - Changed some internal parameter names from the Windows Server 2016 version aliases
    which are compatible with Windows Server 2012.
- Changes to xClusterNetwork
  - Fixed Set-TargetResource for Windows Server 2012 by removing call to Update method
    as it doesn't exist on this version and updates automatically.

## [1.10.0.0] - 2018-03-22

### Changed

- Changes to xFailOverCluster
  - Added xClusterProperty ([issue #169](https://github.com/PowerShell/xFailOverCluster/issues/169)).
- Changes to xClusterNetwork
  - Fix the test for the network role never in desired state ([issue #175](https://github.com/PowerShell/xFailOverCluster/issues/175)).

## [1.9.0.0] - 2018-02-08

### Changed

- Changes to xFailOverCluster
  - Update Pester syntax to v4
  - Updated year to 2018 in license file and module manifest ([issue #167](https://github.com/PowerShell/xFailOverCluster/issues/167)).
- Changes to xClusterNetwork
  - Updated readme to describe process for adding and removing additional networks on clusters
- Changes to xCluster
  - Allow the cluster to be assigned an IP address from a DHCP ([issue #109](https://github.com/PowerShell/xFailOverCluster/issues/109)).
    When the parameter StaticIPAddress is not specified then the cluster will be
    configured to use an IP address from a DHCP.
  - Get-TargetResource now correctly returns the IP address instead of throwing
    and error ([issue #28](https://github.com/PowerShell/xFailOverCluster/issues/28)).
  - Added -IgnoreNetwork parameter ([issue #143](https://github.com/PowerShell/xFailOverCluster/issues/143)).
- Changes to xClusterQuorum
  - When using NodeAndFileShareMajority on Windows Server 2016 any subsequent run
    failed when Test-TargetResource validated the configuration.
  - Cleaned up tests which was using over complicated evaluation code.
  - Added cloud witness (Azure storage) functionality on Windows 2016
    ([issue #37](https://github.com/PowerShell/xFailOverCluster/issues/37)).

## [1.8.0.0] - 2017-08-23

### Changed

- Changes to xFailOverCluster
  - Added a common resource helper module with helper functions for localization.
    - Added helper functions; Get-LocalizedData, New-InvalidResultException,
      New-ObjectNotFoundException, New-InvalidOperationException and
      New-InvalidArgumentException.
  - Fixed lint error MD034 and fixed typos in README.md.
  - Opt-in for module files common tests ([issue #119](https://github.com/PowerShell/xFailOverCluster/issues/119)).
    - Removed Byte Order Mark (BOM) from the files; CommonResourceHelper.psm1 and FailoverClusters.stubs.psm1.
  - Opt-in for script files common tests ([issue #121](https://github.com/PowerShell/xFailOverCluster/issues/121)).
    - Removed Byte Order Mark (BOM) from the files; CommonResourceHelper.Tests.ps1,
      MSFT\_xCluster.Tests.ps1, MSFT\_xClusterDisk.Tests.ps1,
      MSFT\_xClusterPreferredOwner.Tests.ps1, MSFT_xWaitForCluster.Tests.ps1.
  - Added common test helper functions to help test the throwing of localized error strings.
    - Get-InvalidArgumentRecord
    - Get-InvalidOperationRecord
    - Get-ObjectNotFoundException
    - Get-InvalidResultException.
  - Updated year to 2017 in license file and module manifest ([issue #131](https://github.com/PowerShell/xFailOverCluster/issues/131)).
- Changes to xClusterDisk
  - Enabled localization for all strings ([issue #84](https://github.com/PowerShell/xFailOverCluster/issues/84)).
  - Fixed the OutputType data type that was not fully qualified.
  - Minor style changes.
  - Fixed Script Analyzer warnings for Write-Verbose.
- Changes to xClusterNetwork
  - Replaced the URL for the parameter Role in README.md. The new URL is a more
    generic description of the possible settings for the Role parameter. The
    previous URL was still correct but focused on Hyper-V in particular.
  - Fixed typos in parameter descriptions in README.md, comment-based help and schema.mof.
  - Enabled localization for all strings ([issue #85](https://github.com/PowerShell/xFailOverCluster/issues/85)).
  - Minor style changes.
  - Fixed Script Analyzer warnings for Write-Verbose.
- Changes to xCluster
  - Resolved Script Analyzer rule warnings by changing Get-WmiObject to
    Get-CimInstance ([issue #49](https://github.com/PowerShell/xFailOverCluster/issues/49)).
  - Minor style change in tests. Removed '-' in front of '-Be', '-Not', '-Throw',
    etc.
  - Enabled localization for all strings ([issue #83](https://github.com/PowerShell/xFailOverCluster/issues/83)).
  - Added tests to improve code coverage.
    - Fixed random problem with tests failing with error "Invalid token for
      impersonation - it cannot be duplicated." ([issue #133](https://github.com/PowerShell/xFailOverCluster/issues/133)).
  - Minor style changes.
  - Fixed Script Analyzer warnings for Write-Verbose.
- Changes to xWaitForCluster
  - Refactored the unit test for this resource to use stubs and increase coverage
    ([issue #78](https://github.com/PowerShell/xFailOverCluster/issues/78)).
  - Now the Test-TargetResource correctly returns false if the domain name cannot
    be evaluated  ([issue #107](https://github.com/PowerShell/xFailOverCluster/issues/107)).
  - Changed the code to be more aligned with the style guideline.
  - Updated parameter description in the schema.mof.
  - Resolved Script Analyzer warnings ([issue #54](https://github.com/PowerShell/xFailOverCluster/issues/54)).
  - Enabled localization for all strings ([issue #88](https://github.com/PowerShell/xFailOverCluster/issues/88)).
  - Minor style changes.
- Changes to xClusterQuorum
  - Refactored the unit test for this resource to use stubs and increase coverage
    ([issue #77](https://github.com/PowerShell/xFailOverCluster/issues/77)).
  - Changed the code to be more aligned with the style guideline.
  - Updated parameter description in the schema.mof.
  - Added example ([issue #47](https://github.com/PowerShell/xFailOverCluster/issues/47))
    - 1-SetQuorumToNodeMajority.ps1
    - 2-SetQuorumToNodeAndDiskMajority.ps1
    - 3-SetQuorumToNodeAndFileShareMajority.ps1
    - 4-SetQuorumToDiskOnly.ps1
  - Added links to examples from README.md.
  - Minor style changes.
  - Enabled localization for all strings ([issue #87](https://github.com/PowerShell/xFailOverCluster/issues/87)).
- Changes to xClusterPreferredOwner
  - Enabled localization for all strings ([issue #86](https://github.com/PowerShell/xFailOverCluster/issues/86)).
  - Fixed typo in the returned hash table from Get-TargetResource.
  - Minor style changes.

## [1.7.0.0] - 2017-07-12

### Changed

- Changes to xClusterPreferredOwner
  - Script Analyzer warnings have been fixed ([issue #50](https://github.com/PowerShell/xFailOverCluster/issues/50)). This also failed the
    tests for the resource.
- Changes to xClusterDisk
  - Fixed test that was failing in  AppVeyor ([issue #55](https://github.com/PowerShell/xFailOverCluster/issues/55)).
- Changes to xFailOverCluster
  - Added 'Code of Conduct' text to the README.md ([issue #44](https://github.com/PowerShell/xFailOverCluster/issues/44)).
  - Added TOC for all resources in the README.md ([issue #43](https://github.com/PowerShell/xFailOverCluster/issues/43)).
  - Fixed typos and lint errors in README.md.
  - Fixed style issue in example in README.md.
  - Removed 'Unreleased' "tag" from the resources xClusterQuorum and
    xClusterDisk ([issue #36](https://github.com/PowerShell/xFailOverCluster/issues/36))
  - Added new sections to each resource (Requirements, Parameters and Examples)
    in the README.md. Some does not yet have any examples, so they are set to
    'None.'.
  - Added GitHub templates PULL\_REQUEST\_TEMPLATE, ISSUE_TEMPLATE and
    CONTRIBUTING.md ([issue #45](https://github.com/PowerShell/xFailOverCluster/issues/45)).
  - Split the change log from README.md to a separate file CHANGELOG.md
    [issue #48](https://github.com/PowerShell/xFailOverCluster/issues/48).
  - Added the resource xClusterPreferredOwner to README.md ([issue #51](https://github.com/PowerShell/xFailOverCluster/issues/51)).
  - Added the resource xClusterNetwork to README.md ([issue #56](https://github.com/PowerShell/xFailOverCluster/issues/56)).
  - Removed Credential parameter from parameter list for xWaitForCluster.
    Parameter Credential does not exist in the schema.mof of the resource
    ([issue #62](https://github.com/PowerShell/xFailOverCluster/issues/62)).
  - Now all parameters in the README.md list their data type and type qualifier
    ([issue #58](https://github.com/PowerShell/xFailOverCluster/issues/58)).
  - Added Import-DscResource to example in README.md.
  - Added CodeCov and opt-in for all common tests ([issue #41](https://github.com/PowerShell/xFailOverCluster/issues/41)).
  - Added CodeCov badge to README.md
    - Fixed CodeCov badge links so they now can be clicked on.
  - Fixed lint rule MD013 in CHANGELOG.md.
  - Fixed lint rule MD013 in README.md.
  - Fixed lint rule MD024 in README.md.
  - Fixed lint rule MD032 in README.md.
  - Removed example from README.md ([issue #42](https://github.com/PowerShell/xFailOverCluster/issues/42)).
  - Fixed typo in filename for ISSUE\_TEMPLATE. Was 'ISSUE\_TEMPLATE', now it is
    correctly 'ISSUE\_TEMPLATE.md'.
  - Changed appveyor.yml to use the new default test framework in the AppVeyor
    module in DscResource.Tests (AppVeyor.psm1).
  - Added VS Code workspace settings file with formatting settings matching the
    Style Guideline ([issue #67](https://github.com/PowerShell/xFailOverCluster/issues/67)). That will make it possible inside VS Code to
    press SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
    PowerShell code will then be formatted according to the Style Guideline
    (although maybe not complete, but would help a long way).
  - Added new stubs for FailoverClusters module
    (Tests\Unit\Stubs\FailoverClusters.stubs.psm1) to be able to run unit tests
    on a computer that does not have or can install Failover Clustering
    PowerShell module.
  - Added a script file (Tests\Unit\Stubs\Write-ModuleStubFile.ps1) to be able
    to rebuild the stub file (FailoverClusters.stubs.psm1) whenever needed.
  - Added code block around types in README.md.
- Changes to xCluster
  - Added examples
    - 1-CreateFirstNodeOfAFailoverCluster.ps1
    - 2-JoinAdditionalNodeToFailoverCluster.ps1
    - 3-CreateFailoverClusterWithTwoNodes.ps1 (this is the example from README.md)
  - Fixed typo in xCluster parameter description.
  - Added links to examples from README.md
  - Refactored the unit test for this resource to use stubs and increase coverage
    ([issue #73](https://github.com/PowerShell/xFailOverCluster/issues/73)).
    - Removed the password file (MSFT_xCluster.password.txt) which seemed unnecessary.
  - Test-TargetResource now throws and error if domain name cannot be evaluated
    ([issue #72](https://github.com/PowerShell/xFailOverCluster/issues/72)).
  - Set-TargetResource now correctly throws and error if domain name cannot be
    evaluated ([issue #71](https://github.com/PowerShell/xFailOverCluster/issues/71)).
- Changes to xWaitForCluster
  - Added example
    - 1-WaitForFailoverClusterToBePresent.ps1
  - Added link to example from README.md
- Changes to xClusterDisk
  - Refactored the unit test for this resource to use stubs and increase coverage
    ([issue #74](https://github.com/PowerShell/xFailOverCluster/issues/74)).
  - Removed an evaluation that called Test-TargetResource in Set-TargetResource
    method and instead added logic so that Set-TargetResource evaluates if it
    should remove a disk ([issue #90](https://github.com/PowerShell/xFailOverCluster/issues/90)).
  - Changed the code to be more aligned with the style guideline.
  - Added examples ([issue #46](https://github.com/PowerShell/xFailOverCluster/issues/46))
    - 1-AddClusterDisk.ps1
    - 2-RemoveClusterDisk.ps1
  - Added links to examples from README.md.
- Changes to xClusterPreferredOwner
  - Refactored the unit test for this resource to use stubs and increase coverage
    ([issue #76](https://github.com/PowerShell/xFailOverCluster/issues/76)).
  - Changed the code to be more aligned with the style guideline.
  - Added examples ([issue #52](https://github.com/PowerShell/xFailOverCluster/issues/52))
    - 1-AddPreferredOwner.ps1
    - 2-RemovePreferredOwner.ps1
  - Added links to examples from README.md.
- Changes to xClusterNetwork
  - Refactored the unit test for this resource to use stubs and increase coverage
    ([issue #75](https://github.com/PowerShell/xFailOverCluster/issues/75)).
  - Changed the code to be more aligned with the style guideline.
  - Updated resource and parameter description in README.md and schema.mof.
  - Added example ([issue #57](https://github.com/PowerShell/xFailOverCluster/issues/57))
    - 1-ChangeClusterNetwork.ps1
  - Added links to examples from README.md.

### [1.6.0.0] - 2016-12-14

### Changed

- xCluster: Fixed bug in which failure to create a new cluster would hang

### [1.5.0.0] - 2016-08-10

### Changed

- Added xClusterQuorum resource with options *NodeMajority*,
  *NodeAndDiskMajority*, *NodeAndFileShareMajority*, *DiskOnly*
- Currently does not implement cloud witness for Windows 2016.
- Added xClusterDisk resource

### [1.2.0.0] - 2016-03-31

### Changed

- xCluster: Added -NoStorage switch to Add-ClusterNode. This prevents disks from
  being automatically added when joining a node to a cluster

### [1.1.0.0] - 2014-05-13

### Changed

- Removed requirement for CredSSP

### [1.0.0.0] - 2014-04-08

### Changed

- Initial release with the following resources:
  - xCluster and xWaitForCluster
