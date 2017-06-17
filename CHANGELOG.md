# Change log for xFailOverCluster

## Unreleased

- Changes to xClusterPreferredOwner
  - Script Analyzer warnings have been fixed (issue #50). This also failed the
    tests for the resource.
- Changes to xClusterDisk
  - Fixed test that was failing in  AppVeyor (issue #55).
- Changes to xFailOverCluster
  - Added 'Code of Conduct' text to the README.md (issue #44).
  - Added TOC for all resources in the README.md (issue #43).
  - Fixed typos and lint errors in README.md.
  - Fixed style issue in example in README.md.
  - Removed 'Unreleased' "tag" from the resources xClusterQuorum and
    xClusterDisk (issue #36)
  - Added new sections to each resource (Requirements, Parameters and Examples)
    in the README.md. Some does not yet have any examples, so they are set to
    'None.'.
  - Added GitHub templates PULL\_REQUEST\_TEMPLATE, ISSUE_TEMPLATE and
    CONTRIBUTING.md (issue #45).
  - Split the change log from README.md to a separate file CHANGELOG.md
    (issue #48).
  - Added the resource xClusterPreferredOwner to README.md (issue #51).
  - Added the resource xClusterNetwork to README.md (issue #56).
  - Removed Credential parameter from parameter list for xWaitForCluster.
    Parameter Credential does not exist in the schema.mof of the resource
    (issue #62).
  - Now all parameters in the README.md list their data type and type qualifier
    (issue #58.)
  - Added Import-DscResource to example in README.md.
  - Added CodeCov and opt-in for all common tests (issue #41).
  - Added CodeCov badge to README.md
  - Fixed lint rule MD013 in CHANGELOG.md.
  - Fixed lint rule MD013 in README.md.
  - Fixed lint rule MD024 in README.md.
  - Fixed lint rule MD032 in README.md.
  - Removed example from README.md (issue #42).
  - Fixed typo in filename for ISSUE\_TEMPLATE. Was 'ISSUE\_TEMPLATE', now it is
    correctly 'ISSUE\_TEMPLATE.md'.
- Changes to xCluster
  - Added examples
    - 1-CreateFirstNodeOfAFailoverCluster.ps1
    - 2-JoinAdditionalNodeToFailoverCluster.ps1
    - 3-CreateFailoverClusterWithTwoNodes.ps1 (this is the example from README.md)
  - Fixed typo in xCluster parameter description.
  - Added links to examples from README.md
- Changes to xWaitForCluster
  - Added example
    - 1-WaitForFailoverClusterToBePresent.ps1
  - Added link to example from README.md

### 1.6.0.0

- xCluster: Fixed bug in which failure to create a new cluster would hang

### 1.5.0.0

- Added xClusterQuorum resource with options *NodeMajority*,
  *NodeAndDiskMajority*, *NodeAndFileShareMajority*, *DiskOnly*
- Currently does not implement cloud witness for Windows 2016.
- Added xClusterDisk resource

### 1.2.0.0

- xCluster: Added -NoStorage switch to Add-ClusterNode. This prevents disks from
  being automatically added when joining a node to a cluster

### 1.1.0.0

- Removed requirement for CredSSP

### 1.0.0.0

- Initial release with the following resources:
  - xCluster and xWaitForCluster
