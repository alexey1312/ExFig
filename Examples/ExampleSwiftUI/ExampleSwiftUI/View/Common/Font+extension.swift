//
//  The code generated using ExFig — Command line utility to export
//  colors, typography, icons and images from Figma to Xcode project.
//
//  https://github.com/alexey1312/ExFig
//
//  Don’t edit this code manually to avoid runtime crashes
//

import SwiftUI

public extension Font {
    static func body() -> Font {
        if #available(iOS 14.0, *) {
            Font.custom("PTSans-Regular", size: 16.0, relativeTo: .body)
        } else {
            Font.custom("PTSans-Regular", size: 16.0)
        }
    }

    static func caption() -> Font {
        if #available(iOS 14.0, *) {
            Font.custom("PTSans-Regular", size: 14.0, relativeTo: .footnote)
        } else {
            Font.custom("PTSans-Regular", size: 14.0)
        }
    }

    static func header() -> Font {
        Font.custom("PTSans-Bold", size: 20.0)
    }

    static func largeTitle() -> Font {
        if #available(iOS 14.0, *) {
            Font.custom("PTSans-Bold", size: 34.0, relativeTo: .largeTitle)
        } else {
            Font.custom("PTSans-Bold", size: 34.0)
        }
    }

    static func uppercased() -> Font {
        Font.custom("PTSans-Regular", size: 14.0).lowercaseSmallCaps()
    }
}
