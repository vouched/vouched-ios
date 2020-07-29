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

**1st Screen** - Card Detection   
**2nd Screen** - Face Detection  
**3rd Screen** - ID Verification Results  

## How to use the Vouched Library
The Vouched library are the contents of the Vouched directory.
The goal is to distribute the library as a CocoaPod.
To use the library in your own project refer to the following code snippets:

**ID Card detection and submission**
```
import Vouched
let cardDetect = CardDetect()

let detectedCard = cardDetect.detect(cvPixelBuffer)

if let detectedCard = detectedCard {
  if cardDetect.isFar() {
    // prompt user to move camera closer
  } else if !cardDetect.isPostable() {
    // prompt user to hold camera steady
  }
  else {
    // the card/passport is detected, is close enough, and is ready to submit

    let idPhoto = detectedCard.base64Image
    do {
      let params = Params(idPhoto: idPhoto)
      let request = SessionJobRequest(stage: Stage.id, params: params)
      let job = try API.jobSession(request: request)
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
let faceDetect = FaceDetect()

if let detectedFace = detectedFace {
  if faceDetect.isFar() {
    // prompt user to move camera closer
  } else if !self.cardDetect.isPostable() {
    // prompt user to hold camera steady
  }
  else {
    // the face is detected, is close enough, and is ready to submit
    
    let userPhoto = detectedFace.base64Image
    do {
      let params = Params(userPhoto: userPhoto)
      let request = SessionJobRequest(stage: Stage.face, params: params)
      let job = try API.jobSession(request: request, token: theJobToken)
    } catch {
      // handle error cases
    }
  }
}
```
**Getting the final results**
```
  let request = SessionJobRequest(stage: Stage.confirm, params: Params())
  let job = try API.jobSession(request: request, token: theJobToken)
  let result = job.result
  // display the results to the user
```

## Environment Variables

Set Environment Variables:

- Edit scheme Vouched-Example
- Run / Arguments / Environment Variables
- Add API_URL=\*
- Add API_KEY=<PUBLIC_KEY>

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
