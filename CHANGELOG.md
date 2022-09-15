# Changelog

All notable changes to this project will be documented in this file.

## [1.4.5](https://github.com/vouched/vouched-ios/compare/v1.4.5...v1.4.4) - 2022-09-15

#### Removed
- Support for bitcode, which is deprecated in Xcode 14

## [1.4.4](https://github.com/vouched/vouched-ios/compare/v1.4.4...v1.4.2) - 2022-08-24

#### Added
- Support for serializing BarcodeResults for use in the Vouched Reactive Native SDK

## [1.4.2](https://github.com/vouched/vouched-ios/compare/v1.4.2...v1.4.0) - 2022-08-15

#### Added
- Support for reverifying selfies against either the ID or selfie from a previously verified job

## [1.4.0](https://github.com/vouched/vouched-ios/compare/v1.4.0...v1.3.0) - 2022-07-22

#### Added
- Support for reverifying selfies against a previously verified job

## [1.3.0](https://github.com/vouched/vouched-ios/compare/v1.3.0...v1.2.2) - 2022-03-29

#### Added
- Support for user confirmation of IDs
- Simplified example workflow

## [1.2.2](https://github.com/vouched/vouched-ios/compare/v1.2.2...v1.1.6) - 2022-03-29

#### Added
- Detection assets are now bundled with the SDK, no need to download them anymore

## [1.1.6](https://github.com/vouched/vouched-ios/compare/v1.1.4...v1.1.6) - 2022-03-29

#### Added
- Fixes for iOS face detection in the React Native SDK

## [1.1.4](https://github.com/vouched/vouched-ios/compare/v1.1.2...v1.1.4) - 2022-03-29

#### Added
- Support for the Vouched React Native SDK

## [1.1.2](https://github.com/vouched/vouched-ios/compare/v1.1.0...v1.1.2) - 2022-03-07

## [1.1.0](https://github.com/vouched/vouched-ios/compare/v1.0.0...v1.1.0) - 2022-02-09

#### Added
- Enchanced data extraction option now includes the ability to capture infromation from the backside of IDs

## [1.0.0](https://github.com/vouched/vouched-ios/compare/v0.9.0...v1.0.0) - 2022-02-09

#### Added
- Enchanced data extraction option for ID detection
- Control of device flash
- Initial implementation of detected ID orientation
- Increased logging of errors
- Exposed JobError properties

## [0.9.0](https://github.com/vouched/vouched-ios/compare/v0.8.1...v0.9.0) - 2021-11-15

#### Removed
- ML Kit dependency
- Sentry dependency

## [0.8.1](https://github.com/vouched/vouched-ios/compare/v0.8.0...v0.8.1) - 2021-10-06

#### Added
- Compiled with Swift 5.5

## [0.8.0](https://github.com/vouched/vouched-ios/compare/v0.7.3...v0.8.0) - 2021-09-30

#### Added
- Updated job model
- Error when assets are misconfigured

## [0.7.3](https://github.com/vouched/vouched-ios/compare/v0.7.2...v0.7.3) - 2021-09-17

#### Added

- Error reporting with Sentry
- Ablility to reuse VouchedSession instance for failed verifications
- Improvements for LivenessMode.distance 
- VouchedCameraHelper example for face capture

## [0.7.2](https://github.com/vouched/vouched-ios/compare/v0.7.1...v0.7.2) - 2021-08-12

#### Removed

- Dependency that may lead to crashes

## [0.7.1](https://github.com/vouched/vouched-ios/compare/v0.7.0...v0.7.1) - 2021-08-10

#### Added

- Example for VouchedCameraHelper
- Better error handling and logging

## [0.7.0](https://github.com/vouched/vouched-ios/compare/v0.6.4...v0.7.0) - 2021-08-08

#### Added

- VouchedCameraHelper
- Split Core and Barcode dependencies

#### Breaking Changes

- CardDetect.detect
- FaceDetect.detect

## [0.6.4](https://github.com/vouched/vouched-ios/compare/v0.6.3...v0.6.4) - 2021-06-13

#### Added

- boundingBox to CardDetectResult

## [0.6.3](https://github.com/vouched/vouched-ios/compare/v0.6.2...v0.6.3) - 2021-06-03

#### Added

- token to VouchedSessionParameters

## [0.6.2](https://github.com/vouched/vouched-ios/compare/v0.6.1...v0.6.2) - 2021-05-14

#### Added

- Bug Fixes
- Update ResultsViewController

## [0.6.1](https://github.com/vouched/vouched-ios/compare/v0.6.0...v0.6.1) - 2021-05-10

#### Added

- VouchedSessionParameters
- reset() for detectors
- Eventing
- Bug Fixes

## [0.6.0](https://github.com/vouched/vouched-ios/compare/v0.5.8...v0.6.0) - 2021-05-01

#### Added

- Barcode Support
- Example port to Swift 5
- Xcode 12.5 Support

## [0.5.8](https://github.com/vouched/vouched-ios/compare/v0.5.7...v0.5.8) - 2021-04-23

#### Added

- Update Model

## [0.5.7](https://github.com/vouched/vouched-ios/compare/v0.5.6...v0.5.7) - 2021-04-18

#### Added

- Blinking Liveness
- Update README

## [0.5.6](https://github.com/vouched/vouched-ios/compare/v0.5.5...v0.5.6) - 2021-04-12

#### Added

- Update Authentication

## [0.5.5](https://github.com/vouched/vouched-ios/compare/v0.5.4...v0.5.5) - 2021-03-23

#### Added

- Support Bitcode

## [0.5.4](https://github.com/vouched/vouched-ios/compare/v0.5.3...v0.5.4) - 2021-02-10

#### Added

- Consistency and performance improvements

## [0.5.3](https://github.com/vouched/vouched-ios/compare/v0.5.2...v0.5.3) - 2021-02-08

## [0.5.2](https://github.com/vouched/vouched-ios/compare/v0.5.1...v0.5.2) - 2021-02-08

#### Changed

- Update hold steady logic

## [0.5.1](https://github.com/vouched/vouched-ios/compare/v0.5.0...v0.5.1) - 2021-02-07

#### Added

- Pass API Key into VouchedSession initializer (Optional)

#### Removed

- Auto job confirmations

## [0.5.0](https://github.com/vouched/vouched-ios/compare/v0.4.4...v0.5.0) - 2021-01-27

#### Added

- Distance liveness module
- Performance updates

#### Changed

- Retryable Errors interface and logic

#### Breaking Changes

- CardDetect initializer
- FaceDetect initializer

## [0.4.4](https://github.com/vouched/vouched-ios/compare/v0.4.3...v0.4.4) - 2020-11-02

#### Added

- Ability to upload secondary images associated with job

## [0.4.3](https://github.com/vouched/vouched-ios/compare/v0.4.2...v0.4.3) - 2020-09-23

#### Added

- Lower threshold for .moveCloser
- Lower threshold for .lookForward

## [0.4.2](https://github.com/vouched/vouched-ios/compare/v0.4.1...v0.4.2) - 2020-09-15

#### Added

- Bug Fixes

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
