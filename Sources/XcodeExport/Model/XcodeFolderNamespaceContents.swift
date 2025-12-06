import Foundation

struct XcodeFolderNamespaceContents {
    // swiftlint:disable:next force_unwrapping
    let fileURL = URL(string: "Contents.json")!

    let data = Data("""
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      },
      "properties" : {
        "provides-namespace" : true
      }
    }

    """.utf8)
}
