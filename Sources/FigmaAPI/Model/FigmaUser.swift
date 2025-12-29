import Foundation

/// Represents the current authenticated Figma user.
/// Returned from the `/v1/me` endpoint.
public struct FigmaUser: Codable, Sendable, Equatable {
    /// The unique identifier of the user.
    public let id: String

    /// The user's handle (username).
    public let handle: String

    /// URL to the user's profile image.
    public let imgUrl: String

    /// The user's email address.
    /// Only available if `current_user:read` scope is granted.
    public let email: String?

    public init(id: String, handle: String, imgUrl: String, email: String?) {
        self.id = id
        self.handle = handle
        self.imgUrl = imgUrl
        self.email = email
    }
}
