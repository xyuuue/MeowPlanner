import FirebaseAuth
import FirebaseFirestore
import Foundation
import MeowPlannerCore

@MainActor
protocol AccountAuthenticationClient {
    func currentProfile() -> AccountProfile?
    func signInAccount(identifier: String, password: String) async throws -> AccountProfile
    func registerAccount(identifier: String, email: String, password: String) async throws -> AccountProfile
    func registerEmail(email: String, password: String) async throws -> AccountProfile
    func signInEmail(email: String, password: String) async throws -> AccountProfile
    func linkAccount(identifier: String, currentPassword: String) async throws -> AccountProfile
    func deleteAccount(currentPassword: String) async throws
    func sendEmailVerification() async throws
    func sendPasswordReset(email: String) async throws
    func verifyPasswordResetCode(_ code: String) async throws -> String
    func confirmPasswordReset(code: String, newPassword: String) async throws
    func changePassword(currentPassword: String, newPassword: String) async throws
    func linkEmail(email: String, currentPassword: String) async throws -> AccountProfile
    func signInWeChat() async throws -> AccountProfile
    func signOut() throws
}

struct FirebaseAccountAuthenticationClient: AccountAuthenticationClient {
    private let database = Firestore.firestore()

    func currentProfile() -> AccountProfile? {
        Auth.auth().currentUser.map { Self.profile(from: $0) }
    }

    func signInAccount(identifier: String, password: String) async throws -> AccountProfile {
        if EmailAddressRules.normalizedEmail(identifier) != nil {
            return try await signInEmail(email: identifier, password: password)
        }

        let normalizedIdentifier = try AccountAliasRules.normalizedIdentifier(identifier)
        let emailAddress = try await emailAddress(forAccountAlias: normalizedIdentifier)
        return try await profileFromFirebaseRequest(accountIdentifier: normalizedIdentifier) { completion in
            Auth.auth().signIn(withEmail: emailAddress, password: password, completion: completion)
        }
    }

    func registerAccount(identifier: String, email: String, password: String) async throws -> AccountProfile {
        let normalizedIdentifier = try AccountAliasRules.normalizedIdentifier(identifier)
        let emailAddress = try AccountAliasRules.emailAddressForAccountRegistration(
            identifier: normalizedIdentifier,
            email: email
        )
        try EmailAddressRules.validatePassword(password)
        try await ensureAccountAliasAvailable(identifier: normalizedIdentifier, userID: nil)

        _ = try await profileFromFirebaseRequest(accountIdentifier: normalizedIdentifier) { completion in
            Auth.auth().createUser(withEmail: emailAddress, password: password, completion: completion)
        }

        guard let user = Auth.auth().currentUser else {
            throw AccountAuthenticationError.accountNotFound
        }
        try await storeAccountAlias(identifier: normalizedIdentifier, user: user)
        try await updateDisplayName(normalizedIdentifier, for: user)
        return Self.profile(from: user, accountIdentifier: normalizedIdentifier)
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

    func linkAccount(identifier: String, currentPassword: String) async throws -> AccountProfile {
        let normalizedIdentifier = try AccountAliasRules.normalizedIdentifier(identifier)
        guard let user = Auth.auth().currentUser else {
            throw AccountAuthenticationError.accountNotFound
        }

        try await reauthenticate(with: currentPassword, user: user)
        try await ensureAccountAliasAvailable(identifier: normalizedIdentifier, userID: user.uid)
        try await storeAccountAlias(identifier: normalizedIdentifier, user: user)
        try await updateDisplayName(normalizedIdentifier, for: user)
        return Self.profile(from: user, accountIdentifier: normalizedIdentifier)
    }

    func deleteAccount(currentPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AccountAuthenticationError.accountNotFound
        }

        try await reauthenticate(with: currentPassword, user: user)
        try await deleteCloudPlannerData(userID: user.uid)
        try await deleteAccountAliases(userID: user.uid)
        try await deleteDocument(database.document("users/\(user.uid)"))
        try await deleteFirebaseUser(user)
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AccountAuthenticationError.accountNotFound
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.sendEmailVerification { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func verifyPasswordResetCode(_ code: String) async throws -> String {
        let resetCode = try PasswordResetCodeRules.normalizedCode(from: code)
        do {
            return try await Auth.auth().verifyPasswordResetCode(resetCode)
        } catch {
            throw Self.mappedError(error)
        }
    }

    func confirmPasswordReset(code: String, newPassword: String) async throws {
        let resetCode = try PasswordResetCodeRules.normalizedCode(from: code)
        try EmailAddressRules.validatePassword(newPassword)
        do {
            try await Auth.auth().confirmPasswordReset(withCode: resetCode, newPassword: newPassword)
        } catch {
            throw Self.mappedError(error)
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try EmailAddressRules.validatePassword(newPassword)
        guard let user = Auth.auth().currentUser else {
            throw AccountAuthenticationError.accountNotFound
        }

        try await reauthenticate(with: currentPassword, user: user)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.updatePassword(to: newPassword) { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func linkEmail(email: String, currentPassword: String) async throws -> AccountProfile {
        guard let normalizedEmail = EmailAddressRules.normalizedEmail(email),
              !AccountAliasRules.isInternalEmailAddress(normalizedEmail)
        else {
            throw AccountAuthenticationError.invalidEmail
        }
        guard let user = Auth.auth().currentUser else {
            throw AccountAuthenticationError.accountNotFound
        }

        try await reauthenticate(with: currentPassword, user: user)
        try await updateEmail(normalizedEmail, for: user)
        try? await sendEmailVerification(for: user)
        try await reload(user)
        return Self.profile(from: user)
    }

    func signInWeChat() async throws -> AccountProfile {
        throw AccountAuthenticationError.providerUnavailable
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    private func profileFromFirebaseRequest(
        accountIdentifier: String? = nil,
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

                continuation.resume(returning: Self.profile(from: user, accountIdentifier: accountIdentifier))
            }
        }
    }

    private var accountAliases: CollectionReference {
        database.collection("accountAliases")
    }

    private func emailAddress(forAccountAlias identifier: String) async throws -> String {
        let snapshot = try await accountAliases.document(identifier).getDocument()
        guard snapshot.exists,
              let rawEmailAddress = snapshot.data()?["emailAddress"] as? String,
              let emailAddress = EmailAddressRules.normalizedEmail(rawEmailAddress)
        else {
            throw AccountAuthenticationError.accountNotFound
        }
        return emailAddress
    }

    private func ensureAccountAliasAvailable(identifier: String, userID: String?) async throws {
        let snapshot = try await accountAliases.document(identifier).getDocument()
        guard snapshot.exists else {
            return
        }

        if let userID,
           snapshot.data()?["userID"] as? String == userID
        {
            return
        }

        throw AccountAuthenticationError.accountAlreadyExists
    }

    private func storeAccountAlias(identifier: String, user: User) async throws {
        guard let emailAddress = EmailAddressRules.normalizedEmail(user.email ?? "") else {
            throw AccountAuthenticationError.invalidEmail
        }

        try await setData([
            "identifier": identifier,
            "emailAddress": emailAddress,
            "userID": user.uid,
            "createdAt": Date(),
            "updatedAt": Date()
        ], merge: true, for: accountAliases.document(identifier))
    }

    private func updateDisplayName(_ displayName: String, for user: User) async throws {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            changeRequest.commitChanges { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func reauthenticate(with currentPassword: String, user: User) async throws {
        guard let emailAddress = EmailAddressRules.normalizedEmail(user.email ?? "") else {
            throw AccountAuthenticationError.invalidEmail
        }

        let credential = EmailAuthProvider.credential(withEmail: emailAddress, password: currentPassword)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func updateEmail(_ email: String, for user: User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.updateEmail(to: email) { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func sendEmailVerification(for user: User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.sendEmailVerification { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func reload(_ user: User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().currentUser?.reload { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteCloudPlannerData(userID: String) async throws {
        for collection in CloudDataCollection.allCases {
            let collectionPath = try collection.collectionPath(userID: userID)
            let snapshot = try await database.collection(collectionPath).getDocuments()
            for document in snapshot.documents {
                try await deleteDocument(document.reference)
            }
        }
    }

    private func deleteAccountAliases(userID: String) async throws {
        let snapshot = try await accountAliases.whereField("userID", isEqualTo: userID).getDocuments()
        for document in snapshot.documents {
            try await deleteDocument(document.reference)
        }
    }

    private func setData(_ data: [String: Any], merge: Bool, for document: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteDocument(_ document: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteFirebaseUser(_ user: User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.delete { error in
                if let error {
                    continuation.resume(throwing: Self.mappedError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private static func profile(from user: User, accountIdentifier: String? = nil) -> AccountProfile {
        let accountIdentifier = accountIdentifier ?? user.displayName
        return AccountProfile.firebaseEmail(
            userID: user.uid,
            emailAddress: AccountAliasRules.isInternalEmailAddress(user.email) ? nil : user.email,
            displayName: user.displayName,
            accountIdentifier: accountIdentifier
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
        case .invalidVerificationCode, .missingVerificationCode, .sessionExpired, .invalidActionCode, .expiredActionCode:
            return AccountAuthenticationError.missingVerificationCode
        case .requiresRecentLogin:
            return AccountSessionError.remoteAuthentication(message: "Please sign in again before changing your password.")
        case .operationNotAllowed:
            return AccountAuthenticationError.providerUnavailable
        default:
            return AccountSessionError.remoteAuthentication(message: nsError.localizedDescription)
        }
    }
}
