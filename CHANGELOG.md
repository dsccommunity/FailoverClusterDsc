# Change log for xFailOverCluster

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

## Changed

- xFailOverCluster
  - Changed unit tests to handle missing DscResource.Test better.

# Fixed

- xFailOverCluster
  - Fix URLs in the module manifest.
  - Fix the encoding that will be used by ModuleBuilder.
  - Fix paths to examples in the README.md.

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
