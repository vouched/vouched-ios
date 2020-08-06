# Vouched

[![CI Status](https://img.shields.io/travis/marcusoliver/Vouched.svg?style=flat)](https://travis-ci.org/marcusoliver/Vouched)
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
**5th Screen** - Face Authenticaion  

#### Features displayed in Example 
* ID Card and Passport Detection
* Face Detection (w and w/o liveness)
* ID Verification
* Name Verification
* Face Authenticaion (Demo purposes only)

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
  if cardDetect.isFar() {
    // prompt user to move camera closer
  } else if !cardDetect.isPostable() {
    // prompt user to hold camera steady
  }
  else {
    // the card/passport is detected, is close enough, and is ready to submit

    do {
      let job = try session.postFrontId(detectedCard: detectedCard)
      // make sure to hold on to job.token (theJobToken)
      // this token will be needed for future requests
    } catch {
      // handle error cases
    }
  }
}
```

**Face(Selfie) detection and submission**

```
import Vouched
let faceDetect = FaceDetect(config: FaceDetectConfig(liveness: .mouthMovement))

if let detectedFace = detectedFace {
  switch detectedFace.step {
  case .preDetected:
    self.instructionLabel.text = "Loading Camera"
  case .detected:
    updateLabelFromInstruction(detectedFace.instruction)
  case .postable:
    do {
      // make sure to use the same session instance created above
      let job = try session!.postFace(detectedFace: detectedFace)
    } catch {
      // handle error cases
    }
  }
} else {
  DispatchQueue.main.async() {
    self.instructionLabel.text = "Waiting for a face"
  }
}
```

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

## Tips

- Create a new Swift class
  - Add to Vouched/Classes
  - Add file from XCode
  - Run pod install

## Classes

- Config.swift - configuration static and env variables

## Tests

Located under:
`Example/Tests`

Running tests:

- Open Xcode
- Select Product/Test (Cmd+U)

## License

Vouched is available under the Apache License 2.0 license. See the LICENSE file for more info.
