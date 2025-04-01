![Version](https://img.shields.io/cocoapods/v/Vouched.svg?style=flat) ![License](https://img.shields.io/cocoapods/l/Vouched.svg?style=flat) ![Platform](https://img.shields.io/cocoapods/p/Vouched.svg?style=flat)

## Overview

**Vouched iOS SDK** is a mobile identity verification library that allows your app to capture and verify user identity documents and selfies using Vouched’s AI. It ensures clear ID images, performs face detection with liveness checks, and handles the server-side verification process. The SDK supports multiple types of verification jobs:

- **IDV (Identity Verification)** – Capture and verify a government-issued ID (driver’s license, passport, etc.) *and* a selfie. The SDK checks liveness and matches the face to the ID photo. This is used for full identity verification workflows (ID + selfie).
- **Reverification** – Capture a new selfie and compare it to a previously verified user’s ID or selfie on file. This requires an existing completed IDV job ID and reference photo, and is useful for re-authenticating returning users without requiring their ID again.
- **Selfie Verification** – Capture only a selfie with liveness detection (no ID document). This provides basic face presence verification and is useful for simple identity checks or presence verification where an ID document is not required.

## Table of Contents

- [Quickstart: Running the Example App](#quickstart-running-the-example-app)
- [Integrating the SDK with an existing app](#integrating-the-sdk)
- [Core SDK Components](#core-sdk-components)
  - [VouchedCameraHelper](#vouchedcamerahelper)
    - [Initialization](#initialization)
    - [Observing Capture Results](#observing-capture-results)
    - [Starting and Stopping Capture](#starting-and-stopping-capture)
    - [Example Usage](#example-usage)
  - [VouchedDetectionManager](#voucheddetectionmanager)
    - [Initialization](#initialization-1)
    - [Running Detection](#running-detection)
    - [Handling Detection Callbacks](#handling-detection-callbacks)
  - [VouchedSession](#vouchedsession)
    - [Initialization](#initialization-2)
    - [Key Methods (Submitting Data)](#key-methods-submitting-data)
  - [CardDetect](#carddetect)
  - [FaceDetect](#facedetect)
  - [Supporting Types & Options](#supporting-types--options)
    - [BoundingBox](#boundingbox)
    - [CardDetectResult](#carddetectresult)
    - [FaceDetectResult](#facedetectresult)
    - [Params](#params)
    - [CardDetectOptions](#carddetectoptions)
    - [FaceDetectOptions](#facedetectoptions)
    - [RetryableError](#retryableerror)
    - [VouchedCameraMode](#vouchedcameramode)
    - [VouchedCameraHelperOptions](#vouchedcamerahelper-options)
    - [VouchedDetectionOptions](#voucheddetectionoptions)
    - [CaptureResult](#captureresult)
    - [DetectionResult](#detectionresult)
- [Debugging and Logging](#debugging-and-logging)
- [License](#license)

## Quickstart: Running the Example App

Follow these steps to quickly run the **Vouched Example** app and see the SDK in action:

1. **Prerequisites**: Sign up for a Vouched account and obtain your **Public API Key** from the Vouched dashboard (under **Keys**).  Ensure you have Xcode installed and an iOS device running iOS 15.0 or later (cameras do **not** work in the iOS Simulator - you will need to run the SDK on an actual divide).

2. **Clone the Repo**: Clone this repository and open the example project:

   ```
   git clone https://github.com/vouched/vouched-ios.git  
   cd vouched-ios/Example
   ```

3. **Install Dependencies**: In the `Example` directory, install the CocoaPods dependencies:

   ```
   pod install
   ```

   This will install the Vouched SDK and any required libraries. After installation, open the generated `Vouched-Example.xcworkspace`.

4. **Configure the Example**: Add your Vouched API key to a file called `Development.xcconfig`:

   ```
   API_KEY = <PUBLIC_KEY_STRING>
   APP_NAME = Vouched Example
   ```

   

5. **Run on a Device**: Connect your iPhone and build/run the **Vouched-Example** scheme in Xcode. Once installed, click on 'Start Verification' will guide you through the verification flow:

   - **Screen 1:** Enter Name and display options (Optional, used for populating `Params` and verification properties like first/last name).
   - **Screen 2:** ID Card Detection (scans the ID document). When using the VoucheDetectionManager (enabled by default), you may be prompted to flip the ID card over if there is more data to retrieve on the backside of the ID
   - **Screen 3:** Face (Selfie) Detection (with liveness checks).
   - **Screen 4:** Verification Results (IDV results are displayed).
   - **Screen 5:** Face Authentication (demo purposes, e.g., reverification flow).

*Note:* The example app demonstrates features like ID and passport detection, face detection (with and without liveness), ID document verification, name matching, and a basic face re-authentication demo. Use it as a reference for integrating the SDK into your own app.

## Integrating the SDK

The Vouched iOS SDK is distributed via **CocoaPods**. Ensure you have CocoaPods installed, then add the Vouched pod to your project:

1. In your app’s `Podfile`, add Vouched with the latest version, for example:

   ```
   target 'YourAppTarget' do
       pod 'Vouched', '~> 1.9'
   end
   ```

   Replace `~> 1.9` with the desired version or use a specific version if needed.

2. Run `pod install` and open the generated `.xcworkspace` in Xcode.

3. In your Swift files where you use the SDK, import the module:

   ```
   import Vouched
   ```

4. **Camera Permissions**: Make sure to update your app’s **Info.plist** to include a camera usage description (`NSCameraUsageDescription`). This is required for the app to access the device camera for ID and face capture.

After installation and setup, you are ready to integrate the Vouched SDK into your view controllers and begin capturing IDs and selfies for verification.

## Core SDK Components

The Vouched SDK provides several core classes that you will use to capture images and manage the verification process. Below is a breakdown of the major components and how to use them:

### VouchedCameraHelper

The `VouchedCameraHelper` simplifies camera integration and optimizes it for identity document or face capture. It configures the camera capture session (inputs, outputs, focus, etc.) and provides callbacks for detection results.

#### Initialization

Create a `VouchedCameraHelper` by specifying the detection mode (ID or selfie), any helper options, detection options, and the UIView in which the camera preview will display. Many view controllers (like the example app’s ID or selfie view controller) provide convenience methods to configure this helper.

```
let helper = VouchedCameraHelper(
    with: detectorType,              // e.g., .id for ID mode, .selfie for selfie mode
    helperOptions: VouchedCameraHelperOptions, 
    detectionOptions: [VouchedDetectionOptions], 
    in: previewView                  // the UIView that shows the camera preview
)
```

- `detectorType` is a `VouchedCameraMode` (like `.id` or `.selfie` or a barcode mode) determining what the camera is looking for.
- `helperOptions` can be used to tweak image capturing (see VouchedCameraHelperOptions). For most cases, the default is fine.
- `detectionOptions` allows you to specify settings for ID or face detection. For example, you can pass `.cardDetect(...)` with custom `CardDetectOptions` or `.faceDetect(...)` with custom `FaceDetectOptions`.

#### Observing Capture Results

Use delegate closures to receive results from the camera in real-time:

```
helper.withCapture { result in
    // This closure is called whenever a new detection result is available.
}
```

- The closure provides a `CaptureResult` (see CaptureResult), which can be:
  - `.empty` – nothing detected yet (frame is processing or not containing the target).
  - `.id(let detectionResult)` – an ID card/passport was detected (includes image and status).
  - `.selfie(let detectionResult)` – a face was detected.
  - `.barcode(let detectionResult)` – a barcode was detected (if using barcode mode).

```
helper.observeBoundingBox { boundingBox in
    // This closure provides a BoundingBox for the detected ID, useful for drawing a rectangle on screen.
}
```

- The `boundingBox` is a `BoundingBox` struct containing the coordinates of the detected ID document in the camera frame and the image size. You can use this to guide the user (e.g., show a rectangle around the ID).

#### Starting and Stopping Capture

Start the camera preview and detection by calling:

```
helper.startCapture()
```

This begins the video feed and detection (ID or face) processing. Typically, you start capture when the view appears.

When you have obtained the required results and are ready to move on (for example, you got a `postable` ID image or a live selfie), stop the camera to halt detection:

```
helper.stopCapture()
```

Stopping capture frees up the camera and stops further processing. You might do this right before submitting to the API or when navigating away from the capture screen.

#### Example Usage

A typical usage pattern of `VouchedCameraHelper` in a view controller might look like this:

```
let helper = VouchedCameraHelper(with: .id,
                                 detectionOptions: [
                                     .cardDetect(
                                         CardDetectOptionsBuilder()
                                             .withEnableDistanceCheck(false)
                                             .build()
                                     )
                                 ],
                                 in: previewContainer)?
    .withCapture { result in
        switch result {
        case .empty:
            // No detection yet; you might show an instruction to align the ID
            break
        case .id(let idResult):
            // An ID was detected; you can inspect idResult (CardDetectResult)
            // e.g., check idResult.step or idResult.instruction for guidance
            break
        default:
            break
        }
    }
```

In the example above, we configure the helper for ID capture. We disable the distance check in `CardDetectOptions` (perhaps to allow closer capture without warning) and supply a preview view. The capture closure checks the result: if an ID is detected (`.id` case), we can examine the `idResult`. The `idResult.step` will indicate the state of detection (e.g., `.detected` or `.postable`), and `idResult.instruction` may provide a message or guidance (e.g., “Move closer”, “Hold steady”). Once `idResult.step` becomes `.postable`, it means we have a high-quality image ready to submit.

You can also use `observeBoundingBox` in combination with the above to draw a rectangle when an ID is detected to enhance the user experience.

### VouchedDetectionManager

The `VouchedDetectionManager` helps orchestrate multi-step ID verification flows. It processes the results from the Vouched API and guides what step is needed next. For instance, if an ID’s back side needs to be captured (common in countries where the back of the ID has data), the detection manager will prompt for it.

#### Initialization

To set up a `VouchedDetectionManager`, you need a `VouchedSession` (for making API calls) and a `VouchedCameraHelper` (for capturing images). You also configure it with `DetectionCallbacks` to handle events:

```
let helper: VouchedCameraHelper = ...       // already configured for .id mode
let session = VouchedSession(apiKey: "YOUR_PUBLIC_KEY", groupId: "GROUP_ID")
let config = VouchedDetectionManagerConfig(session: session)
let callbacks = DetectionCallbacks()        // we will set specific closures on this
config.callbacks = callbacks

let detectionMgr = VouchedDetectionManager(helper: helper, config: config)
```

- We create a `VouchedSession` (see VouchedSession) with your API key (and optionally a Group ID if your Vouched setup uses groups). This session will be used by the detection manager to submit images and get results.
- A `VouchedDetectionManagerConfig` is created with that session. We prepare a `DetectionCallbacks` object which will hold our callback closures for certain events, then assign it to the config.
- Finally, we initialize the `VouchedDetectionManager` with the camera helper and config.

#### Running Detection

Start the guided detection process by calling:

```
detectionMgr.startDetection()
```

This will begin the detection flow. Under the hood, the `VouchedDetectionManager` will use the camera helper to capture an ID image and submit it via the session. Depending on the response (Job result), it may proceed to the next required vision step (like prompting for the ID backside or a selfie).

#### Handling Detection Callbacks

You can customize what happens when additional information is needed or when the verification completes by using the `DetectionCallbacks`:

```
callbacks.onDetectionChange = { change in
    // Example: prompt the user to flip the ID for backside capture
    let alert = UIAlertController(title: nil, 
                                  message: "Turn ID card over to backside", 
                                  preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .default) { _ in
        // User is ready; signal to proceed with backside capture
        change.completion(true)
    }
    alert.addAction(ok)
    viewController.present(alert, animated: true)
}
```

In the above snippet, when the SDK determines another capture is needed (like the back of the ID), it triggers `onDetectionChange`. We present an alert to tell the user to flip their ID. Once the user taps OK, we call `change.completion(true)` to continue the process. (If we called `completion(false)`, it would cancel that step.)

For final results when the detection process is complete (either success or failure), use the `detectionComplete` callback:

```
callbacks.detectionComplete = { result in
    switch result {
    case .success(let job):
        print("Verification succeeded: \(job)")
        // You can use the Job result (contains verified user info and verification status)
    case .failure(let error):
        print("Verification failed with error: \(error)")
        // Handle the error (perhaps allow retry or display failure message)
    }
}
```

Here, `result` is a Swift `Result` type. On success, you get a `Job` object which includes all verification data (you might send this to your backend or use it to update UI). On failure, you get an error (for example, network issues or an invalid image).

*Tip:* Check out the example app’s implementation (in `IdViewController` extension for `VouchedDetectionManager`) to see a full usage of these callbacks in context.

### VouchedSession

The `VouchedSession` manages API interactions with the Vouched service. This class is responsible for taking the captured images (from `CardDetect` or `FaceDetect`) and submitting them to Vouched’s backend, then returning the verification job results. **Note:** You should create only **one** `VouchedSession` instance per verification workflow (e.g., keep one session throughout a single user verification process).

#### Initialization

Create a session with your **Public API Key** (and optionally a Group ID if your Vouched setup uses groups):

```
let session = VouchedSession(apiKey: "YOUR_PUBLIC_KEY", groupId: "YOUR_GROUP_ID")
```

- **apiKey** (String, non-null): Your Vouched public API key.
- **groupId** (String, optional): A specific group identifier, if provided by Vouched (can usually be omitted unless you have multiple groups).

If your workflow uses a temporary session token (for example, if provided by your backend for security), you can initialize with a token:

```
let session = VouchedSession(
    apiKey: "YOUR_PUBLIC_KEY", 
    groupId: "GROUP_ID", 
    sessionParameters: VouchedSessionParameters(token: "TEMPORARY_SESSION_TOKEN")
)
```

The token is optional and typically not needed for most integrations unless instructed by Vouched support.

#### Key Methods (Submitting Data)

Once you have a `VouchedSession`, you will use its methods to send captured data to the Vouched API. Each method returns a `Job` object containing the updated verification state.

- **postFrontId** – Submit the front side of an ID document. Call this when you have a front ID image ready (e.g., after `CardDetect` yields a postable image).

  ```
  let job = try session.postFrontId(detectedCard: detectedCardResult, details: userDetails)
  ```

  **Parameters:**
    • *detectedCard* (`CardDetectResult`) – The result from `CardDetect` for the ID image.
    • *details* (`Params`, optional) – Additional user details (first name, last name, etc.) if you want to submit them along with the ID.
   **Returns:** A `Job` model representing the state after uploading the ID. For example, the job might indicate that the front ID was received and whether the back side is needed.

- **postFace** – Submit a selfie image. Call this when you have captured a live face that is ready to be verified (e.g., after `FaceDetect` yields a postable image).

  ```
  let job = try session.postFace(detectedFace: detectedFaceResult)
  ```

  **Parameters:**
    • *detectedFace* (`FaceDetectResult`) – The result from `FaceDetect` for the selfie image.
   **Returns:** A `Job` model updated with the face verification attempt. This is typically used in the IDV flow after an ID has been submitted.

- **postSelfieVerification** - Submit a selfie image after a liveness check is done

  ```
  let job = try session.postSelfieVerification(detectedFace: detectedFaceResult, liveness: livenessMode)
  ```

  **Parameters:**
    • *detectedFace* (`FaceDetectResult`) – The result from `FaceDetect` for the selfie image.
   **Returns:** A `Job` model updated with the face verification attempt. This is used for liveness checks in t.

- **postConfirm** – Confirm that all required steps are done and finalize the verification. In an IDV flow, after submitting front ID, possibly back ID, and selfie, call this to tell the system to complete the job.

  ```
  let job = try session.postConfirm()
  ```

  **Returns:** A final `Job` model representing the completed verification. The job status will indicate success or contain any errors that need to be addressed.

- **postReverify** – Initiate a re-verification by submitting a new selfie against a past verification job. Use this for returning users to confirm they are the same person without a new ID.

  ```
  let job = try session.postReverify(jobID: "<PREVIOUS_JOB_ID>", userPhoto: "<BASE64_USER_PHOTO>")
  ```

  **Parameters:**
    • *jobID* (`String`) – The ID of the previously completed job you want to verify against.
    • *userPhoto* (`String`) – A base64-encoded image of the new user selfie to verify.
   **Returns:** A `Job` model containing the re-verification result (face matching outcome).

- **postSelfieVerification** – Submit a selfie-only verification job (no ID). Use this if you are doing a liveness or face check without an ID document (the **Selfie Verification** job type).

  ```
  let job = try session.postSelfieVerification(detectedFace: detectedFaceResult)
  ```

  **Parameters:**
    • *detectedFace* (`FaceDetectResult`) – The result from `FaceDetect` for the selfie image.
   **Returns:** A `Job` model representing the selfie verification result.

All these methods throw errors if something goes wrong (e.g., network failure or invalid input), so they are called with `try`. In a real app, you should handle errors (e.g., using `do-catch` in Swift) and provide feedback or retry options to the user if needed.

### CardDetect

The `CardDetect` class handles detection of ID cards or passports from camera frames. It uses the machine learning model to find the ID in a video frame and prepares the image for submission (cropping, checking quality, etc.).

#### Initialize

Initialize a `CardDetect` with desired options:

```
let cardDetect = CardDetect(options: 
    CardDetectOptionsBuilder()
        .withEnableDistanceCheck(true)
        .build()
)
```

- **options** (`CardDetectOptions`): Configuration for card detection. In this example, `withEnableDistanceCheck(true)` means the SDK will warn if the ID is too close or too far from the camera. You can also enable enhanced info extraction with `.withEnhanceInfoExtraction(true)` if available (this can automate capturing extra data like barcodes or MRZ to improve verification).

#### Process Image

Use `CardDetect` on a camera frame (CVImageBuffer) to attempt to detect an ID:

```
let detectedCard = cardDetect.detect(sampleBuffer)
```

- **sampleBuffer** (`CVImageBuffer`) – a video frame (usually from the `CMSampleBuffer` you get in a camera capture output callback).
- **Returns:** a `CardDetectResult` (or `nil` if no ID is detected at all). The `CardDetectResult` contains:
  - `image`: a base64 string of the cropped ID image (front side).
  - `distanceImage`: a base64 string of a farther zoomed-out image (useful for distance check or audit).
  - `step`: a `Step` enum indicating detection status (`.preDetected`, `.detected`, or `.postable`).
  - `instruction`: an `Instruction` (e.g., an enum or message guiding the user).
  - `boundingBox`: a `CGRect` for where the ID was found in the frame (if any).

Typically, you call `cardDetect.detect(...)` on each frame in a camera feed. Use the `step` and `instruction` from the result to update the UI. For example, if `step` is `.preDetected`, you might show “Center your ID in the frame.” If `step` is `.detected` (ID found but not optimal), you might use `instruction` to show something like “Hold steady” or “Move closer.” Once you get a result with `step == .postable`, you should stop the camera and submit that `detectedCard` via `VouchedSession.postFrontId`.

### FaceDetect

The `FaceDetect` class handles detecting a face (selfie) in camera frames and performing liveness checks. It ensures the face image meets quality and liveness requirements before submission.

#### Initialize

Initialize a `FaceDetect` with desired options:

```
let faceDetect = FaceDetect(options: 
    FaceDetectOptionsBuilder()
        .withLivenessMode(.distance)
        .build()
)
```

- **options** (`FaceDetectOptions`): Configuration for face detection. For example, `withLivenessMode(.distance)` sets the liveness detection mode. (Liveness modes might include `.distance` for a depth-based liveness check, or other modes like `.motion` or `.blink` depending on what the SDK supports.)

#### Process Image

Use `FaceDetect` on a camera frame to detect a face:

```
let detectedFace = faceDetect.detect(sampleBuffer)
```

- **sampleBuffer** (`CVImageBuffer`) – a video frame from the camera.
- **Returns:** a `FaceDetectResult` (or `nil` if no face is detected). The `FaceDetectResult` contains:
  - `image`: a base64 string of the face (selfie) image suitable for verification.
  - `distanceImage`: a base64 of an image used for liveness (could be a slightly different crop or scale).
  - `step`: a `Step` enum indicating the status of face detection/liveness (similar to ID detection, it might be `.preDetected`, `.detected`, or `.postable` when the face is good to go).
  - `instruction`: an `Instruction` guiding the user (e.g., “Frame your face in the oval” or “Move back a little”).

Just like with `CardDetect`, you typically call `faceDetect.detect(...)` on each video frame. Use the `step` to update the UI. Only proceed when you get a `.postable` face, indicating the face image passed liveness checks and is ready to submit via `session.postFace` or `session.postSelfieVerification` (for selfie-only flows).

### Supporting Types & Options

Below are various supporting types, option builders, and enums provided by the SDK that you might encounter or use when configuring the above components:

#### BoundingBox

Represents the bounding rectangle of a detected ID card in an image.

```
public struct BoundingBox {
    public let box: CGRect?      // The rectangle area of the ID in the image (if detected)
    public let imageSize: CGSize // The full image size to which the box coordinates refer
}
```

You get a `BoundingBox` from `VouchedCameraHelper.observeBoundingBox` or via `CardDetectResult.boundingBox`. It’s useful for drawing guides in your UI.

#### CardDetectResult

The result of an ID detection attempt by `CardDetect` (used to submit an ID image via the session).

```
public struct CardDetectResult {
    public let image: String?        // Base64-encoded ID image (front)
    public let distanceImage: String?// Base64-encoded zoomed-out image (for distance check)
    public let step: Step            // Detection step/status (preDetected, detected, postable)
    public let instruction: Instruction // Suggested user instruction
    public let boundingBox: CGRect?  // Bounding box of ID in the image (if detected)
}
```

Use `CardDetectResult` as input to `session.postFrontId`. The `step` and `instruction` help you manage UI/UX before submission. Only call `postFrontId` when `step == .postable` (i.e., `CardDetectResult` is deemed good enough).

#### FaceDetectResult

The result of a face detection (selfie) attempt by `FaceDetect` (used to submit a selfie via the session).

```
public struct FaceDetectResult {
    public let image: String?         // Base64-encoded face image
    public let distanceImage: String? // Base64-encoded image for liveness (if applicable)
    public let step: Step             // Detection/liveness step (preDetected, detected, postable)
    public let instruction: Instruction // Suggested user instruction for liveness
}
```

Use `FaceDetectResult` with `session.postFace` or `session.postSelfieVerification`. Ensure `step == .postable` to have a quality image with liveness assurance. The `instruction` can be shown to the user if `step` is not yet postable (for example, “Blink your eyes” or other prompts if required by the liveness mode).

#### Params

A struct for optional user parameters that can be sent along with the verification job. This can include personal info and images if you want to provide them manually:

```
struct Params: Codable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var birthDate: String?      // in YYYY-MM-DD or appropriate format
    var properties: [Property]?
    var idPhoto: String?        // If you already have an ID image in Base64 to submit
    var userPhoto: String?      // If you already have a user selfie in Base64
    var idDistancePhoto: String?
    var userDistancePhoto: String?
}
```

Typically, you will get most of these from the detection results. For example, if using `VouchedDetectionManager`, it will handle populating these when calling session methods. However, you can use `Params` to provide additional info like name or contact details to the verification job (some verification flows may use these to cross-check data).

#### CardDetectOptions

Configuration options for `CardDetect`. Use the `CardDetectOptionsBuilder` to construct this:

```
class CardDetectOptionsBuilder {
    public func withEnableDistanceCheck(_ enable: Bool) -> CardDetectOptionsBuilder { ... }
    public func withEnhanceInfoExtraction(_ enhance: Bool) -> CardDetectOptionsBuilder { ... }
    public func build() -> CardDetectOptions { ... }
}
```

- `withEnableDistanceCheck(true)` will have the SDK enforce a proper distance for the ID capture (not too close to the camera). If the ID is too close/far, the `instruction` in `CardDetectResult` will likely prompt the user to adjust.
- `withEnhanceInfoExtraction(true)` (if available in your SDK version) allows the `VouchedDetectionManager` to gather additional info from the ID, such as using the barcode (on US driver’s licenses) or other sources to improve verification. This can increase verification thoroughness by cross-checking data (for example, reading the PDF417 barcode on the back of US IDs).

#### FaceDetectOptions

Configuration options for `FaceDetect`. Built via `FaceDetectOptionsBuilder`:

```
class FaceDetectOptionsBuilder {
    public func withLivenessMode(_ mode: LivenessMode) -> FaceDetectOptionsBuilder { ... }
    public func build() -> FaceDetectOptions { ... }
}
```

- **LivenessMode** could be an enum provided by the SDK (e.g., `.distance`, `.motion`, `.blink`, etc.), controlling what liveness test is used (if any). Use the mode recommended by Vouched for your use case. For example, `.distance` might use 3D depth cues from the front camera, whereas other modes might ask the user to perform an action.

#### RetryableError

An enum that represents certain verification errors that might be fixable by retrying (often related to image quality):

```
enum RetryableError: String {
    case invalidIdPhotoError
    case blurryIdPhotoError
    case glareIdPhotoError
    case invalidUserPhotoError
}
```

After you receive a `Job` result from the API (e.g., from `session.postConfirm` or via detection manager callbacks), you can inspect it for error codes. If you see one of these errors, it means the image had an issue:

- *invalidIdPhotoError*: The ID image wasn’t acceptable (couldn’t read data).
- *blurryIdPhotoError*: The ID was blurry.
- *glareIdPhotoError*: There was glare on the ID.
- *invalidUserPhotoError*: The selfie had an issue (blurry, not a face, etc.).

These hints can be used to prompt the user to retry that part of the process (e.g., “Your ID photo was blurry, please try again”).

#### VouchedCameraMode

An enum specifying the mode for `VouchedCameraHelper`:

```
public enum VouchedCameraMode {
   case id           // ID card/passport capture mode
    case barcode(String, DetectorOptions)  // (Optional) mode to scan a barcode with given format
   case selfie       // Selfie (face) capture mode
}
```

Typically you will use `.id` or `.selfie` with the camera helper. The `.barcode` mode is for scanning barcodes (not covered in detail here, but exists as an option if needed, possibly for QR codes or driver’s license barcodes with a specific detector configuration).

#### VouchedCameraHelperOptions

Options to alter image processing behavior in `VouchedCameraHelper`:

```
public struct VouchedCameraHelperOptions {
    public static var usePhotoCapture: VouchedCameraHelperOptions
    public static var cropIdImage: VouchedCameraHelperOptions
}
```

You can pass an array of these to the helper’s `helperOptions`. For example:

- `.usePhotoCapture` might use still photo capture instead of video frame capture for final image (could result in higher resolution image at the cost of speed).
- `.cropIdImage` might automatically crop the ID image to the document bounds.

Combine these as needed for your scenario. If unsure, you can omit `helperOptions` to use defaults.

#### VouchedDetectionOptions

An enum to specify detection settings for `VouchedCameraHelper` when initializing it:

```
public enum VouchedDetectionOptions {
    case cardDetect(CardDetectOptions)
    case faceDetect(FaceDetectOptions)
}
```

This enum lets you pass in the options for ID or face detection. For instance, in the earlier example we passed `[.cardDetect(CardDetectOptions(...))]` when creating the helper for `.id` mode. If you were setting up a `.selfie` mode camera, you’d use `.faceDetect(faceOptions)` accordingly. These options fine-tune the detection algorithms.

#### CaptureResult

An enum delivered by `VouchedCameraHelper.withCapture` delegate, representing what was detected:

```
public enum CaptureResult {
    case empty                        // No relevant object detected in frame
    case id(DetectionResult)          // An ID document was detected
    case selfie(DetectionResult)      // A face was detected
    case barcode(DetectionResult)     // A barcode was detected
}
```

All cases except `.empty` carry a `DetectionResult` (see below) which can be either a `CardDetectResult` or `FaceDetectResult` (or a similar result type for barcode if used). Check the case in the result to know what you got in that frame and then handle accordingly (update UI or eventually stop capture and submit).

#### DetectionResult

A protocol that unifies detection results (for ID or face). Both `CardDetectResult` and `FaceDetectResult` conform to this:

```
public protocol DetectionResult {
    func params() throws -> Params
}
```

This protocol allows you to get a `Params` object from a detection result via `result.params()`. This can be useful if you want to manually gather all data and send it, but typically you will directly pass the `CardDetectResult` or `FaceDetectResult` to the session methods as shown earlier. The `params()` function might package the images into a `Params` struct for you (throwing an error if something is missing).

## Debugging and Logging

The SDK includes a logger to help with debugging. You can configure the `VouchedLogger` to print out useful information during development. By default, if you do not configure it, the logger is set to no output (`.none`) and only error level.

To enable logging, set the destination and level early in your app (for example, in `AppDelegate` initialization):

```
VouchedLogger.shared.configure(destination: .xcode, level: .debug)
```

**Log Destinations** (where logs are written):

- `.xcode` – Xcode console output (use this when debugging in Xcode).
- `.console` – OS console (via `os_log`, viewable in Console.app).
- `.none` – No logging output.

**Log Levels** (severity to log):

- `.debug` – Verbose logging (includes info and errors). This is useful during development to see everything.
- `.info` – Informational messages and errors.
- `.error` – Only errors.

The levels are inclusive (e.g., setting level to `.debug` will also show `.info` and `.error` messages, and `.info` will show its messages plus errors). For day-to-day debugging, `.debug` with destination `.xcode` is recommended. Be sure to disable or raise the log level in production builds if you do not want verbose logs.

## License

Vouched iOS SDK is available under the Apache License 2.0. See the `LICENSE` file for more information.
