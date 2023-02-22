# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2023-02-22
### Added
- Added `serializer_params` method to more easily allow for custom serializer params.

## [0.2.2] - 2020-05-18
### Fixed
- JsonapiActions#json_response uses `defined?` to check for serializer library
