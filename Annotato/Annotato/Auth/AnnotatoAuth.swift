import AnnotatoSharedLibrary

class AnnotatoAuth {
    private var authService: AnnotatoAuthService

    init() {
        authService = FirebaseAuth()
    }

    var currentUser: AnnotatoUser? {
        authService.currentUser
    }

    var delegate: AnnotatoAuthDelegate? {
        get { authService.delegate }
        set { authService.delegate = newValue }
    }

    func signUp(email: String, password: String, displayName: String) {
        authService.signUp(email: email, password: password, displayName: displayName)
    }

    func logIn(email: String, password: String) {
        authService.logIn(email: email, password: password)
    }
}