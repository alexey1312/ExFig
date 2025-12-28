import XCTest

/// UI tests for the authentication flow.
/// These tests verify the critical user journey of signing in and signing out.
@MainActor
final class AuthFlowUITests: XCTestCase {
    var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    @MainActor
    override func tearDown() async throws {
        app = nil
    }

    // MARK: - Auth View Tests

    func testAuthViewDisplaysOnLaunch() throws {
        // Verify the auth view is displayed initially
        let headerText = app.staticTexts["ExFig Studio"]
        XCTAssertTrue(headerText.waitForExistence(timeout: 5), "App header should be visible on launch")

        let connectText = app.staticTexts["Connect your Figma account to get started"]
        XCTAssertTrue(connectText.exists, "Connect prompt should be visible")
    }

    func testAuthMethodPickerExists() throws {
        // Verify the segmented picker for auth methods is present
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Auth method picker should exist")

        // Check both segments exist
        let oauthButton = picker.buttons["OAuth"]
        let tokenButton = picker.buttons["Personal Token"]
        XCTAssertTrue(oauthButton.exists, "OAuth option should exist")
        XCTAssertTrue(tokenButton.exists, "Personal Token option should exist")
    }

    func testSwitchToPersonalTokenAuth() throws {
        // Switch to Personal Token tab
        let picker = app.segmentedControls.firstMatch
        guard picker.waitForExistence(timeout: 5) else {
            XCTFail("Auth method picker should exist")
            return
        }

        let tokenButton = picker.buttons["Personal Token"]
        tokenButton.click()

        // Verify Personal Token UI elements appear
        let tokenField = app.secureTextFields.firstMatch
        XCTAssertTrue(tokenField.waitForExistence(timeout: 3), "Token field should appear")

        let connectButton = app.buttons["Connect"]
        XCTAssertTrue(connectButton.exists, "Connect button should exist")
        XCTAssertFalse(connectButton.isEnabled, "Connect button should be disabled when token is empty")
    }

    func testOAuthButtonExists() throws {
        // Verify OAuth sign-in button is present
        let signInButton = app.buttons["Sign in with Figma"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in with Figma button should exist")
    }

    func testPersonalTokenValidation() throws {
        // Switch to Personal Token
        let picker = app.segmentedControls.firstMatch
        guard picker.waitForExistence(timeout: 5) else {
            XCTFail("Auth method picker should exist")
            return
        }

        picker.buttons["Personal Token"].click()

        // Get token field and connect button
        let tokenField = app.secureTextFields.firstMatch
        guard tokenField.waitForExistence(timeout: 3) else {
            XCTFail("Token field should appear")
            return
        }

        let connectButton = app.buttons["Connect"]

        // Initially disabled
        XCTAssertFalse(connectButton.isEnabled, "Connect should be disabled with empty token")

        // Type a token
        tokenField.click()
        tokenField.typeText("figd_test_token_123")

        // Now enabled
        XCTAssertTrue(connectButton.isEnabled, "Connect should be enabled after entering token")
    }

    func testOpenFigmaSettingsLink() throws {
        // Switch to Personal Token
        let picker = app.segmentedControls.firstMatch
        guard picker.waitForExistence(timeout: 5) else {
            XCTFail("Auth method picker should exist")
            return
        }

        picker.buttons["Personal Token"].click()

        // Verify the link to Figma settings exists
        let settingsLink = app.links["Open Figma Settings"]
        XCTAssertTrue(settingsLink.waitForExistence(timeout: 3), "Figma settings link should exist")
    }
}
