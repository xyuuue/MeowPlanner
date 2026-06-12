import Foundation
import MeowPlannerCore
import SwiftUI

struct AccountSettingsSection: View {
    @ObservedObject var accountStore: AccountSessionStore
    @Environment(\.appLanguage) private var appLanguage

    @State private var emailAddress = ""
    @State private var password = ""

    var body: some View {
        Section(PlannerCopy.text(.account, language: appLanguage)) {
            if let profile = accountStore.currentProfile {
                signedInContent(profile)
            } else {
                signedOutContent
            }
        }
    }

    private func signedInContent(_ profile: AccountProfile) -> some View {
        Group {
            LabeledContent(PlannerCopy.text(.signedIn, language: appLanguage)) {
                Text(accountName(for: profile))
                    .foregroundStyle(MeowPlannerTheme.cocoa)
            }

            LabeledContent(PlannerCopy.text(.provider, language: appLanguage)) {
                Text(profile.provider.title(language: appLanguage))
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                accountStore.signOut()
                password = ""
            } label: {
                Label(PlannerCopy.text(.signOut, language: appLanguage), systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var signedOutContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                TextField(PlannerCopy.text(.email, language: appLanguage), text: $emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField(PlannerCopy.text(.password, language: appLanguage), text: $password)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 10) {
                    Button {
                        signInEmail()
                    } label: {
                        Label(PlannerCopy.text(.signIn, language: appLanguage), systemImage: "envelope.open")
                    }
                    .disabled(emailFieldsAreIncomplete || accountStore.isAuthenticating)

                    Button {
                        registerEmail()
                    } label: {
                        Label(PlannerCopy.text(.createAccount, language: appLanguage), systemImage: "person.badge.plus")
                    }
                    .disabled(emailFieldsAreIncomplete || accountStore.isAuthenticating)
                }

                if accountStore.isAuthenticating {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let lastError = accountStore.lastError {
                Text(errorMessage(for: lastError))
                    .font(.caption)
                    .foregroundStyle(MeowPlannerTheme.blush)
            }

            LabeledContent(AccountProvider.phone.title(language: appLanguage)) {
                Text(PlannerCopy.text(.phoneComingSoon, language: appLanguage))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(AccountProvider.wechat.title(language: appLanguage)) {
                Text(PlannerCopy.text(.wechatNeedsSetup, language: appLanguage))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func signInEmail() {
        accountStore.signInEmail(email: emailAddress, password: password)
        clearPasswordAfterSuccessfulAuthentication()
    }

    private func registerEmail() {
        accountStore.registerEmail(email: emailAddress, password: password)
        clearPasswordAfterSuccessfulAuthentication()
    }

    private func clearPasswordAfterSuccessfulAuthentication() {
        if accountStore.currentProfile != nil {
            password = ""
        }
    }

    private func accountName(for profile: AccountProfile) -> String {
        if let displayName = profile.displayName, !displayName.isEmpty {
            return displayName
        }
        if let emailAddress = profile.emailAddress, !emailAddress.isEmpty {
            return emailAddress
        }
        return profile.provider.title(language: appLanguage)
    }

    private var emailFieldsAreIncomplete: Bool {
        emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty
    }

    private func errorMessage(for error: AccountSessionError) -> String {
        switch (error, appLanguage) {
        case (.authentication(.invalidEmail), .english):
            "Use a valid email address."
        case (.authentication(.invalidEmail), .chinese):
            "请输入有效邮箱。"
        case (.authentication(.weakPassword(let minimumCharacters)), .english):
            "Use at least \(minimumCharacters) password characters."
        case (.authentication(.weakPassword(let minimumCharacters)), .chinese):
            "密码至少需要 \(minimumCharacters) 个字符。"
        case (.authentication(.accountAlreadyExists), .english):
            "This email already has an account."
        case (.authentication(.accountAlreadyExists), .chinese):
            "这个邮箱已经注册。"
        case (.authentication(.accountNotFound), .english):
            "No account exists for this email."
        case (.authentication(.accountNotFound), .chinese):
            "这个邮箱还没有账号。"
        case (.authentication(.incorrectPassword), .english):
            "The password is incorrect."
        case (.authentication(.incorrectPassword), .chinese):
            "密码不正确。"
        case (.remoteAuthentication(let message), .english) where isFirebaseNetworkError(message):
            "Cannot connect to Firebase. Check your network connection or the app's outgoing network permission."
        case (.remoteAuthentication(let message), .chinese) where isFirebaseNetworkError(message):
            "无法连接 Firebase。请检查网络连接或应用的联网权限。"
        case (.remoteAuthentication(let message), .english):
            "Account sign-in failed: \(message)"
        case (.remoteAuthentication(let message), .chinese):
            "账号登录失败：\(message)"
        }
    }

    private func isFirebaseNetworkError(_ message: String) -> Bool {
        let normalized = message.lowercased()
        return normalized.contains("network error")
            || normalized.contains("unreachable host")
            || normalized.contains("timed out")
            || normalized.contains("interrupted connection")
    }
}
