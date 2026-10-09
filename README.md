# Vouched iOS SDK

Identity verification SDK for iOS. Drop-in flow that handles document capture, face capture with liveness, and submission to the Vouched backend.

## Prerequisites

- A [Vouched account](https://app.vouched.id) with an active API key. If you don't have one, contact your Vouched representative.
- *Optional, for enhanced ID capture:* enhanced document detection reads documents faster and more reliably than the classic pipeline, and is licensed per application. To enable it, give your Vouched representative the bundle identifier of every app that will run the SDK, including build variants (for example `com.example.myapp` and `com.example.myapp.staging`).

  Until it is enabled, document capture runs the classic pipeline instead. Capture still works, and no code change is needed on your side once enhanced capture is turned on.

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 5.9+
- An Apple Developer account (free tier works for local development)
- A Vouched API key (contact your Vouched representative)

## Features

- Document capture (front, back, and full ID) with automatic detection
- Face capture with liveness verification
- Drop-in SwiftUI view that drives the entire verification flow end to end
- Customizable terminal screens (success, cancelled, error)
- Optional custom instruction screens before ID and face stages

## Installation

Add the package via **File → Add Package Dependencies** in Xcode:

```
https://github.com/vouched/vouched-ios
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vouched/vouched-ios", from: "2.0.1")
]
```

## Permissions

Add the camera usage description to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to capture your ID and take a selfie for identity verification.</string>
```

## Required Info.plist Entry

The SDK's capture screens require your app to opt in to full-speed rendering on iPhone. Without this key, the app crashes on launch as soon as a Vouched screen is presented:

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

## Quick Start

### 1. Present the verification flow

`VouchedFlowView` drives the full flow. Provide an `AppConfig` with your API key and chain modifiers to register terminal screens:

```swift
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

### 2. (Optional) Custom instruction screens

Show your own SwiftUI screens before the ID and face capture stages:

```swift
VouchedFlowView(config: config)
    .withIdStageInstructionsScreen { onContinue in
        IdInstructionsScreen(onContinue: onContinue)
    }
    .withFaceStageInstructionsScreen { onContinue in
        FaceInstructionsScreen(onContinue: onContinue)
    }
```

### 3. (Optional) Observe stage transitions

```swift
VouchedFlowView(config: config)
    .onStageChange { from, to in
        print("Stage: \(from) → \(to)")
    }
```

### 4. (Optional) Enable analytics tracking

We recommend enabling anonymous analytics. It lets Vouched diagnose verification failures in your integration, which is the fastest path to a resolution when you raise a support ticket:

```swift
VouchedFlowView(config: config)
    .trackingConsent(true)
```

## Sample App

This repository ships a working sample app under `Example/` that demonstrates the full integration above.

### Configure signing

1. Open `Example/VouchedSample.xcodeproj` in Xcode.
2. Select the `VouchedSample` target → **Signing & Capabilities**.
3. Choose your Apple Developer team from the dropdown.

### Provide an API key

The sample reads its API key from `Example/VouchedSample/Secrets.swift`, which is gitignored.

1. Copy the template:
   ```bash
   cp Example/VouchedSample/Secrets.swift.template Example/VouchedSample/Secrets.swift
   ```
2. Open `Secrets.swift` and replace `VOUCHED_API_KEY_PLACEHOLDER` with your Vouched API key.

### Run

Build and run on a physical iOS device. Camera access is required for ID and face capture; the simulator does not provide a real camera.

## Advanced Configuration

### Flow types

`AppConfig.type` selects which stages the flow runs:

| Type | Stages |
|---|---|
| `.id` | Document capture only |
| `.idv` | Document capture and face capture |
| `.reverify` | Face capture only, matched against a previous job (re-verification) |
| `.selfieVerification` | Face capture only |

### Document Capture Options

```swift
let config = AppConfig(
    type: .idv,
    sessionParams: .init(apiKey: "YOUR_VOUCHED_API_KEY"),
    documentCaptureConfig: DocumentCaptureConfig(
        detectionMode: .enhancedWithFallback,
        includeBackId: true,
        classicDocumentDetectionOptions: .init(
            enableDistanceCheck: true,
            captureMethod: .both,
            tuning: .init(
                timeoutMs: 30000,
                holdSteadyDurationMs: 1000
            )
        ),
        includeBarcodeScanning: true,
        options: .init(
            userImageConfirmation: true,
            cardIDThreshold: 0.8
        )
    )
)
```

`DocumentCaptureConfig`:

| Field | Default | Description |
|---|---|---|
| `detectionMode` | `.enhancedWithFallback` | Which detection pipeline runs. `.enhancedWithFallback` uses enhanced detection and falls back to classic when it is unavailable. `.classicOnly` uses platform-native detection (Vision framework). |
| `includeBackId` | `false` | Capture the back of the ID in addition to the front. |
| `classicDocumentDetectionOptions` | see below | Options that apply to the classic pipeline. |
| `includeBarcodeScanning` | `false` | Scan the PDF417 barcode on the back of driver's licenses. Only relevant when `includeBackId` is `true`. |
| `options` | see below | Capture-result acceptance options. |

#### `classicDocumentDetectionOptions`

`enableDistanceCheck` applies only to the classic pipeline, and only when it actually runs: either because `.enhancedWithFallback` fell back to it, or because `detectionMode` is `.classicOnly`. `captureMethod` and `tuning.timeoutMs` apply in both modes: `captureMethod` decides whether the third-party pipeline runs at all, and `timeoutMs` drives the enhanced-detection fallback timer.

| Field | Default | Description |
|---|---|---|
| `enableDistanceCheck` | `false` | Run the distance challenge (hold the ID farther away, then move closer) before the final capture, and send a `distanceImage` alongside the ID result. Front ID only. |
| `captureMethod` | `.camera` | How the user provides the image. See the capture methods table below. |
| `tuning` | see below | Capture timing. |

#### `tuning`

| Field | Default | Description |
|---|---|---|
| `timeoutMs` | `30000` | How long the capture session runs before it fails with a timeout. Must be positive; set it to `nil` for no timeout. |
| `holdSteadyDurationMs` | `1000` | How long the user must hold steady before auto-capture triggers. Must be positive. Raising it reduces motion blur at the cost of a slower capture. |

#### `options`

| Field | Default | Description |
|---|---|---|
| `userImageConfirmation` | `false` | Show a confirmation screen after capture so the user can accept or retake the image. When `false`, capture proceeds immediately. |
| `cardIDThreshold` | `0.0` | Minimum ID confidence, from 0.0 to 1.0, that the backend must report before the flow advances. Below it, the stage returns to retry. The default of `0.0` disables the gate. |

#### Capture methods

| Value | Behavior |
|---|---|
| `.camera` | Live camera capture only. |
| `.upload` | Gallery upload only. The camera is never started; the capture screen shows just the upload button. |
| `.both` | Live camera capture with an additional upload-from-gallery button. |

Uploaded images are posted directly and skip on-device detection. The gallery uses the system photo picker, so `.upload` and `.both` need no additional `Info.plist` permission.

### Face Capture Options

```swift
let config = AppConfig(
    type: .idv,
    sessionParams: .init(apiKey: "YOUR_VOUCHED_API_KEY"),
    faceCaptureConfig: FaceCaptureConfig(
        timeoutMs: 30000,
        detectionMode: .enhancedWithFallback,
        livenessMode: .straight,
        selfieThreshold: 0.8,
        captureMethod: .camera
    )
)
```

| Field | Default | Description |
|---|---|---|
| `timeoutMs` | `30000` | How long the capture session runs before the user is offered a manual photo. Must be positive; set it to `nil` for no timeout. |
| `detectionMode` | `.classicOnly` | Which pipeline runs. `.enhancedWithFallback` uses enhanced liveness detection and falls back to classic on failure. `.classicOnly` uses platform-native detection (Vision framework). |
| `livenessMode` | `.straight` | The classic liveness challenge: `.straight`, `.mouthMovement`, `.distance`, or `.orientation`. Ignored when enhanced liveness succeeds. |
| `selfieThreshold` | `0.0` | Minimum selfie confidence, from 0.0 to 1.0, that the backend must report before the flow advances. Below it, the stage returns to retry. The default of `0.0` disables the gate. |
| `captureMethod` | `.camera` | How the user provides the selfie, using the same values as document capture. |

## Versioning

This SDK follows Semantic Versioning. Each tagged release on this repository corresponds to one published XCFramework, hosted as a GitHub Release asset and pinned in `Package.swift` with a SHA-256 checksum.

## Support

- Documentation: https://docs.vouched.id
- Contact: support@vouched.id

## License

Apache 2.0. See [LICENSE](LICENSE) for details.

## Migrating from v1

If you were using the CocoaPods-based v1 SDK, see [MIGRATION.md](MIGRATION.md) for a full breakdown of what changed and how to upgrade.

## Legacy SDK

Looking for the v1.x SDK? See the [v1.11.0 README](https://github.com/vouched/vouched-ios/blob/v1.11.0/README.md).
