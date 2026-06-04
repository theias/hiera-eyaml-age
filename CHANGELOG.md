# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-05-27

### Fixed

- Fix option lookup: rename some option keys that still had `age_` prepended, to avoid double-prefixing by eyaml
- Override `option()` to correctly apply defined defaults when running on a Puppet server

## [0.2.1] - 2026-05-27

### Fixed

- Widen hiera-eyaml dependency range to `>= 4.2.0, < 6.0` to work with both Debian packaging and current gem releases

## [0.2.0] - 2026-05-26

### Added

- Manage packaging (gem, deb)
- Add options to take identity and/or recipients from environment variables instead of files

### Fixed

- Handle errors without dumping age's stderr unless asked for

## [0.1.0]

### Added

- init
