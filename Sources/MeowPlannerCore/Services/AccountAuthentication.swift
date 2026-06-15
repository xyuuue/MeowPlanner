import CryptoKit
import Foundation

public enum AccountProvider: String, CaseIterable, Codable, Identifiable, Sendable {
    case apple
    case email
    case wechat

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch (self, language) {
        case (.apple, .english): "Apple"
        case (.apple, .chinese): "Apple"
        case (.email, .english): "Email"
        case (.email, .chinese): "邮箱"
        case (.wechat, .english): "WeChat"
        case (.wechat, .chinese): "微信"
        }
    }
}

public struct AccountProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var provider: AccountProvider
    public var remoteUserID: String?
    public var emailAddress: String?
    public var accountIdentifier: String?
    public var displayName: String?
    public var createdAt: Date
    public var lastSignedInAt: Date

    public init(
        id: String,
        provider: AccountProvider,
        remoteUserID: String? = nil,
        emailAddress: String?,
        accountIdentifier: String? = nil,
        displayName: String?,
        createdAt: Date,
        lastSignedInAt: Date
    ) {
        self.id = id
        self.provider = provider
        self.remoteUserID = remoteUserID
        self.emailAddress = emailAddress
        self.accountIdentifier = Self.normalizedOptionalAccountIdentifier(accountIdentifier)
        self.displayName = displayName
        self.createdAt = createdAt
        self.lastSignedInAt = lastSignedInAt
    }

    public static func apple(
        userIdentifier: String,
        emailAddress: String?,
        displayName: String?,
        now: Date = Date()
    ) -> AccountProfile {
        AccountProfile(
            id: "apple:\(userIdentifier)",
            provider: .apple,
            emailAddress: normalizedOptionalEmail(emailAddress),
            displayName: normalizedOptionalDisplayName(displayName),
            createdAt: now,
            lastSignedInAt: now
        )
    }

    static func email(
        id: String,
        emailAddress: String,
        displayName: String,
        createdAt: Date,
        lastSignedInAt: Date
    ) -> AccountProfile {
        AccountProfile(
            id: id,
            provider: .email,
            emailAddress: emailAddress,
            displayName: displayName,
            createdAt: createdAt,
            lastSignedInAt: lastSignedInAt
        )
    }

    public static func firebaseEmail(
        userID: String,
        emailAddress: String?,
        displayName: String?,
        accountIdentifier: String? = nil,
        now: Date = Date()
    ) -> AccountProfile {
        AccountProfile(
            id: "firebase:\(userID)",
            provider: .email,
            remoteUserID: userID,
            emailAddress: normalizedOptionalEmail(emailAddress),
            accountIdentifier: accountIdentifier,
            displayName: normalizedOptionalDisplayName(displayName),
            createdAt: now,
            lastSignedInAt: now
        )
    }

    private static func normalizedOptionalEmail(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        return EmailAddressRules.normalizedEmail(value)
    }

    private static func normalizedOptionalDisplayName(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return nil
        }
        return trimmed
    }

    private static func normalizedOptionalAccountIdentifier(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        return try? AccountAliasRules.normalizedIdentifier(value)
    }
}

public enum AccountAuthenticationError: Error, Equatable, Sendable {
    case invalidEmail
    case invalidAccountIdentifier
    case weakPassword(minimumCharacters: Int)
    case accountAlreadyExists
    case accountNotFound
    case incorrectPassword
    case missingVerificationCode
    case passwordConfirmationMismatch
    case providerUnavailable
}

public enum AccountAliasRules {
    public static let minimumIdentifierCharacters = 3
    public static let maximumIdentifierCharacters = 32
    public static let internalEmailDomain = "accounts.meowplanner.local"

    public static func normalizedIdentifier(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumIdentifierCharacters,
              trimmed.count <= maximumIdentifierCharacters
        else {
            throw AccountAuthenticationError.invalidAccountIdentifier
        }

        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-")
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw AccountAuthenticationError.invalidAccountIdentifier
        }

        return trimmed.lowercased()
    }

    public static func isInternalEmailAddress(_ value: String?) -> Bool {
        guard let normalizedEmail = value.flatMap(EmailAddressRules.normalizedEmail) else {
            return false
        }
        return normalizedEmail.hasSuffix("@\(internalEmailDomain)")
    }

    public static func emailAddressForAccountRegistration(identifier: String, email: String) throws -> String {
        _ = try normalizedIdentifier(identifier)
        guard let normalizedEmail = EmailAddressRules.normalizedEmail(email),
              !isInternalEmailAddress(normalizedEmail)
        else {
            throw AccountAuthenticationError.invalidEmail
        }
        return normalizedEmail
    }
}

public enum EmailAddressRules {
    public static let minimumPasswordCharacters = 8

    public static func normalizedEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(where: { $0.isWhitespace }) else {
            return nil
        }

        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let local = parts.first,
              let domain = parts.last,
              !local.isEmpty,
              domain.contains("."),
              domain.first != ".",
              domain.last != "."
        else {
            return nil
        }

        return trimmed.lowercased()
    }

    static func displayName(from email: String) -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let localPart = trimmed.split(separator: "@", omittingEmptySubsequences: false).first,
              !localPart.isEmpty
        else {
            return "Email"
        }
        return String(localPart)
    }

    public static func validatePassword(_ password: String) throws {
        guard password.count >= minimumPasswordCharacters else {
            throw AccountAuthenticationError.weakPassword(minimumCharacters: minimumPasswordCharacters)
        }
    }

    public static func validatePasswordConfirmation(newPassword: String, confirmPassword: String) throws {
        try validatePassword(newPassword)
        guard newPassword == confirmPassword else {
            throw AccountAuthenticationError.passwordConfirmationMismatch
        }
    }
}

public enum PasswordResetCodeRules {
    public static func normalizedCode(from value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AccountAuthenticationError.missingVerificationCode
        }

        if let components = URLComponents(string: trimmed),
           let code = components.queryItems?.first(where: { $0.name == "oobCode" })?.value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !code.isEmpty
        {
            return code
        }

        return trimmed
    }
}

public struct EmailAccountCredential: Codable, Equatable, Sendable {
    public var accountID: String
    public var normalizedEmail: String
    public var displayName: String
    public var saltHex: String
    public var passwordDigestHex: String
    public var createdAt: Date
    public var lastSignedInAt: Date

    public init(
        accountID: String,
        normalizedEmail: String,
        displayName: String,
        saltHex: String,
        passwordDigestHex: String,
        createdAt: Date,
        lastSignedInAt: Date
    ) {
        self.accountID = accountID
        self.normalizedEmail = normalizedEmail
        self.displayName = displayName
        self.saltHex = saltHex
        self.passwordDigestHex = passwordDigestHex
        self.createdAt = createdAt
        self.lastSignedInAt = lastSignedInAt
    }

    func matches(password: String) -> Bool {
        passwordDigestHex == Self.digest(password: password, saltHex: saltHex)
    }

    func profile(lastSignedInAt: Date) -> AccountProfile {
        AccountProfile.email(
            id: accountID,
            emailAddress: normalizedEmail,
            displayName: displayName,
            createdAt: createdAt,
            lastSignedInAt: lastSignedInAt
        )
    }

    func updatingLastSignedIn(at date: Date) -> EmailAccountCredential {
        var copy = self
        copy.lastSignedInAt = date
        return copy
    }

    static func make(email: String, password: String, now: Date) throws -> EmailAccountCredential {
        guard let normalizedEmail = EmailAddressRules.normalizedEmail(email) else {
            throw AccountAuthenticationError.invalidEmail
        }
        try EmailAddressRules.validatePassword(password)

        let saltHex = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return EmailAccountCredential(
            accountID: "email:\(normalizedEmail)",
            normalizedEmail: normalizedEmail,
            displayName: EmailAddressRules.displayName(from: email),
            saltHex: saltHex,
            passwordDigestHex: digest(password: password, saltHex: saltHex),
            createdAt: now,
            lastSignedInAt: now
        )
    }

    private static func digest(password: String, saltHex: String) -> String {
        let input = Data("\(saltHex):\(password)".utf8)
        return SHA256.hash(data: input).map { String(format: "%02x", $0) }.joined()
    }
}

public struct EmailAccountAuthenticator: Sendable {
    private var credentialsByEmail: [String: EmailAccountCredential]

    public init(credentials: [EmailAccountCredential] = []) {
        credentialsByEmail = Dictionary(uniqueKeysWithValues: credentials.map { ($0.normalizedEmail, $0) })
    }

    public func exportedCredentials() -> [EmailAccountCredential] {
        credentialsByEmail.values.sorted { $0.normalizedEmail < $1.normalizedEmail }
    }

    public mutating func register(
        email: String,
        password: String,
        now: Date = Date()
    ) throws -> AccountProfile {
        guard let normalizedEmail = EmailAddressRules.normalizedEmail(email) else {
            throw AccountAuthenticationError.invalidEmail
        }
        guard credentialsByEmail[normalizedEmail] == nil else {
            throw AccountAuthenticationError.accountAlreadyExists
        }

        let credential = try EmailAccountCredential.make(email: email, password: password, now: now)
        credentialsByEmail[normalizedEmail] = credential
        return credential.profile(lastSignedInAt: now)
    }

    public mutating func signIn(
        email: String,
        password: String,
        now: Date = Date()
    ) throws -> AccountProfile {
        guard let normalizedEmail = EmailAddressRules.normalizedEmail(email) else {
            throw AccountAuthenticationError.invalidEmail
        }
        guard let credential = credentialsByEmail[normalizedEmail] else {
            throw AccountAuthenticationError.accountNotFound
        }
        guard credential.matches(password: password) else {
            throw AccountAuthenticationError.incorrectPassword
        }

        let updated = credential.updatingLastSignedIn(at: now)
        credentialsByEmail[normalizedEmail] = updated
        return updated.profile(lastSignedInAt: now)
    }
}
