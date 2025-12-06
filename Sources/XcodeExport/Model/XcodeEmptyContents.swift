import Foundation

struct XcodeEmptyContents {
    // swiftlint:disable:next force_unwrapping
    let fileURL = URL(string: "Contents.json")!

    let data = Data("""
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """.utf8)
}
