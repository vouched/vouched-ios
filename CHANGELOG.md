# Changelog

All notable changes to this project will be documented in this file.

## [0.4.1](https://github.com/vouched/vouched-ios/compare/v0.4.0...v0.4.1) - 2020-09-14

#### Added
- idAddress to JobResult

## [0.4.0](https://github.com/vouched/vouched-ios/compare/v0.3.0...v0.4.0) - 2020-09-05

#### Added
- Instruction .lookForward
- Enable federated groups in VouchedSession

## [0.3.0](https://github.com/vouched/vouched-ios/compare/v0.2.0...v0.3.0) - 2020-08-17

#### Added
- VouchedUtils
- RetryableError - notion of which errors to retry card/face detection

## [0.2.0](https://github.com/vouched/vouched-ios/compare/v0.1.0...v0.2.0) - 2020-08-14

#### Added
- Upgrade CardDetect to increase image quality

#### Breaking Changes
- CardDetect.isFar()
- CardDetect.isPostable()
- CardDetect.detect()


## [0.1.0](https://github.com/vouched/vouched-ios/compare/v0.0.3...v0.1.0) - 2020-08-10

#### Added
- VouchedLogger for easier debugging 

#### Removed
- Unused code
- Unnecessary print statements


## [0.0.3](https://github.com/vouched/vouched-ios/compare/v0.0.2...v0.0.3) - 2020-08-06

### <ins>SDK</ins>

#### Added
- Authentication for demo puposes
- Liveness check in face detection
- VouchedSession that encapsulatea Job token management and API calls

#### Changed
- FaceDetectResult to include the step and instruction

#### Removed
- isPostable() and isFar() from FaceDetect

### <ins>Example</ins>

#### Added
- Name Verification Screen
- Authentication Screen
- Nav header titles for each screen

#### Changed
- Xcode Config File for API Key instead of Environment Variables


## [0.0.2](https://github.com/vouched/vouched-ios/releases/tag/v0.0.2) - 2020-07-28

### Added
- Initial release
