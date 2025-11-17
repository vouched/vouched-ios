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


## Install

Add the package to your existing project's Podfile

```shell
pod 'Vouched', 'VOUCHED_VERSION'
```

## SDK Job Types

The Vouched SDK supports three different types of verification jobs, which serve different purposed in verification:

1. **IDV (Identity Verification) Job**
   - Captures and verifies an ID document (driver's license, passport, etc.)
   - Captures a selfie of the user
   - Performs liveness detection
   - Matches the selfie against the ID photo
   - Used for full identity verification workflows
   - Use the 
2. **Reverification Job**
   - Captures a new selfie and compares it against a previously completed IDV job
   - Useful for re-authenticating returning users
   - Requires the original job ID and user photo
3. **Selfie Verification Job**
   - Captures only a selfie of the user
   - Performs liveness detection
   - Does not require ID document
   - Useful for basic presence and liveness verification

## Reference

### VouchedCameraHelper

This class is introduced to make it easier for developers to integrate `VouchedSDK` and provide the optimal photography. The helper takes care of configuring the capture session, input, and output. 

##### Initialize

You can initialize the helper by specifying a Detector that you wish to use. Note how some of the controllers have a convenience method ```configureHelper(_ detector: Detector.Type)``` to simplify the configuration of the helper.

```swift
let helper = VouchedCameraHelper(with detector: Detector.Type, helperOptions: VouchedCameraHelperOptions, detectionOptions: [VouchedDetectionOptions], in: UIView)
```

##### Observe Results

There are two helper methods that serve as delegates to obtain capturing results

```swift
func withCapture(delegate: @escaping ((CaptureResult) -> Void)) -> VouchedCameraHelper
```


| Parameter Type                            | Nullable |
| ------------------------------------------- | :--------: |
| Closure([CaptureResult](#captureresult) ) |  false  |

```swift
func observeBoundingBox(observer: @escaping ((BoundingBox) -> Void)) -> VouchedCameraHelper
```


| Parameter Type                      | Nullable |
| ------------------------------------- | :--------: |
| Closure([BoundingBox](boundingbox)) |  false  |

##### Run

In order to start capturing, put the following code:

```swift
helper.startCapture()
```

Once the results are ready to process/submit, stop capturing:

```swift
helper.stopCapture()
```

##### Usage

Typical usage is as follows:
**Note:** you can inspect the results delivered from the callback, and do additional processing before using the session object to post the results to the api service.:

```swift
let helper = VouchedCameraHelper(with: .id,
                                 detectionOptions: [.cardDetect(CardDetectOptionsBuilder().withEnableDistanceCheck(false).build())],
                                 in: previewContainer)?
    .withCapture(delegate: { (result) in
        switch result {
        case .empty:
            ...
        case .id(let result):
            ...
        default:
            break
        }
    })
```

### VouchedDetectionManager

This class is introduced to help guide the ID verification modes by processing job results returned by the Vouched API service, and generating the appropriate modes that are needed to complete ID verification.  For example, consider a ID that has important verification This is particularly important if you are verifying identities in countries where some of the information needed for verification is on the back side of the ID, the detection manager will prompt the user to turn the card around to capture that information.

##### Initialize

```swift
    let helper: VouchedCameraHelper
    let session: VouchedSession
    let config = VouchedDetectionManagerConfig(session: session)
    let callbacks = DetectionCallbacks
    config.callbacks = callbacks
    let detectionMgr = VouchedDetectionManager(helper: helper, config: config)
```

##### Run

In order to start detection, put the following code:

```swift
    detectionMgr.startDetection()
```

If there is a need to capture additional info the following closure will be called :

```swift
    let callbacks = DetectionCallbacks { change in
        let alert = UIAlertController(title: nil, message: "Turn ID card over to backside", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { _ in
            change.completion(true)
        })
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
```

Once the detection process is finished and there is a `Job` result the following closure will be called:

```swift
    let callbacks: DetectionCallbacks
    callbacks.detectionComplete = { result in
        switch result {
        case .success(let job):
                print("\(job)")
        case .failure(let err):
            print("Error: \(err)")
        }
```

Examine the `extension IdViewController : VouchedDetectionManager` in the example app to see how this mechanism can be implemented. 


### VouchedSession

This class handles a user's Vouched session. It takes care of the API calls. 
**Note:** Use only one instance of the session object for the duration of a user's verification session

##### Initialize

```swift
let session = VouchedSession(apiKey: "PUBLIC_KEY", groupId: "GROUP_ID")
```


| Parameter Type | Nullable |
| ---------------- | :--------: |
| String         |  false  |
| String         |   true   |

##### Initializing with a token

```swift
let session = VouchedSession(apiKey: "PUBLIC_KEY", groupId: "GROUP_ID", sessionParameters: VouchedSessionParameters(token: "TOKEN"))
```

##### POST Front Id image

```swift
let job = try session.postFrontId(detectedCard: detectedCard, details: details)
```


| Parameter Type                        | Nullable |
| --------------------------------------- | :--------: |
| [CardDetectResult](#carddetectresult) |  false  |
| [Params](#params)                     |   true   |

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

##### POST Selfie image

```swift
let job = try session.postFace(detectedFace: detectedFace)
```


| Parameter Type                        | Nullable |
| --------------------------------------- | :--------: |
| [FaceDetectResult](#facedetectresult) |  false  |

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

##### POST confirm verification

```swift
let job = try session.postConfirm()
```

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

##### POST re-verification

```swift
let job = try session.postReverify(jobID: String, userPhoto: String)
```

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

##### POST Selfie verification

```swift
let job = try session.postSelfieVerification(detectedFace: detectedFace)
```


| Parameter Type                        | Nullable |
| ------------------------------------- | :------: |
| [FaceDetectResult](#facedetectresult) |  false   |

`Returns` - [Job](https://docs.vouched.id/#tag/job-model)

| Parameter Type                    | Nullable |
| --------------------------------- | :------: |
| jobID                             |  false   |
| userPhoto (base64 encoded string) |  false   |

### CardDetect

This class handles detecting an ID (cards and passports) and performing necessary steps to ensure image is `Step.postable`.

##### Initialize

```swift
let cardDetect = CardDetect(options: CardDetectOptionsBuilder().withEnableDistanceCheck(true).build())
```


| Parameter Type                          | Nullable |
| ----------------------------------------- | :--------: |
| [CardDetectOptions](#carddetectoptions) |  false  |

##### Process Image

```swift
let detectedCard = cardDetect?.detect(sampleBuffer)
```


| Parameter Type | Nullable |
| ---------------- | :--------: |
| CVImageBuffer  |  false  |

`Returns` - [CardDetectResult](#carddetectresult)

### FaceDetect

This class handles detecting a face and performing necessary steps to ensure image is `Step.postable`.

##### Initialize

```swift
let faceDetect = FaceDetect(options: FaceDetectOptionsBuilder().withLivenessMode(.distance).build())
```


| Parameter Type                          | Nullable |
| ----------------------------------------- | :--------: |
| [FaceDetectOptions](#facedetectoptions) |  false  |

##### Process Image

```swift
let detectedFace = faceDetect?.detect(sampleBuffer)
```


| Parameter Type | Nullable |
| ---------------- | :--------: |
| CVImageBuffer  |  false  |

`Returns` - [FaceDetectResult](#facedetectresult)

### Types

##### BoundingBox

The bounding box of detected `ID card` for the output from [Card Detection](#carddetectresult).

```swift
public struct BoundingBox {
    public let box: CGRect?
    public let imageSize: CGSize
}
```

##### CardDetectResult

The output from [Card Detection](#carddetect) and used to submit an ID.

```swift
struct CardDetectResult {
    public let image: String?
    public let distanceImage: String?
    public let step: Step
    public let instruction: Instruction
    public let boundingBox: CGRect?
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
    public func withEnhanceInfoExtraction(_ enhanceInfoExtraction: Bool) -> CardDetectOptionsBuilder
    
    public func build() -> CardDetectOptions { ... }
}
```

The [VouchedDetectionManager](#voucheddetectionmanager) can increase your verification abilities by recognizing additional sources of information based on the ID that your user submits.  You can enable this behavior by using  ```.withEnhanceInfoExtraction(true)``` when setting

**ValidationParameters**

These are optional configuration parameters can be used used to provide input to the IDV session when using the [VouchedDetectionManager](#voucheddetectionmanager). More information about their usage can be found in [our documentation] (https://docs.vouched.id/docs/js-plugin#verification-object). 

```
public struct VouchedValidationParamSettings: VouchedValidationParams {
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var phone: String?
    public var birthDate: String?
    public var geoLocation: Geolocation?
    public var enablePhysicalAddress: Bool?
    public var enableIPAddress: Bool?
    public var enableDarkWeb: Bool?
    public var enableCrossCheck: Bool?
    public var enableDriversLicenseValidation: Bool?
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

##### VouchedCameraMode

An enum to provide mode for [VouchedCameraHelper](#vouchedcamerahelper)

```swift
public enum VouchedCameraMode {
    case id
    case barcode(String, DetectorOptions)
    case selfie
}
```

##### VouchedCameraHelperOptions

List of options to alter image processing for [VouchedCameraHelper](#vouchedcamerahelper)

```swift
public struct VouchedCameraHelperOptions {
    public static var usePhotoCapture: VouchedCameraHelperOptions
    public static var cropIdImage: VouchedCameraHelperOptions
}
```

##### VouchedDetectionOptions

An enum to provide settings for `ID`/`Selfie` detection for [VouchedCameraHelper](#vouchedcamerahelper)

```swift
public enum VouchedDetectionOptions {
    case cardDetect(CardDetectOptions)
    case faceDetect(FaceDetectOptions)
}
```


| Parameter Type                          | Nullable |
| ----------------------------------------- | :--------: |
| [CardDetectOptions](#carddetectoptions) |  false  |
| [FaceDetectOptions](#facedetectoptions) |  false  |

##### CaptureResult

An enum to deliver detection results

```swift
public enum CaptureResult {
    case empty
    case id(DetectionResult)
    case selfie(DetectionResult)
    case barcode(DetectionResult)
}
```


| Parameter Type                      | Nullable |
| ------------------------------------- | :--------: |
| [DetectionResult](#detectionresult) |  false  |

##### DetectionResult

Generic protocol, used to submit detection results

```swift
public protocol DetectionResult {
    func params() throws -> Params
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