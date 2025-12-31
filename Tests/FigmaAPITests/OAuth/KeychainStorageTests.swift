import Foundation
import Testing

@testable import FigmaAPI

@Suite("Keychain Storage Tests")
struct KeychainStorageTests {
    let testService = "io.exfig.test.\(UUID().uuidString)"

    @Test("save and load round trip")
    func saveAndLoadRoundTrip() throws {
        let storage = KeychainStorage(service: testService)
        let testData = Data("test-token-data".utf8)
        let key = "test-key-\(UUID().uuidString)"

        try storage.save(testData, forKey: key)
        let loaded = try storage.load(forKey: key)

        #expect(loaded == testData)

        // Cleanup
        try? storage.delete(forKey: key)
    }

    @Test("load throws itemNotFound for missing key")
    func loadThrowsForMissingKey() {
        let storage = KeychainStorage(service: testService)
        let key = "nonexistent-key-\(UUID().uuidString)"

        #expect(throws: KeychainError.itemNotFound) {
            try storage.load(forKey: key)
        }
    }

    @Test("exists returns true for saved item")
    func existsReturnsTrueForSavedItem() throws {
        let storage = KeychainStorage(service: testService)
        let testData = Data("test".utf8)
        let key = "exists-test-\(UUID().uuidString)"

        try storage.save(testData, forKey: key)

        #expect(storage.exists(forKey: key) == true)

        // Cleanup
        try? storage.delete(forKey: key)
    }

    @Test("exists returns false for missing item")
    func existsReturnsFalseForMissingItem() {
        let storage = KeychainStorage(service: testService)
        let key = "missing-\(UUID().uuidString)"

        #expect(storage.exists(forKey: key) == false)
    }

    @Test("delete removes item")
    func deleteRemovesItem() throws {
        let storage = KeychainStorage(service: testService)
        let testData = Data("test".utf8)
        let key = "delete-test-\(UUID().uuidString)"

        try storage.save(testData, forKey: key)
        #expect(storage.exists(forKey: key) == true)

        try storage.delete(forKey: key)
        #expect(storage.exists(forKey: key) == false)
    }

    @Test("delete does not throw for missing item")
    func deleteDoesNotThrowForMissingItem() throws {
        let storage = KeychainStorage(service: testService)
        let key = "never-existed-\(UUID().uuidString)"

        // Should not throw
        try storage.delete(forKey: key)
    }

    @Test("save updates existing item")
    func saveUpdatesExistingItem() throws {
        let storage = KeychainStorage(service: testService)
        let key = "update-test-\(UUID().uuidString)"

        let data1 = Data("first-value".utf8)
        let data2 = Data("second-value".utf8)

        try storage.save(data1, forKey: key)
        try storage.save(data2, forKey: key)

        let loaded = try storage.load(forKey: key)
        #expect(loaded == data2)

        // Cleanup
        try? storage.delete(forKey: key)
    }

    @Test("different keys are isolated")
    func differentKeysAreIsolated() throws {
        let storage = KeychainStorage(service: testService)
        let key1 = "key1-\(UUID().uuidString)"
        let key2 = "key2-\(UUID().uuidString)"

        let data1 = Data("value1".utf8)
        let data2 = Data("value2".utf8)

        try storage.save(data1, forKey: key1)
        try storage.save(data2, forKey: key2)

        #expect(try storage.load(forKey: key1) == data1)
        #expect(try storage.load(forKey: key2) == data2)

        // Cleanup
        try? storage.delete(forKey: key1)
        try? storage.delete(forKey: key2)
    }
}

@Suite("Keychain Error Tests")
struct KeychainErrorTests {
    @Test("errors are equatable")
    func errorsAreEquatable() {
        #expect(KeychainError.itemNotFound == KeychainError.itemNotFound)
        #expect(KeychainError.duplicateItem == KeychainError.duplicateItem)
        #expect(KeychainError.unexpectedStatus(100) == KeychainError.unexpectedStatus(100))
        #expect(KeychainError.unexpectedStatus(100) != KeychainError.unexpectedStatus(200))
        #expect(KeychainError.itemNotFound != KeychainError.duplicateItem)
    }

    @Test("errors have descriptive messages")
    func errorsHaveDescriptiveMessages() {
        #expect(KeychainError.itemNotFound.errorDescription != nil)
        #expect(KeychainError.duplicateItem.errorDescription != nil)
        #expect(KeychainError.unexpectedStatus(-25300).errorDescription != nil)
        #expect(KeychainError.encodingFailed.errorDescription != nil)
        #expect(KeychainError.decodingFailed.errorDescription != nil)
        #expect(KeychainError.unsupportedPlatform.errorDescription != nil)
    }
}
