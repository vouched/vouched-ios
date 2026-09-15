import Foundation
@_exported import VouchedCore

/// Main entry point for the Vouched SDK.
///
/// The SDK initializes itself automatically when a verification flow starts;
/// no explicit initialization call is required.
public struct Vouched {
    private init() {}

    /// Registers Swift-side view factories with the KMP core.
    /// Assignments are idempotent; called whenever a flow view is constructed.
    static func registerNativeComponents() {
        ScanditContainerFactory.shared.factory = { config in
            ScanditContainerUIView(config: config)
        }
        AWSLivenessContainerFactory.shared.factory = { config in
            LivenessContainerUIView(config: config)
        }
    }

    /// Updates the user's tracking consent after initialization.
    ///
    /// Call this when the user grants or revokes consent in your app's privacy settings.
    public static func setTrackingConsent(_ granted: Bool) {
        VouchedCore.Vouched.shared.setTrackingConsent(granted: granted)
    }
}
