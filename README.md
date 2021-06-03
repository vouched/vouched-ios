# Vouched

[![Version](https://img.shields.io/cocoapods/v/Vouched.svg?style=flat)](https://cocoapods.org/pods/Vouched)
[![License](https://img.shields.io/cocoapods/l/Vouched.svg?style=flat)](https://cocoapods.org/pods/Vouched)
[![Platform](https://img.shields.io/cocoapods/p/Vouched.svg?style=flat)](https://cocoapods.org/pods/Vouched)

## Run Example

Clone this repo and change directory to _example_

```shell
git clone https://github.com/vouched/vouched-ios

cd vouched-ios/Example
```

Then, follow steps listed on the [example README](https://github.com/vouched/vouched-ios/blob/master/Example/README.md)

## Prerequisites

- An account with Vouched
- Your Vouched Public Key
- Mobile Assets (available on the dashboard)

## Install

Add the package to your existing project's Podfile

```shell
pod 'Vouched', 'VOUCHED_VERSION'
```

## Getting Started

This section will provide a _step-by-step_ to understand the Vouched SDK through the Example.

0. [Get familiar with Vouched](https://docs.vouched.id/#section/Overview)

1. [Run the Example](#run-example)
   - Go through the verification process but stop after each step and take a look at the logs. Particularly understand the [Job](https://docs.vouched.id/#tag/job-model) data from each step.
   ```swift
   print(job)
   ```
   - Once completed, take a look at the [Job details on your Dashboard](https://docs.vouched.id/#section/Dashboard/Jobs)
2. Modify the [SampleBufferDelegate](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate)

   - Locate the [captureOutput](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput) in each Controller and make modifications.

     - Comment out the [RetryableErrors](#retryableerror)
       `let retryableErrors = ...`
     - Add custom logic to display data or control the navigation

   - Locate the Vouched detectors and add logging
     - `cardDetect.detect(imageBuffer!)`
     - `faceDetect.detect(imageBuffer!)`

3. Tweak [AVCapture](https://developer.apple.com/documentation/avfoundation/avcapturedevice) settings  
   Better images lead to better results from Vouched AI
4. You are ready to integrate Vouched SDK into your app

## Reference

### VouchedSession

This class handles a user's Vouched session. It takes care of the API calls. Use one instance for the duration of a user's verification session.

##### Initialize

```swift
let session = VouchedSession(apiKey: "PUBLIC_KEY", groupId: "GROUP_ID")
```

| Parameter Type | Nullable |
| -------------- | :------: |
| String         |  false   |
| String         |   true   |

##### Initializing with a token
```swift
let session = VouchedSession(apiKey: "PUBLIC_KEY", groupId: "GROUP_ID", sessionParameters: VouchedSessionParameters(token: "TOKEN"))
```

##### POST Front Id image

```swift
let job = try session.postFrontId(detectedCard: detectedCard, params: &params)
```

| Parameter Type                        | Nullable |
| ------------------------------------- | :------: |
| [CardDetectResult](#carddetectresult) |  false   |
| [Params](#params)                     |   true   |

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

##### POST Selfie image

```swift
let job = try session.postFace(detectedFace: detectedFace)
```

| Parameter Type                        | Nullable |
| ------------------------------------- | :------: |
| [FaceDetectResult](#facedetectresult) |  false   |

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

##### POST confirm verification

```swift
let job = try session.postConfirm()
```

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

### CardDetect

This class handles detecting an ID (cards and passports) and performing necessary steps to ensure image is `Step.postable`.

##### Initialize

```swift
let cardDetect = CardDetect(options: CardDetectOptionsBuilder().withEnableDistanceCheck(true).build())
```

| Parameter Type                          | Nullable |
| --------------------------------------- | :------: |
| [CardDetectOptions](#carddetectoptions) |  false   |

##### Process Image

```swift
let detectedCard = cardDetect.detect(imageBuffer)
```

| Parameter Type | Nullable |
| -------------- | :------: |
| CVImageBuffer  |  false   |

`Returns` - [CardDetectResult](#carddetectresult)

### FaceDetect

This class handles detecting a face and performing necessary steps to ensure image is `Step.postable`.

##### Initialize

```swift
let faceDetect = FaceDetect(options: FaceDetectOptionsBuilder().withLivenessMode(.distance).build())
```

| Parameter Type                          | Nullable |
| --------------------------------------- | :------: |
| [FaceDetectOptions](#facedetectoptions) |  false   |

##### Process Image

```swift
let detectedFace = faceDetect.detect(imageBuffer)
```

| Parameter Type | Nullable |
| -------------- | :------: |
| CVImageBuffer  |  false   |

`Returns` - [FaceDetectResult](#facedetectresult)

### Types

##### CardDetectResult

The output from [Card Detection](#carddetect) and used to submit an ID.

```swift
struct CardDetectResult {
    public let image: String?
    public let distanceImage: String?
    public let step: Step
    public let instruction: Instruction
}
```

##### FaceDetectResult

The output from [Face Detection](#facedetect) and used to submit a Selfie.

```swift
struct FaceDetectResult {
    public let image: String?
    public let distanceImage: String?
    public let step: Step
    public let instruction: Instruction
}
```

##### Params

The parameters that are used to submit a Job.

```swift
struct Params: Codable{
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var birthDate: String?
    var properties: [Property]?
    var idPhoto: String?
    var userPhoto: String?
    var idDistancePhoto: String?
    var userDistancePhoto: String?
}
```

##### CardDetectOptions

The options for [Card Detection](#carddetect).

```swift
class CardDetectOptionsBuilder {
    public func withEnableDistanceCheck(_ enableDistanceCheck: Bool) -> CardDetectOptionsBuilder { ... }

    public func build() -> CardDetectOptions { ... }
}
```

##### FaceDetectOptions

The options for [Face Detection](#facedetect).

```swift
class FaceDetectOptionsBuilder {
    public func withLivenessMode(_ livenessMode: LivenessMode) -> FaceDetectOptionsBuilder { ... }

    public func build() -> FaceDetectOptions { ... }
}
```

##### RetryableError

An enum to provide an optional baseline of Verification Error(s) for a given Job.

```swift
enum RetryableError: String {
    case invalidIdPhotoError
    case blurryIdPhotoError
    case glareIdPhotoError
    case invalidUserPhotoError
}
```

## Debugging/Logging

Configure VouchedLogger to the destination and level desired. If not configured, VouchedLogger defaults to `.none` and `.error`

```swift
VouchedLogger.shared.configure(destination: .xcode, level: .debug)
```

Destinations - where the log output is written

- .xcode (Xcode output)
- .console (Console app via [os_log](https://developer.apple.com/documentation/os/oslog))
- .none

Levels - the severity of the log

- .debug
- .info
- .error

The level is inclusive of more severe logs. i.e - `.debug` will also log `.info` and `.error`

## License

Vouched is available under the Apache License 2.0 license. See the LICENSE file for more info.
