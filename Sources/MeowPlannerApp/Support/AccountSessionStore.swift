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
            ?? Self.decode(AccountProfile.self, key: Self.sessionStorageKey, defaults: defaults)
    }

    func registerEmail(email: String, password: String) {
        authenticate { [self] in
            try await self.authenticationClient.registerEmail(email: email, password: password)
        }
    }

    func signInEmail(email: String, password: String) {
        authenticate { [self] in
            try await self.authenticationClient.signInEmail(email: email, password: password)
        }
    }

    func signOut() {
        do {
            try authenticationClient.signOut()
            currentProfile = nil
            lastError = nil
            defaults.removeObject(forKey: Self.sessionStorageKey)
            FirestoreAppDataSyncService.shared.stopSync()
        } catch {
            lastError = .remoteAuthentication(message: error.localizedDescription)
        }
    }

    private func authenticate(_ operation: @escaping () async throws -> AccountProfile) {
        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        lastError = nil

        Task { @MainActor in
            defer {
                isAuthenticating = false
            }

            do {
                let profile = try await operation()
                currentProfile = profile
                lastError = nil
                persistCurrentProfile()
            } catch let error as AccountAuthenticationError {
                lastError = .authentication(error)
            } catch let error as AccountSessionError {
                lastError = error
            } catch {
                lastError = .remoteAuthentication(message: error.localizedDescription)
            }
        }
    }

    private func persistCurrentProfile() {
        Self.encode(currentProfile, key: Self.sessionStorageKey, defaults: defaults)
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T, key: String, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        defaults.set(data, forKey: key)
    }
}
