import Foundation
import Testing

@testable import ExFigStudio

@Suite("ExFig Studio Tests")
struct ExFigStudioTests {
    @Test("App state initializes correctly")
    @MainActor
    func appStateInitializes() {
        let appState = AppState()

        #expect(!appState.isAuthenticated)
        #expect(appState.figmaAuth == nil)
        #expect(appState.selectedNavItem == .projects)
    }

    @Test("Navigation items have unique IDs")
    func navigationItemsUniqueIds() {
        let ids = NavigationItem.allCases.map(\.id)
        #expect(Set(ids).count == NavigationItem.allCases.count)
    }

    @Test("Navigation items have icons")
    func navigationItemsHaveIcons() {
        for item in NavigationItem.allCases {
            #expect(!item.icon.isEmpty)
        }
    }
}
