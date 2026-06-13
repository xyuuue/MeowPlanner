import Foundation
import MeowPlannerCore
import SwiftUI

struct AccountSettingsSection: View {
    @ObservedObject var accountStore: AccountSessionStore
    @Environment(\.appLanguage) private var appLanguage

    @State private var showingAuthenticationModal = false

    var body: some View {
        Section(PlannerCopy.text(.account, language: appLanguage)) {
            if let profile = accountStore.currentProfile {
                signedInContent(profile)
            } else {
                signedOutContent
            }
        }
        .sheet(isPresented: $showingAuthenticationModal) {
            AccountAuthenticationModalView(
                accountStore: accountStore,
                initialMode: .signIn
            )
        }
    }

    private func signedInContent(_ profile: AccountProfile) -> some View {
        Group {
            LabeledContent(PlannerCopy.text(.signedIn, language: appLanguage)) {
                Text(accountName(for: profile))
                    .foregroundStyle(MeowPlannerTheme.cocoa)
            }

            if let accountIdentifier = profile.accountIdentifier, !accountIdentifier.isEmpty {
                LabeledContent(PlannerCopy.text(.accountIdentifier, language: appLanguage)) {
                    Text(accountIdentifier)
                        .foregroundStyle(.secondary)
                }
            }

            if let emailAddress = profile.emailAddress, !emailAddress.isEmpty {
                LabeledContent(PlannerCopy.text(.email, language: appLanguage)) {
                    Text(emailAddress)
                        .foregroundStyle(.secondary)
                }
            }

            if let phoneNumber = profile.phoneNumber, !phoneNumber.isEmpty {
                LabeledContent(PlannerCopy.text(.phone, language: appLanguage)) {
                    Text(phoneNumber)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var signedOutContent: some View {
        Group {
            Button {
                showingAuthenticationModal = true
            } label: {
                Label(PlannerCopy.text(.loginButton, language: appLanguage), systemImage: "person.crop.circle")
            }

            if let lastError = accountStore.lastError {
                Text(AccountErrorMessageFormatter.message(for: lastError, language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(MeowPlannerTheme.blush)
            }
        }
    }

    private func accountName(for profile: AccountProfile) -> String {
        if let accountIdentifier = profile.accountIdentifier, !accountIdentifier.isEmpty {
            return accountIdentifier
        }
        if let displayName = profile.displayName, !displayName.isEmpty {
            return displayName
        }
        if let emailAddress = profile.emailAddress, !emailAddress.isEmpty {
            return emailAddress
        }
        return profile.provider.title(language: appLanguage)
    }
}

enum AccountErrorMessageFormatter {
    static func message(for error: AccountSessionError, language: AppLanguage) -> String {
        switch (error, language) {
        case (.authentication(.invalidEmail), .english):
            "Use a valid email address."
        case (.authentication(.invalidEmail), .chinese):
            "请输入有效邮箱。"
        case (.authentication(.invalidAccountIdentifier), .english):
            "Use 3-32 letters, numbers, underscores, dots, or hyphens for the account name."
        case (.authentication(.invalidAccountIdentifier), .chinese):
            "账号名需要 3-32 位，只能包含字母、数字、下划线、点或连字符。"
        case (.authentication(.invalidPhoneNumber), .english):
            "Use an international phone number, such as +1..."
        case (.authentication(.invalidPhoneNumber), .chinese):
            "请输入带国家区号的手机号，例如 +1..."
        case (.authentication(.weakPassword(let minimumCharacters)), .english):
            "Use at least \(minimumCharacters) password characters."
        case (.authentication(.weakPassword(let minimumCharacters)), .chinese):
            "密码至少需要 \(minimumCharacters) 个字符。"
        case (.authentication(.accountAlreadyExists), .english):
            "This account already exists."
        case (.authentication(.accountAlreadyExists), .chinese):
            "这个账号已经注册。"
        case (.authentication(.accountNotFound), .english):
            "No account exists for this sign-in."
        case (.authentication(.accountNotFound), .chinese):
            "这个登录方式还没有账号。"
        case (.authentication(.incorrectPassword), .english):
            "The password is incorrect."
        case (.authentication(.incorrectPassword), .chinese):
            "密码不正确。"
        case (.authentication(.missingVerificationCode), .english):
            "Send and enter the verification code first."
        case (.authentication(.missingVerificationCode), .chinese):
            "请先发送并输入验证码。"
        case (.authentication(.passwordConfirmationMismatch), .english):
            PlannerCopy.text(.passwordConfirmationMismatch, language: .english)
        case (.authentication(.passwordConfirmationMismatch), .chinese):
            PlannerCopy.text(.passwordConfirmationMismatch, language: .chinese)
        case (.authentication(.providerUnavailable), .english):
            "This sign-in method needs platform setup before it can be used."
        case (.authentication(.providerUnavailable), .chinese):
            "这个登录方式需要完成平台配置后才能使用。"
        case (.remoteAuthentication(let message), .english) where isFirebaseNetworkError(message):
            "Cannot connect to Firebase. Check your network connection or the app's outgoing network permission."
        case (.remoteAuthentication(let message), .chinese) where isFirebaseNetworkError(message):
            "无法连接 Firebase。请检查网络连接或应用的联网权限。"
        case (.remoteAuthentication(let message), .english):
            "Account action failed: \(message)"
        case (.remoteAuthentication(let message), .chinese):
            "账号操作失败：\(message)"
        }
    }

    private static func isFirebaseNetworkError(_ message: String) -> Bool {
        let normalized = message.lowercased()
        return normalized.contains("network error")
            || normalized.contains("unreachable host")
            || normalized.contains("timed out")
            || normalized.contains("interrupted connection")
    }
}
