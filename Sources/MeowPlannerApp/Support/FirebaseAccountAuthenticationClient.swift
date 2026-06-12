import FirebaseAuth
import Foundation
import MeowPlannerCore

@MainActor
protocol AccountAuthenticationClient {
    func currentProfile() -> AccountProfile?
    func registerEmail(email: String, password: String) async throws -> AccountProfile
    func signInEmail(email: String, password: String) async throws -> AccountProfile
    func signOut() throws
}

struct FirebaseAccountAuthenticationClient: AccountAuthenticationClient {
    func currentProfile() -> AccountProfile? {
        Auth.auth().currentUser.map(Self.profile)
    }

    func registerEmail(email: String, password: String) async throws -> AccountProfile {
        try await profileFromFirebaseRequest { completion in
            Auth.auth().createUser(withEmail: email, password: password, completion: completion)
        }
    }

    func signInEmail(email: String, password: String) async throws -> AccountProfile {
        try await profileFromFirebaseRequest { completion in
            Auth.auth().signIn(withEmail: email, password: password, completion: completion)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    private func profileFromFirebaseRequest(
        _ request: (@escaping (AuthDataResult?, Error?) -> Void) -> Void
    ) async throws -> AccountProfile {
        try await withCheckedThrowingContinuation { continuation in
            request { result, error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: AccountSessionError.remoteAuthentication(message: "Firebase did not return a user."))
                    return
                }

                continuation.resume(returning: Self.profile(from: user))
            }
        }
    }

    private static func profile(from user: User) -> AccountProfile {
        AccountProfile.firebaseEmail(
            userID: user.uid,
            emailAddress: user.email,
            displayName: user.displayName
        )
    }

    private static func mappedError(_ error: Error) -> Error {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code)
        else {
            return AccountSessionError.remoteAuthentication(message: error.localizedDescription)
        }

        switch code {
        case .invalidEmail:
            return AccountAuthenticationError.invalidEmail
        case .emailAlreadyInUse:
            return AccountAuthenticationError.accountAlreadyExists
        case .weakPassword:
            return AccountAuthenticationError.weakPassword(minimumCharacters: EmailAddressRules.minimumPasswordCharacters)
        case .userNotFound:
            return AccountAuthenticationError.accountNotFound
        case .wrongPassword, .invalidCredential:
            return AccountAuthenticationError.incorrectPassword
        default:
            return AccountSessionError.remoteAuthentication(message: nsError.localizedDescription)
        }
    }
}
