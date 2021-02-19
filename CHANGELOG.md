# Change log for xFailOverCluster

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

### Added

- xFailOverCluster
  - Add the module MarkdownLinkCheck to dependent modules to active the
    markdown link tests.
  - Added the filetypes to the file `.gitattributes` according to the
    Plaster template.
  - Update examples to be ready to be published to the PowerShell Gallery.
  - Added a CONTRIBUTING.md.
  - Replaced module CommonResourceHelper with the PowerShell Gallery module
    DscResource.Common v0.2.0.
  - Adding back publishing code coverage to Codecov.io.
    - Add status badge for Codecov.io in README.md.
    - Fix Azure Pipelines code coverage ([issue #236](https://github.com/dsccommunity/xFailOverCluster/issues/236)).

### Changed

- xFailOverCluster
  - Renamed `master` branch to `main` ([issue #246](https://github.com/dsccommunity/xFailOverCluster/issues/246)).
  - Updated the CI pipeline files to the latest template.
  - Changed unit tests to handle missing DscResource.Test better.
  - Changed the Code of Conduct to the one adopted by DSC Community.
  - Added `.markdownlint.json` to get the correct settings for the
    MarkdownLint VS Code extension.
  - Changed Visual Studio Code settings to the file `settings.json` according
    to the Plaster template.
  - Set `testRunTitle` for PublishTestResults task so that a helpful name is
    displayed in Azure DevOps for each test run.
  - Set a display name on all the jobs and tasks in the CI pipeline.
  - The deploy step is now only run when merged to branch `master` in the
    DSC Community upstream repository (not to branch `master` in a fork
    which always failed due to missing credentials).
  - Only run the CI pipeline on branch `master` when there are changes to
    files inside the `source` folder.
  - Changed integration tests to run on a a build image with Windows Server
    2019 since the one we previously used was removed from Azure Pipelines ([issue #233](https://github.com/dsccommunity/xFailOverCluster/issues/233)).
  - Updated CI pipeline to get version from the property `NuGetVersionV2`.
  - Pin Pester to 4.10.1 in `RequiredModule.psd1` since the tests does
    not support Pester 5.
  - Updated repository to use the latest version of the module ModuleBuilder.

### Fixed

- xFailOverCluster
  - The component `gitversion` that is used in the pipeline was wrongly configured
    when the repository moved to the new default branch `main`. It no longer throws
    an error when using newer versions of GitVersion.
  - Added CODE_OF_CONDUCT.md file, and a 'Code of Conduct' section in the
    README.md.
  - Improved CI pipeline
    - Renamed the jobs
    - Splitting up the testing in different jobs.
  - URLs in the module manifest pointed in the wrong direction.
  - Changed the encoding that will be used by ModuleBuilder (`UTF-8`).
  - URLs to examples in README.md didn't take account for new folder
    structure.
  - Release pipeline stopped working in some circumstances, workaround is
    to pin ModuleBuilder to version `1.0.0` for now.
    *There is an issue with ModuleBuilder with preview strings using dash,*
    *e.g. `fix0008-9`. The string is compliant with SemVer 2.0 but there*
    *is a bug in `Publish-Module` that prevents the module to be released.*
  - Added code coverage reporting to Azure DevOps.
  - Update status badges in README.md.
  - Replaced section 'Branches' with section 'Releases' in README.md.
  - Pull request and issue template got minor updates.
  - Update module manifest exporting resources and fixed style.
  - Update GitVersion.yml with the correct regular expression.
  - Fix import statement in all tests, making sure it throws if module
    DscResource.Test cannot be imported.
  - Update the deploy stage so that it is skipped when merging
    branch master in forks.
- xClusterPreferredOwner
  - Fixed broken links to examples in README.md.
- xClusterQuorum
  - Fixed broken link to examples in README.md ([issue #208](https://github.com/dsccommunity/xFailOverCluster/issues/208)).
- CommonResourceHelper
  - Added `en-US` localization folder to pass PSSA rule.
- xCluster
  - Added script file information to the example `1-CreateFirstNodeOfAFailoverCluster.ps1`.
  - Fixed Describe-block descriptions ([issue #234](https://github.com/dsccommunity/xFailOverCluster/issues/234)).
  - Made DomainAdministratorCredential optional ([issue #164](https://github.com/dsccommunity/xFailOverCluster/issues/164))

### Removed

- Removed the file `Deploy.PSDeploy.ps1` since it is not longer used by
  the build pipeline.

## [1.14.1] - 2019-12-18

### Changed

- xFailOverCluster
  - Changed the pipeline to publish test results for both success and failure.

### Fixed

- CommonResourceHelper
  - Fix unit tests to load the helper modules using module manifest.
  - Fix to correctly export the functions in the helper module
    ([issue #214](https://github.com/dsccommunity/xFailOverCluster/issues/214)).
  - Fix typo in module manifest.

## [1.14.0] - 2019-12-17

### Added

- xFailOverCluster
  - Added automatic release with a new CI pipeline.

### Changed

- xFailOverCluster
  - Moved the helper module `CommonResourceHelper` to the `Modules` folder.
- CommonResourceHelper
  - Update `Get-LocalizedData` to handle new location of helper module.
