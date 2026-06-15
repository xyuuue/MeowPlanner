import Combine
import Foundation
import MeowPlannerCore

enum AccountSessionError: Error, Equatable {
    case authentication(AccountAuthenticationError)
    case remoteAuthentication(message: String)
}

@MainActor
final class AccountSessionStore: ObservableObject {
    static let shared = AccountSessionStore()

    @Published private(set) var currentProfile: AccountProfile?
    @Published private(set) var lastError: AccountSessionError?
    @Published private(set) var lastNotice: String?
    @Published private(set) var isAuthenticating = false

    private static let sessionStorageKey = "meowplanner.account.currentSession"

    private let defaults: UserDefaults
    private let authenticationClient: any AccountAuthenticationClient

    init(
        defaults: UserDefaults = .standard,
        authenticationClient: any AccountAuthenticationClient = FirebaseAccountAuthenticationClient()
    ) {
        self.defaults = defaults
        self.authenticationClient = authenticationClient
        currentProfile = authenticationClient.currentProfile()
        defaults.removeObject(forKey: Self.sessionStorageKey)
    }

    func signInAccount(identifier: String, password: String) {
        authenticate { [self] in
            try await self.authenticationClient.signInAccount(identifier: identifier, password: password)
        }
    }

    func registerAccount(identifier: String, email: String, password: String) {
        authenticate { [self] in
            let profile = try await self.authenticationClient.registerAccount(identifier: identifier, email: email, password: password)
            try? await self.authenticationClient.sendEmailVerification()
            return profile
        }
    }

    func registerEmail(email: String, password: String) {
        authenticate { [self] in
            let profile = try await self.authenticationClient.registerEmail(email: email, password: password)
            try? await self.authenticationClient.sendEmailVerification()
            return profile
        }
    }

    func signInEmail(email: String, password: String) {
        authenticate { [self] in
            try await self.authenticationClient.signInEmail(email: email, password: password)
        }
    }

    func sendEmailVerification() {
        performAccountOperation {
            try await self.authenticationClient.sendEmailVerification()
        }
    }

    func sendPasswordReset(email: String, onSuccess: @escaping @MainActor () -> Void = {}) {
        performAccountOperation({
            try await self.authenticationClient.sendPasswordReset(email: email)
        }, onSuccess: onSuccess)
    }

    func verifyPasswordResetCode(_ code: String, onSuccess: @escaping @MainActor (String) -> Void = { _ in }) {
        performAccountOperation({
            try await self.authenticationClient.verifyPasswordResetCode(code)
        }, onSuccess: onSuccess)
    }

    func confirmPasswordReset(code: String, newPassword: String, confirmPassword: String, onSuccess: @escaping @MainActor () -> Void = {}) {
        performAccountOperation({
            try EmailAddressRules.validatePasswordConfirmation(
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            try await self.authenticationClient.confirmPasswordReset(code: code, newPassword: newPassword)
        }, onSuccess: onSuccess)
    }

    func changePassword(currentPassword: String, newPassword: String) {
        performAccountOperation {
            try await self.authenticationClient.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        }
    }

    func linkEmail(email: String, currentPassword: String) {
        authenticate { [self] in
            try await self.authenticationClient.linkEmail(email: email, currentPassword: currentPassword)
        }
    }

    func linkAccount(identifier: String, currentPassword: String) {
        authenticate { [self] in
            try await self.authenticationClient.linkAccount(identifier: identifier, currentPassword: currentPassword)
        }
    }

    func deleteAccount(currentPassword: String) {
        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        lastError = nil
        lastNotice = nil

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                try await authenticationClient.deleteAccount(currentPassword: currentPassword)
                clearSignedInPresentationState()
            } catch let error as AccountAuthenticationError {
                lastError = .authentication(error)
            } catch let error as AccountSessionError {
                lastError = error
            } catch {
                lastError = .remoteAuthentication(message: error.localizedDescription)
            }
        }
    }

    func signInWeChat() {
        authenticate { [self] in
            try await self.authenticationClient.signInWeChat()
        }
    }

    func signOut() {
        do {
            try authenticationClient.signOut()
            clearSignedInPresentationState()
        } catch {
            lastError = .remoteAuthentication(message: error.localizedDescription)
        }
    }

    private func clearSignedInPresentationState() {
        currentProfile = nil
        lastError = nil
        lastNotice = nil
        defaults.removeObject(forKey: Self.sessionStorageKey)
        FirestoreAppDataSyncService.shared.stopSync()
        AccountScopedModelContainerStore.shared.unload()
        AccountScopedModelContainerStore.shared.prepareSignedOutContainer()
        WidgetTimelineSyncService.clearSnapshotAndReload()
    }

    private func authenticate(_ operation: @escaping () async throws -> AccountProfile) {
        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        lastError = nil
        lastNotice = nil

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                let profile = try await operation()
                currentProfile = profile
                lastError = nil
                lastNotice = nil
                defaults.removeObject(forKey: Self.sessionStorageKey)
            } catch let error as AccountAuthenticationError {
                lastError = .authentication(error)
            } catch let error as AccountSessionError {
                lastError = error
            } catch {
                lastError = .remoteAuthentication(message: error.localizedDescription)
            }
        }
    }

    private func performAccountOperation(
        _ operation: @escaping () async throws -> Void,
        onSuccess: @escaping @MainActor () -> Void = {}
    ) {
        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        lastError = nil
        lastNotice = nil

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                try await operation()
                lastError = nil
                lastNotice = "OK"
                onSuccess()
            } catch let error as AccountAuthenticationError {
                lastError = .authentication(error)
            } catch let error as AccountSessionError {
                lastError = error
            } catch {
                lastError = .remoteAuthentication(message: error.localizedDescription)
            }
        }
    }

    private func performAccountOperation<Value>(
        _ operation: @escaping () async throws -> Value,
        onSuccess: @escaping @MainActor (Value) -> Void
    ) {
        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        lastError = nil
        lastNotice = nil

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                let value = try await operation()
                lastError = nil
                lastNotice = "OK"
                onSuccess(value)
            } catch let error as AccountAuthenticationError {
                lastError = .authentication(error)
            } catch let error as AccountSessionError {
                lastError = error
            } catch {
                lastError = .remoteAuthentication(message: error.localizedDescription)
            }
        }
    }
}
