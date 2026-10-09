# Migrating from SDK v1 to v2

SDK v2 is a full rewrite. The API surface, distribution method, and minimum OS version have all changed. This guide walks a current v1 customer through the steps to upgrade.

If you are integrating Vouched for the first time, skip this page and go straight to the [README](README.md).

## What changed

| | v1 | v2 |
|---|---|---|
| Distribution | CocoaPods | Swift Package Manager |
| Language | Objective-C / Swift | Swift |
| Integration | Manual camera + session management | Drop-in `VouchedFlowView` |
| UI toolkit | UIKit views you host yourself | SwiftUI flow driven by the SDK |
| Minimum iOS | 16.0 | 17.0 |

## Step 1 — Switch from CocoaPods to Swift Package Manager

Remove the v1 pod from your `Podfile` and run `pod install` to clean up:

```ruby
# REMOVE from your Podfile
pod 'Vouched', '1.11.0'
```

Add the v2 package via **File → Add Package Dependencies** in Xcode:

```
https://github.com/vouched/vouched-ios
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vouched/vouched-ios", from: "2.0.1")
]
```

## Step 2 — Update your Info.plist

Keep the camera usage description v1 required, and add the entry v2's capture screens need. Without `CADisableMinimumFrameDurationOnPhone`, the app crashes on launch as soon as a Vouched screen is presented:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to capture your ID and take a selfie for identity verification.</string>
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

## Step 3 — Replace the manual capture flow with `VouchedFlowView`

In v1 you constructed a `VouchedCameraHelper` against a UIView you hosted, and posted each stage to the backend yourself through a `VouchedSession`:

```swift
// v1 — you drove every step
// The group id is not a session argument: it lives on VouchedSessionParameters.
let session = VouchedSession(apiKey: "PUBLIC_KEY",
                             sessionParameters: VouchedSessionParameters(groupId: "GROUP_ID"),
                             apiUrl: nil)

let helper = VouchedCameraHelper(with: .id,
                                 detectionOptions: [.cardDetect(CardDetectOptionsBuilder().withEnableDistanceCheck(true).build())],
                                 in: previewContainer)?
    .withCapture(delegate: { result in
        switch result {
        case .id(let detectedCard):
            // You decided when and what to post:
            _ = try? session.postFrontId(detectedCard: detectedCard, details: nil)
        default:
            break
        }
    })

helper?.startCapture()
// ...then postFace(...), postConfirm(), handling the returned Job at every step
```

In v2 the SDK owns the camera, detection, mode transitions, retries, and every call to the Vouched backend. You configure the flow and render one SwiftUI view:

```swift
// v2 — the SDK drives the flow
import SwiftUI
import Vouched

struct VerificationView: View {
    private let config = AppConfig(
        type: .idv,
        sessionParams: .init(apiKey: "YOUR_VOUCHED_API_KEY")
    )

    var body: some View {
        VouchedFlowView(config: config)
            .successScreen { job in
                Text("Verification complete: \(job.id)")
            }
            .cancelledScreen { reason in
                Text("Cancelled: \(reason ?? "user cancelled")")
            }
            .errorScreen { error, retry in
                VStack {
                    Text("Error: \(error.localizedDescription)")
                    Button("Retry", action: retry)
                }
            }
    }
}
```

There is no `VouchedCameraHelper` to construct, no `startCapture()` / `stopCapture()` lifecycle, no per-stage posting, and no explicit initialization step — the SDK initializes itself and validates your API key when the flow starts.

> **Note:** v2 also defines a type named `VouchedSession`, but it is not the v1 session. It is an internal handle the flow manages for you, and it takes an `AppConfig` rather than an API key. Migrating code should not construct one.

### SwiftUI requirement

`VouchedFlowView` is a SwiftUI view. If your app is UIKit-based, host it in a `UIHostingController`:

```swift
let controller = UIHostingController(rootView: VerificationView())
navigationController?.pushViewController(controller, animated: true)
```

## Step 4 — Map your v1 options to v2 configuration

v1 spread its options across `VouchedCameraHelperOptions`, `CardDetectOptionsBuilder`, `FaceDetectOptionsBuilder`, and the `VouchedDetectionManager`. v2 consolidates them into two config objects on `AppConfig`: `documentCaptureConfig` and `faceCaptureConfig`.

| v1 | v2 |
|---|---|
| `VouchedCameraMode.id` / `.barcode` | `type: .id` + `DocumentCaptureConfig(includeBackId:includeBarcodeScanning:)` |
| `VouchedCameraMode.selfie` | `type: .idv`, `.selfieVerification`, or `.reverify` |
| `CardDetectOptionsBuilder().withEnableDistanceCheck(...)` | `classicDocumentDetectionOptions.enableDistanceCheck` |
| `CardDetectOptionsBuilder().withEnhanceInfoExtraction(true)` + `VouchedDetectionManager` mode changes | No direct equivalent. In v1 it enabled PDF417 barcode reading during classic front-ID detection. In v2, `includeBarcodeScanning: true` reads the PDF417 — on the front with the `.enhancedWithFallback` pipeline (single-side scan), on the back with the classic pipeline (it implies a back capture). The `.enhancedWithFallback` pipeline (`detectionMode: .enhancedWithFallback`, the default) is a new, separate detection; with `includeBackId: true` its full-document scanner reads every zone on both sides, including a front barcode when the document carries one — no `VouchedDetectionManagerCallbacks` wiring |
| `VouchedCameraHelperOptions.usePhotoCapture` | `captureMethod: .upload` or `.both` (gallery capture) |
| `VouchedCameraHelperOptions.cropIdImage` | Handled by the v2 capture UX; no direct flag |
| `FaceDetectOptionsBuilder().withLivenessMode(.distance)` | `FaceCaptureConfig(livenessMode: .distance)` |
| `Params` / `VouchedValidationParamSettings` | `JobParams` on `AppConfig` |
| `session.postFrontId` / `postFace` / `postConfirm` | Handled internally by `VouchedFlowView` |
| `session.postReverify(jobId:matchId:userPhoto:)` (`matchId` defaults to `"selfie"`) | `type: .reverify` |
| `session.postSelfieVerification(detectedFace:)` | `type: .selfieVerification` |
| `VouchedSession(apiKey:sessionParameters:apiUrl:)` with the group id on `VouchedSessionParameters(groupId:)` | `SessionParams(apiKey:accountGroupSid:)` |
| `VouchedSessionParameters(token:)` | Not needed — the flow manages the job token |
| `RetryableError` | `.errorScreen { error, retry in }` |
| `observeBoundingBox` / `BoundingBox` | Handled internally by the capture UI |
| `VouchedLogger` | No public equivalent in v2 |

v2 also adds the liveness challenges `.straight` (the default) and `.orientation`.

### Example: v1 setup and its v2 equivalent

v1:

```swift
let session = VouchedSession(apiKey: "PUBLIC_KEY",
                             sessionParameters: VouchedSessionParameters(groupId: "GROUP_ID"),
                             apiUrl: nil)
let helper = VouchedCameraHelper(with: .id,
                                 detectionOptions: [
                                     .cardDetect(CardDetectOptionsBuilder()
                                         .withEnableDistanceCheck(true)
                                         .withEnhanceInfoExtraction(true)
                                         .build())
                                 ],
                                 in: previewContainer)
// The face stage used FaceDetectOptionsBuilder().withLivenessMode(.distance)
```

v2:

```swift
let config = AppConfig(
    type: .idv,
    sessionParams: .init(apiKey: "YOUR_VOUCHED_API_KEY"),
    jobParams: JobParams(firstName: "Jane", lastName: "Doe"),   // replaces Params
    documentCaptureConfig: DocumentCaptureConfig(
        // .enhancedWithFallback is a new, separate detection that may read
        // the barcode on the front depending on the document being detected
        detectionMode: .enhancedWithFallback,
        classicDocumentDetectionOptions: .init(
            enableDistanceCheck: true,                           // replaces withEnableDistanceCheck
            captureMethod: .both,
            tuning: .init(timeoutMs: 30000)
        ),
        // withEnhanceInfoExtraction has no direct equivalent: in v1 it read the PDF417 barcode
        // on the front during classic detection. v2's classic pipeline never reads the barcode
        // on the front; includeBarcodeScanning reads it on the back capture instead.
        includeBarcodeScanning: true
    ),
    faceCaptureConfig: FaceCaptureConfig(
        timeoutMs: 30000,
        livenessMode: .distance                                  // replaces withLivenessMode
    )
)
```

## Step 5 — Move result handling to the terminal screens

In v1 you handled a `Job` after every post and inspected errors yourself:

```swift
// v1
do {
    let job = try session.postFrontId(detectedCard: detectedCard, details: details)
    // business and navigation logic based on Job data
} catch {
    // handle app/network/system errors
}

// or, with the detection manager:
callbacks.detectionComplete = { result in
    switch result {
    case .success(let job): print("\(job)")
    case .failure(let err): print("Error: \(err)")
    }
}
```

In v2 there are three terminal screens, and the success screen receives the full verification result:

```swift
// v2
VouchedFlowView(config: config)
    .onStageChange { from, to in
        print("Stage: \(from) → \(to)")   // replaces VouchedCameraMode bookkeeping
    }
    .successScreen { job in
        Text("Job id: \(job.id)")
        // job.result exposes success, parsed ID fields, and confidences
    }
    .cancelledScreen { reason in
        Text("Cancelled: \(reason ?? "user cancelled")")
    }
    .errorScreen { error, retry in
        // Replaces RetryableError handling; `retry` restarts the failed stage
        Button("Retry", action: retry)
    }
```

## Step 6 — (Optional) restore v1 customizations

**Custom instruction screens.** In v1 you built your own pre-capture screens and navigation. In v2, inject SwiftUI screens before the ID and face stages:

```swift
VouchedFlowView(config: config)
    .withIdStageInstructionsScreen { onContinue in
        IdInstructionsScreen(onContinue: onContinue)
    }
    .withFaceStageInstructionsScreen { onContinue in
        FaceInstructionsScreen(onContinue: onContinue)
    }
```

**Analytics consent.** v2 can send anonymous analytics that help Vouched diagnose verification failures in your integration:

```swift
VouchedFlowView(config: config)
    .trackingConsent(true)
```

## Where v1 concepts went

| v1 | v2 |
|---|---|
| `VouchedSession` plus manual `postFrontId` / `postFace` / `postConfirm` calls | Handled internally by `VouchedFlowView` |
| `VouchedCameraHelper` and camera lifecycle management (`startCapture` / `stopCapture`) | Handled internally by `VouchedFlowView` |
| `VouchedDetectionManager` and `VouchedDetectionManagerCallbacks` | Automatic — driven by `AppConfig.type`, your `DocumentCaptureConfig` flags (`includeBackId`, `includeBarcodeScanning`), and backend job results |
| `CardDetect` / `FaceDetect` | Internal detection pipelines (`documentCaptureConfig.detectionMode`, `faceCaptureConfig.detectionMode`) |
| Per-stage completion callbacks | `.successScreen`, `.cancelledScreen`, and `.errorScreen` modifiers |
| Custom capture screens | `.withIdStageInstructionsScreen` and `.withFaceStageInstructionsScreen` modifiers |
| Detection and capture tuning parameters | `documentCaptureConfig` and `faceCaptureConfig` on `AppConfig` |
| `Params` / `VouchedValidationParamSettings` | `JobParams` on `AppConfig` |
| `VouchedSession(apiKey:sessionParameters:apiUrl:)` with the group id on `VouchedSessionParameters(groupId:)` | `SessionParams(apiKey:accountGroupSid:)` |
| `VouchedSessionParameters(token:)` | Not needed — the flow manages the job token; re-verification uses `type: .reverify` |
| `RetryableError` | `.errorScreen { error, retry in }` |

See the [README](README.md) for the full v2 quick start, and [Advanced Configuration](README.md#advanced-configuration) for the capture options that replace v1's tuning parameters.

## Behavior changes to be aware of

- **Minimum iOS 17 and Xcode 16.** If your app supports older iOS versions, you must raise your deployment target or stay on v1.
- **SwiftUI.** v2 renders its own SwiftUI flow; UIKit apps host it in a `UIHostingController`.
- **Enhanced detection is licensed per bundle identifier.** Enhanced document/face detection is faster and more reliable than the classic pipeline, and is enabled per app by Vouched. Give your Vouched representative the bundle identifier of every app that ships, including build variants (for example `com.example.myapp` and `com.example.myapp.staging`). Until it is enabled, capture runs the classic pipeline — no code change is needed on your side once it is turned on.
- **Barcode scanning is built in.** v1 exposed a `.barcode` camera mode you had to drive yourself. In v2, set `includeBarcodeScanning: true` on `DocumentCaptureConfig` and the PDF417 barcode is read as part of the back capture.
- **Timeouts degrade gracefully.** When a capture timeout expires, v2 offers the user a manual photo instead of failing the stage.
- **Gallery uploads skip on-device detection.** With `captureMethod: .upload` or `.both`, uploaded images are posted directly, and the system photo picker needs no extra `Info.plist` permission.

## Upgrade checklist

- [ ] Remove the `Vouched` pod and add the SPM package from `https://github.com/vouched/vouched-ios`
- [ ] Add `CADisableMinimumFrameDurationOnPhone` to your `Info.plist` (and keep `NSCameraUsageDescription`)
- [ ] Replace `VouchedCameraHelper` + per-stage posting with `AppConfig` + `VouchedFlowView`
- [ ] Map capture options to `documentCaptureConfig` / `faceCaptureConfig`
- [ ] Move `Job` handling into `.successScreen` / `.cancelledScreen` / `.errorScreen`
- [ ] (Optional) Re-add custom instruction screens, `.onStageChange`, and `.trackingConsent`
- [ ] Register every bundle identifier with Vouched to enable enhanced detection
- [ ] Test the full verification flow on a physical device

## Legacy SDK

v1 remains available via CocoaPods at version `1.11.0`. The v1 source, example app, and documentation are preserved at the [v1.11.0 tag](https://github.com/vouched/vouched-ios/tree/v1.11.0).

The v1 example app is also available locally under `Example/v1/`.
