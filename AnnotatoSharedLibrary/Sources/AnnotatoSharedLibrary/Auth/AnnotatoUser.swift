public class AnnotatoUser {
    public let uid: String
    public let email: String
    public let displayName: String

    public init(uid: String, email: String, displayName: String) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
}