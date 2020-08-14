# Vouched

[![Version](https://img.shields.io/cocoapods/v/Vouched.svg?style=flat)](https://cocoapods.org/pods/Vouched)
[![License](https://img.shields.io/cocoapods/l/Vouched.svg?style=flat)](https://cocoapods.org/pods/Vouched)
[![Platform](https://img.shields.io/cocoapods/p/Vouched.svg?style=flat)](https://cocoapods.org/pods/Vouched)

## Run the Example

1. Clone the repo and run `pod install` from the Example directory
2. Setup the [environment variables](#environment-variables)
3. Add `inference_graph.tflite` and `labelmap_mobilenet_card.txt` to the ./Example/Vouched directory. Ensure these files are in **Copy Bundle Resources**
4. Run Vouched-Example on a device with iOS 11.0+

**1st Screen** - Name Input (Optional)  
**2st Screen** - Card Detection   
**3nd Screen** - Face Detection  
**4th Screen** - ID Verification Results  
**5th Screen** - Face Authenticaion (**Demo purposes only**) 

#### Features displayed in Example 
* ID Card and Passport Detection
* Face Detection (w and w/o liveness)
* ID Verification
* Name Verification
* Face Authenticaion (**Demo purposes only**)

## How to use the Vouched Library

The Vouched library are the contents of the Vouched directory.
The goal is to distribute the library as a CocoaPod.
To use the library in your own project refer to the following code snippets:

**ID Card detection and submission**

```
import Vouched
let cardDetect = CardDetect()
let session: VouchedSession = VouchedSession(type: .idVerificationWithFace)

let detectedCard = cardDetect.detect(cvPixelBuffer)


if let detectedCard = detectedCard {
  switch detectedCard.step {
  case .preDetected:
    // prompt user to show ID card
  case .detected:
    updateLabelFromInstruction(detectedCard.instruction)
  case .postable:
    do {
      let job = try session.postFrontId(detectedCard: detectedCard)
    } catch {
      // handle error cases
    }
  }
} else {
    // prompt user to show ID card
}
```

**Face(Selfie) detection and submission**

```
import Vouched
let faceDetect = FaceDetect(config: FaceDetectConfig(liveness: .mouthMovement))

if let detectedFace = detectedFace {
  switch detectedFace.step {
  case .preDetected:
    // prompt user to look into camera
  case .detected:
    updateLabelFromInstruction(detectedFace.instruction)
  case .postable:
    do {
      // make sure to use the same session instance created previously
      let job = try session.postFace(detectedFace: detectedFace)
    } catch {
      // handle error cases
    }
  }
} else {
    // prompt user to look into camera
}
```

**Debugging/Logging Vouched**  
Destinations - where the log output is written
* .xcode (Xcode output)
* .console (Console app via [os_log](https://developer.apple.com/documentation/os/oslog))
* .none

Levels - the severity of the log
* .debug
* .info
* .error

The level is inclusive of more severe logs. i.e - debug will also log info and error 

Configure VouchedLogger to the destination and level desired
```
VouchedLogger.shared.configure(destination: .xcode, level: .debug)
```
If not configured, VouchedLogger defaults to .none and .error

## Environment Variables

Set Environment Variables:

[XCConfig Reference](https://www.mokacoding.com/blog/double-slash-xcconfig/). Create `Example/Development.xcconfig` where the contents are:

```
API_KEY = <PUBLIC_KEY>
APP_NAME = Vouched (Dev)

// local dev server usage only. Otherwise don't specify API_URL
SLASH = /
API_URL = http:$(SLASH)/localhost:7700

```

## Tests

Located under:
`Example/Tests`

Running tests:

- Open Xcode
- Select Product/Test (Cmd+U)

## License

Vouched is available under the Apache License 2.0 license. See the LICENSE file for more info.
