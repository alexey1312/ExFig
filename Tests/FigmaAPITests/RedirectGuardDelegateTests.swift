@testable import FigmaAPI
import Foundation
#if os(Linux)
    import FoundationNetworking
#endif
import XCTest

/// URLSessionTask.init() is deprecated in macOS 10.15, but is the only way to mock tasks.
@available(macOS, deprecated: 10.15)
final class RedirectGuardDelegateTests: XCTestCase {
    private var delegate: RedirectGuardDelegate!

    override func setUp() {
        super.setUp()
        delegate = RedirectGuardDelegate()
    }

    // MARK: - Same Host

    func testPreservesHeadersOnSameHostRedirect() {
        let expectation = expectation(description: "redirect")
        let original = makeRequest(url: "https://api.figma.com/v1/files/abc", headers: ["X-Figma-Token": "secret"])
        // URLSession copies headers to redirect request; simulate that behavior
        let redirect = makeRequest(
            url: "https://api.figma.com/v1/files/abc/nodes",
            headers: ["X-Figma-Token": "secret"]
        )
        let task = makeMockTask(originalRequest: original)

        delegate.urlSession(
            URLSession.shared,
            task: task,
            willPerformHTTPRedirection: HTTPURLResponse(),
            newRequest: redirect
        ) { resultRequest in
            XCTAssertEqual(resultRequest?.value(forHTTPHeaderField: "X-Figma-Token"), "secret")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Cross Host

    func testStripsHeadersOnCrossHostRedirect() {
        let expectation = expectation(description: "redirect")
        let original = makeRequest(url: "https://api.figma.com/v1/images/abc", headers: ["X-Figma-Token": "secret"])
        let redirect = makeRequest(
            url: "https://s3.amazonaws.com/figma-images/image.png",
            headers: ["X-Figma-Token": "secret"]
        )
        let task = makeMockTask(originalRequest: original)

        delegate.urlSession(
            URLSession.shared,
            task: task,
            willPerformHTTPRedirection: HTTPURLResponse(),
            newRequest: redirect
        ) { resultRequest in
            XCTAssertNil(resultRequest?.value(forHTTPHeaderField: "X-Figma-Token"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Scheme Downgrade

    func testStripsHeadersOnSchemeDowngrade() {
        let expectation = expectation(description: "redirect")
        let original = makeRequest(url: "https://api.figma.com/v1/files/abc", headers: ["Authorization": "Bearer tok"])
        let redirect = makeRequest(
            url: "http://api.figma.com/v1/files/abc",
            headers: ["Authorization": "Bearer tok"]
        )
        let task = makeMockTask(originalRequest: original)

        delegate.urlSession(
            URLSession.shared,
            task: task,
            willPerformHTTPRedirection: HTTPURLResponse(),
            newRequest: redirect
        ) { resultRequest in
            XCTAssertNil(resultRequest?.value(forHTTPHeaderField: "Authorization"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Fail-Closed (nil hosts)

    func testStripsHeadersWhenOriginalHostIsNil() {
        let expectation = expectation(description: "redirect")
        // file URL → nil host
        let original = URLRequest(url: URL(fileURLWithPath: "/local/path"))
        let redirect = makeRequest(
            url: "https://api.figma.com/v1/files/abc",
            headers: ["X-Figma-Token": "secret"]
        )
        let task = makeMockTask(originalRequest: original)

        delegate.urlSession(
            URLSession.shared,
            task: task,
            willPerformHTTPRedirection: HTTPURLResponse(),
            newRequest: redirect
        ) { resultRequest in
            XCTAssertNil(resultRequest?.value(forHTTPHeaderField: "X-Figma-Token"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testStripsHeadersWhenRedirectHostIsNil() {
        let expectation = expectation(description: "redirect")
        let original = makeRequest(url: "https://api.figma.com/v1/files/abc", headers: ["X-Figma-Token": "secret"])
        let redirect = URLRequest(url: URL(fileURLWithPath: "/local/redirect"))
        let task = makeMockTask(originalRequest: original)

        delegate.urlSession(
            URLSession.shared,
            task: task,
            willPerformHTTPRedirection: HTTPURLResponse(),
            newRequest: redirect
        ) { resultRequest in
            XCTAssertNil(resultRequest?.value(forHTTPHeaderField: "X-Figma-Token"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeRequest(url: String, headers: [String: String] = [:]) -> URLRequest {
        // swiftlint:disable:next force_unwrapping
        var request = URLRequest(url: URL(string: url)!)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    private func makeMockTask(originalRequest: URLRequest?) -> URLSessionTask {
        MockURLSessionTask(originalRequest: originalRequest)
    }
}

// MARK: - Mock URLSessionTask

/// Minimal mock that exposes `originalRequest` for redirect guard testing.
private final class MockURLSessionTask: URLSessionTask, @unchecked Sendable {
    private let _originalRequest: URLRequest?

    @available(macOS, deprecated: 10.15)
    init(originalRequest: URLRequest?) {
        _originalRequest = originalRequest
        super.init()
    }

    override var originalRequest: URLRequest? {
        _originalRequest
    }
}
