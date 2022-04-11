import AnnotatoSharedLibrary
import Foundation
import Combine

class AnnotatoAuth {
    private var authService: AnnotatoAuthService
    private let usersPersistenceManager = UsersPersistenceManager()
    private(set) var currentUser: AnnotatoUser?
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var signUpIsSuccess = false
    @Published private(set) var logInIsSuccess = false
    @Published private(set) var signUpError: Error?
    @Published private(set) var logInError: Error?

    init() {
        authService = FirebaseAuth()
        currentUser = fetchLocalUserCredentials()
        setUpSubscribers()
    }

    func signUp(email: String, password: String, displayName: String) {
        authService.signUp(email: email, password: password, displayName: displayName)
    }

    private func createUser(user: AnnotatoUser) {
        Task {
            guard await usersPersistenceManager.createUser(user: user) != nil else {
                return
            }

            self.signUpIsSuccess = true
        }
    }

    func logIn(email: String, password: String) {
        authService.logIn(email: email, password: password)

        storeCredentialsLocally()
    }

    func logOut() {
        authService.logOut()

        purgeLocalCredentials()
    }

    private func setUpSubscribers() {
        authService.newUserPublisher.sink(receiveValue: { [weak self] newUser in
            guard let newUser = newUser else {
                return
            }

            self?.createUser(user: newUser)
        }).store(in: &cancellables)
    }
}

// MARK: Local storage of user credentials
extension AnnotatoAuth {
    private var savedUserKey: String {
        "savedUser"
    }

    private func storeCredentialsLocally() {
        guard let currentUser = currentUser,
              let encodedUser = try? JSONCustomEncoder().encode(currentUser) else {
            return
        }

        UserDefaults.standard.set(encodedUser, forKey: savedUserKey)
    }

    private func fetchLocalUserCredentials() -> AnnotatoUser? {
        guard let savedUser = UserDefaults.standard.object(forKey: savedUserKey) as? Data,
              let decodedUser = try? JSONCustomDecoder().decode(AnnotatoUser.self, from: savedUser) else {
            return nil
        }

        return decodedUser
    }

    private func purgeLocalCredentials() {
        UserDefaults.standard.removeObject(forKey: savedUserKey)
    }
}
