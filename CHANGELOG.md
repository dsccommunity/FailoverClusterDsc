# Change log for xFailOverCluster

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

### Changed

- xFailOverCluster
  - Changed unit tests to handle missing DscResource.Test better.
  - Changed the Code of Conduct to the one adopted by DSC Community.
  - Added `.markdownlint.json` to get the correct settings for the
    MarkdownLint VS Code extension.

### Fixed

- xFailOverCluster
  - Added CODE_OF_CONDUCT.md file, and a 'Code of Conduct' section in the
    README.md.
  - Improved CI pipeline
    - Renamed the jobs
    - Splitting up the testing in different jobs.
  - URLs in the module manifest pointed in the wrong direction.
  - Changed the encoding that will be used by ModuleBuilder (`ÙTF-8`).
  - URLs to examples in README.md didn't take account for new folder
    structure.
  - Release pipeline stopped working in some circumstances, workaround is
    to pin ModuleBuilder to version `1.0.0` for now.
    *There are a issue with ModuleBuilder using preview strings using dash,*
    *e.g. `fix0008-9`. The string is compliant with SemVer 2.0 but there*
    *is a bug in `Publish-Module` that prevents the module to be released.*
  - Added code coverage reporting to Azure DevOps.
  - Update status badges in README.md.
  - Replaced section 'Branches' with section 'Releases' in README.md.
  - Pull request and issue template got minor updates.
- xClusterPreferredOwner
  - Fixed broken links to examples in README.md.
- xClusterQuorum
  - Fixed broken link to examples in README.md ([issue #208](https://github.com/dsccommunity/xFailOverCluster/issues/208).
- CommonResourceHelper
  - Added `en-US` localization folder to pass PSSA rule.
- xCluster
  - Added script file information to the example `1-CreateFirstNodeOfAFailoverCluster.ps1`.

### Removed

- Removed the file `.codecov.yml` since Codecov is no longer used.
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
