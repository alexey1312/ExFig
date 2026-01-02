import Foundation

/// The target platform for asset export.
///
/// ExFig supports exporting to both iOS (Xcode) and Android (Android Studio) projects.
/// The platform affects naming conventions, output formats, and generated code.
public enum Platform: String, Sendable, CaseIterable {
    /// iOS/iPadOS/macOS platform (Xcode projects).
    /// Generates xcassets, Swift extensions for UIKit and SwiftUI.
    case ios

    /// Android platform (Android Studio projects).
    /// Generates XML resources, vector drawables, and Kotlin code for Jetpack Compose.
    case android

    /// Flutter platform (Flutter projects).
    /// Generates Dart code and SVG/PNG/WebP assets.
    case flutter

    /// Web platform (React/TypeScript projects).
    /// Generates CSS variables, TypeScript constants, and React TSX components.
    case web
}
