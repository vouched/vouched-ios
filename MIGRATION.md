# Migrating from SDK v1 to v2

SDK v2 is a full rewrite. The API surface, distribution method, and minimum OS version have all changed.

## What changed

| | v1 | v2 |
|---|---|---|
| Distribution | CocoaPods | Swift Package Manager |
| Language | Objective-C / Swift | Swift (KMP core) |
| Integration | Manual camera + session management | Drop-in `VouchedFlowView` |
| Minimum iOS | 16.0 | 17.0 |

## Installation

Remove the CocoaPods dependency and add the SPM package instead:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/vouched/vouched-ios", from: "2.0.0")
]
```

Or via **File → Add Package Dependencies** in Xcode:

```
https://github.com/vouched/vouched-ios
```

## API changes

v1 required you to manage the camera session, detection, and API calls manually:

```swift
// v1
let session = VouchedSession(apiKey: "YOUR_KEY")
let helper = VouchedCameraHelper(with: .id, ...) { result in
    let job = try session.postFrontId(detectedCard: result)
    ...
}
```

v2 replaces this with a single drop-in view:

```swift
// v2
import Vouched

VouchedFlowView(config: AppConfig(
    type: .idv,
    sessionParams: .init(apiKey: "YOUR_KEY")
))
```

The SDK owns the camera, detection, retries, and every call to the Vouched backend. There is no session to construct, no per-stage posting, and no explicit initialization step.

> **Note:** v2 also defines a type named `VouchedSession`, but it is not the v1 session. It is an internal handle the flow manages for you, and it takes an `AppConfig` rather than an API key. Migrating code should not construct one.

### Where v1 concepts went

| v1 | v2 |
|---|---|
| `VouchedSession` plus manual `postFrontId` / `postFace` calls | Handled internally by `VouchedFlowView` |
| `VouchedCameraHelper` and camera lifecycle management | Handled internally by `VouchedFlowView` |
| Per-stage completion callbacks | `.successScreen`, `.cancelledScreen`, and `.errorScreen` modifiers |
| Custom capture screens | `.withIdStageInstructionsScreen` and `.withFaceStageInstructionsScreen` modifiers |
| Detection and capture tuning parameters | `documentCaptureConfig` and `faceCaptureConfig` on `AppConfig` |

See the [README](README.md) for the full v2 quick start, and [Advanced Configuration](README.md#advanced-configuration) for the capture options that replace v1's tuning parameters.

## Legacy SDK

v1 remains available via CocoaPods at version `1.11.0`. The v1 source, example app, and documentation are preserved at the [v1.11.0 tag](https://github.com/vouched/vouched-ios/tree/v1.11.0).

The v1 example app is also available locally under `Example/v1/`.
