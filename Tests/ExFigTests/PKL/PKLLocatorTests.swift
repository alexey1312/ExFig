@testable import ExFigCLI
import Foundation
import Testing

@Suite("PKLLocator Tests")
struct PKLLocatorTests {
    @Test("Finds pkl via mise installs or Homebrew or PATH")
    func findsPkl() throws {
        let locator = PKLLocator()

        // This test assumes pkl is installed via mise, Homebrew, or is in PATH
        let pklPath = try locator.findPKL()

        #expect(pklPath.path.contains("pkl"))
        #expect(FileManager.default.fileExists(atPath: pklPath.path))
    }

    @Test("Found pkl is executable")
    func foundPklIsExecutable() throws {
        let locator = PKLLocator()

        let pklPath = try locator.findPKL()

        // Should find pkl somewhere
        #expect(FileManager.default.isExecutableFile(atPath: pklPath.path))
    }

    @Test("Throws NotFound when pkl is not installed")
    func throwsNotFoundWhenMissing() throws {
        // Create locator that won't find pkl
        let locator = PKLLocator(
            miseShimsPath: "/nonexistent/path",
            pathEnvironment: "/nonexistent/bin"
        )

        #expect(throws: PKLError.self) {
            try locator.findPKL()
        }
    }

    @Test("Returns cached path on subsequent calls")
    func returnsCachedPath() throws {
        let locator = PKLLocator()

        let firstPath = try locator.findPKL()
        let secondPath = try locator.findPKL()

        #expect(firstPath == secondPath)
    }
}
