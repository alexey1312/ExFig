import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Security
#endif

// MARK: - Keychain Errors

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error, LocalizedError, Sendable {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    case encodingFailed
    case decodingFailed
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            "Item not found in Keychain"
        case .duplicateItem:
            "Item already exists in Keychain"
        case let .unexpectedStatus(status):
            "Keychain error: \(status)"
        case .encodingFailed:
            "Failed to encode data for Keychain"
        case .decodingFailed:
            "Failed to decode data from Keychain"
        case .unsupportedPlatform:
            "Keychain is not supported on this platform"
        }
    }
}

// MARK: - Keychain Storage Protocol

/// Protocol for secure storage operations.
public protocol SecureStorage: Sendable {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data
    func delete(forKey key: String) throws
    func exists(forKey key: String) -> Bool
}

// MARK: - Keychain Storage Implementation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

    /// Secure storage using macOS/iOS Keychain.
    public final class KeychainStorage: SecureStorage, @unchecked Sendable {
        private let service: String
        private let accessGroup: String?
        private let lock = NSLock()

        public init(service: String = "io.exfig.studio", accessGroup: String? = nil) {
            self.service = service
            self.accessGroup = accessGroup
        }

        public func save(_ data: Data, forKey key: String) throws {
            lock.lock()
            defer { lock.unlock() }

            // Try to update existing item first
            let updateQuery = baseQuery(forKey: key)
            let updateAttributes: [String: Any] = [kSecValueData as String: data]

            var status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            if status == errSecItemNotFound {
                // Item doesn't exist, add it
                var addQuery = baseQuery(forKey: key)
                addQuery[kSecValueData as String] = data
                status = SecItemAdd(addQuery as CFDictionary, nil)
            }

            guard status == errSecSuccess else {
                if status == errSecDuplicateItem {
                    throw KeychainError.duplicateItem
                }
                throw KeychainError.unexpectedStatus(status)
            }
        }

        public func load(forKey key: String) throws -> Data {
            lock.lock()
            defer { lock.unlock() }

            var query = baseQuery(forKey: key)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess else {
                if status == errSecItemNotFound {
                    throw KeychainError.itemNotFound
                }
                throw KeychainError.unexpectedStatus(status)
            }

            guard let data = result as? Data else {
                throw KeychainError.decodingFailed
            }

            return data
        }

        public func delete(forKey key: String) throws {
            lock.lock()
            defer { lock.unlock() }

            let query = baseQuery(forKey: key)
            let status = SecItemDelete(query as CFDictionary)

            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.unexpectedStatus(status)
            }
        }

        public func exists(forKey key: String) -> Bool {
            lock.lock()
            defer { lock.unlock() }

            var query = baseQuery(forKey: key)
            query[kSecReturnData as String] = false

            let status = SecItemCopyMatching(query as CFDictionary, nil)
            return status == errSecSuccess
        }

        private func baseQuery(forKey key: String) -> [String: Any] {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]

            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            return query
        }
    }

#else

    /// Fallback storage for Linux (file-based, not secure for production).
    public final class KeychainStorage: SecureStorage, @unchecked Sendable {
        private let storagePath: URL
        private let lock = NSLock()

        public init(service: String = "io.exfig.studio", accessGroup _: String? = nil) {
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            storagePath = cacheDir.appendingPathComponent(service)
            try? FileManager.default.createDirectory(at: storagePath, withIntermediateDirectories: true)
        }

        public func save(_ data: Data, forKey key: String) throws {
            lock.lock()
            defer { lock.unlock() }

            let fileURL = storagePath.appendingPathComponent(key)
            try data.write(to: fileURL)
        }

        public func load(forKey key: String) throws -> Data {
            lock.lock()
            defer { lock.unlock() }

            let fileURL = storagePath.appendingPathComponent(key)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw KeychainError.itemNotFound
            }
            return try Data(contentsOf: fileURL)
        }

        public func delete(forKey key: String) throws {
            lock.lock()
            defer { lock.unlock() }

            let fileURL = storagePath.appendingPathComponent(key)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }

        public func exists(forKey key: String) -> Bool {
            let fileURL = storagePath.appendingPathComponent(key)
            return FileManager.default.fileExists(atPath: fileURL.path)
        }
    }

#endif
