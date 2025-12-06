import Foundation

/// The target platform for asset export.
///
/// ExFig supports exporting to both iOS (Xcode) and Android (Android Studio) projects.
/// The platform affects naming conventions, output formats, and generated code.
public enum Platform: String, Sendable {
    /// iOS/iPadOS/macOS platform (Xcode projects).
    /// Generates xcassets, Swift extensions for UIKit and SwiftUI.
    case ios

    /// Android platform (Android Studio projects).
    /// Generates XML resources, vector drawables, and Kotlin code for Jetpack Compose.
    case android
}
