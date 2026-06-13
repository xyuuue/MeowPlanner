import MeowPlannerCore
import SwiftUI

enum AccountAuthenticationMode: String, CaseIterable, Identifiable {
    case signIn
    case createAccount
    case forgotPassword
    case changePassword
    case linkAccount
    case deleteAccount

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .signIn:
            PlannerCopy.text(.signInExistingAccount, language: language)
        case .createAccount:
            PlannerCopy.text(.createNewAccount, language: language)
        case .forgotPassword:
            PlannerCopy.text(.forgotPassword, language: language)
        case .changePassword:
            PlannerCopy.text(.changePassword, language: language)
        case .linkAccount:
            PlannerCopy.text(.linkAccount, language: language)
        case .deleteAccount:
            PlannerCopy.text(.deleteAccount, language: language)
        }
    }
}

enum AccountLoginMethod: String, CaseIterable, Identifiable {
    case account
    case email
    case phone
    case wechat

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .account:
            PlannerCopy.text(.accountLogin, language: language)
        case .email:
            PlannerCopy.text(.email, language: language)
        case .phone:
            PlannerCopy.text(.phone, language: language)
        case .wechat:
            PlannerCopy.text(.wechat, language: language)
        }
    }
}

struct AccountAuthenticationModalView: View {
    @ObservedObject var accountStore: AccountSessionStore
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AccountAuthenticationMode
    @State private var loginMethod: AccountLoginMethod = .account
    @State private var accountIdentifier = ""
    @State private var emailAddress = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var verificationCode = ""
    @State private var passwordResetMessage: String?

    init(
        accountStore: AccountSessionStore,
        initialMode: AccountAuthenticationMode = .signIn
    ) {
        self.accountStore = accountStore
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                if mode == .signIn || mode == .createAccount {
                    Section {
                        Picker("", selection: $mode) {
                            Text(AccountAuthenticationMode.signIn.title(language: appLanguage))
                                .tag(AccountAuthenticationMode.signIn)
                            Text(AccountAuthenticationMode.createAccount.title(language: appLanguage))
                                .tag(AccountAuthenticationMode.createAccount)
                        }
                        .fufuSegmentedPickerStyle()
                        .labelsHidden()
                    }
                }

                switch mode {
                case .signIn:
                    signInContent
                case .createAccount:
                    createAccountContent
                case .forgotPassword:
                    forgotPasswordContent
                case .changePassword:
                    changePasswordContent
                case .linkAccount:
                    linkAccountContent
                case .deleteAccount:
                    deleteAccountContent
                }

                accountStatusContent
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding()
            .frame(minWidth: 420, idealWidth: 500, minHeight: 420)
            .background(MeowPlannerTheme.plannerGradient)
            .navigationTitle(mode.title(language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }
            }
            .onChange(of: accountStore.currentProfile?.id) { _, newValue in
                if newValue != nil, mode == .signIn || mode == .createAccount {
                    dismiss()
                }
                if newValue == nil, mode == .deleteAccount {
                    dismiss()
                }
            }
            .onChange(of: accountStore.currentProfile?.accountIdentifier) { _, newValue in
                if newValue != nil, mode == .linkAccount {
                    dismiss()
                }
            }
            .onChange(of: accountStore.lastNotice) { _, newValue in
                if newValue != nil, mode == .changePassword {
                    dismiss()
                }
            }
        }
    }

    private var signInContent: some View {
        Group {
            loginMethodSection

            Section {
                switch loginMethod {
                case .account:
                    accountPasswordFields
                    Button {
                        accountStore.signInAccount(identifier: accountIdentifier, password: password)
                    } label: {
                        Label(PlannerCopy.text(.signIn, language: appLanguage), systemImage: "person.crop.circle")
                    }
                    .disabled(accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || accountStore.isAuthenticating)
                case .email:
                    emailPasswordFields
                    Button {
                        accountStore.signInEmail(email: emailAddress, password: password)
                    } label: {
                        Label(PlannerCopy.text(.signIn, language: appLanguage), systemImage: "envelope.open")
                    }
                    .disabled(emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || accountStore.isAuthenticating)
                case .phone:
                    phoneVerificationFields
                    Button {
                        accountStore.signInPhone(verificationCode: verificationCode)
                    } label: {
                        Label(PlannerCopy.text(.signIn, language: appLanguage), systemImage: "phone")
                    }
                    .disabled(verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || accountStore.isAuthenticating)
                case .wechat:
                    wechatButton
                }

                Button {
                    resetPasswordResetState()
                    loginMethod = .email
                    mode = .forgotPassword
                } label: {
                    Label(PlannerCopy.text(.forgotPassword, language: appLanguage), systemImage: "questionmark.circle")
                }
            }
        }
    }

    private var createAccountContent: some View {
        Group {
            loginMethodSection

            Section {
                switch loginMethod {
                case .account:
                    accountEmailPasswordFields
                    Button {
                        accountStore.registerAccount(
                            identifier: accountIdentifier,
                            email: emailAddress,
                            password: password
                        )
                    } label: {
                        Label(PlannerCopy.text(.createAccount, language: appLanguage), systemImage: "person.badge.plus")
                    }
                    .disabled(
                        accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || password.isEmpty
                            || accountStore.isAuthenticating
                    )

                    Button {
                        accountStore.sendEmailVerification()
                    } label: {
                        Label(PlannerCopy.text(.sendVerificationCode, language: appLanguage), systemImage: "number.circle")
                    }
                    .disabled(accountStore.currentProfile == nil || accountStore.isAuthenticating)
                case .email:
                    emailPasswordFields
                    Button {
                        accountStore.registerEmail(email: emailAddress, password: password)
                    } label: {
                        Label(PlannerCopy.text(.createAccount, language: appLanguage), systemImage: "person.badge.plus")
                    }
                    .disabled(emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || accountStore.isAuthenticating)

                    Button {
                        accountStore.sendEmailVerification()
                    } label: {
                        Label(PlannerCopy.text(.sendVerificationCode, language: appLanguage), systemImage: "number.circle")
                    }
                    .disabled(accountStore.currentProfile == nil || accountStore.isAuthenticating)
                case .phone:
                    phoneVerificationFields
                    Button {
                        accountStore.signInPhone(verificationCode: verificationCode)
                    } label: {
                        Label(PlannerCopy.text(.createAccount, language: appLanguage), systemImage: "phone.badge.plus")
                    }
                    .disabled(verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || accountStore.isAuthenticating)
                case .wechat:
                    wechatButton
                }
            }
        }
    }

    private var forgotPasswordContent: some View {
        Group {
            Section {
                TextField(PlannerCopy.text(.email, language: appLanguage), text: $emailAddress)
                    .textFieldStyle(.roundedBorder)

                Button {
                    let email = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                    accountStore.sendPasswordReset(email: email) {
                        emailAddress = email
                        verificationCode = ""
                        newPassword = ""
                        passwordResetMessage = PlannerCopy.text(.passwordResetLinkSent, language: appLanguage)
                    }
                } label: {
                    Label(PlannerCopy.text(.sendResetLink, language: appLanguage), systemImage: "envelope.badge")
                }
                .disabled(emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || accountStore.isAuthenticating)
            }

            Section {
                Button {
                    resetPasswordResetState()
                    mode = .signIn
                } label: {
                    Label(PlannerCopy.text(.signInExistingAccount, language: appLanguage), systemImage: "arrow.left")
                }
            }
        }
    }

    private var changePasswordContent: some View {
        Section {
            SecureField(PlannerCopy.text(.currentPassword, language: appLanguage), text: $currentPassword)
                .textFieldStyle(.roundedBorder)
            SecureField(PlannerCopy.text(.newPassword, language: appLanguage), text: $newPassword)
                .textFieldStyle(.roundedBorder)

            Button {
                accountStore.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            } label: {
                Label(PlannerCopy.text(.changePassword, language: appLanguage), systemImage: "key")
            }
            .disabled(currentPassword.isEmpty || newPassword.isEmpty || accountStore.isAuthenticating)
        }
    }

    private var linkAccountContent: some View {
        Section {
            TextField(PlannerCopy.text(.accountIdentifier, language: appLanguage), text: $accountIdentifier)
                .textFieldStyle(.roundedBorder)
            SecureField(PlannerCopy.text(.currentPassword, language: appLanguage), text: $currentPassword)
                .textFieldStyle(.roundedBorder)

            Button {
                accountStore.linkAccount(identifier: accountIdentifier, currentPassword: currentPassword)
            } label: {
                Label(PlannerCopy.text(.linkAccount, language: appLanguage), systemImage: "person.crop.circle.badge.plus")
            }
            .disabled(accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || currentPassword.isEmpty || accountStore.isAuthenticating)
        }
    }

    private var deleteAccountContent: some View {
        Section {
            Text(PlannerCopy.text(.deleteAccountWarning, language: appLanguage))
                .font(.caption)
                .foregroundStyle(MeowPlannerTheme.blush)

            SecureField(PlannerCopy.text(.currentPassword, language: appLanguage), text: $currentPassword)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                accountStore.deleteAccount(currentPassword: currentPassword)
            } label: {
                Label(PlannerCopy.text(.deleteAccount, language: appLanguage), systemImage: "trash")
            }
            .disabled(currentPassword.isEmpty || accountStore.isAuthenticating)
        }
    }

    private var loginMethodSection: some View {
        Section {
            Picker(PlannerCopy.text(.provider, language: appLanguage), selection: $loginMethod) {
                ForEach(AccountLoginMethod.allCases) { method in
                    Text(method.title(language: appLanguage)).tag(method)
                }
            }
            .fufuSegmentedPickerStyle()
        }
    }

    private var accountEmailPasswordFields: some View {
        Group {
            TextField(PlannerCopy.text(.accountIdentifier, language: appLanguage), text: $accountIdentifier)
                .textFieldStyle(.roundedBorder)
            TextField(PlannerCopy.text(.email, language: appLanguage), text: $emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField(PlannerCopy.text(.password, language: appLanguage), text: $password)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var accountPasswordFields: some View {
        Group {
            TextField(PlannerCopy.text(.accountIdentifier, language: appLanguage), text: $accountIdentifier)
                .textFieldStyle(.roundedBorder)
            SecureField(PlannerCopy.text(.password, language: appLanguage), text: $password)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var emailPasswordFields: some View {
        Group {
            TextField(PlannerCopy.text(.email, language: appLanguage), text: $emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField(PlannerCopy.text(.password, language: appLanguage), text: $password)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var phoneVerificationFields: some View {
        Group {
            TextField(PlannerCopy.text(.phone, language: appLanguage), text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
            Button {
                accountStore.sendPhoneVerification(phoneNumber: phoneNumber)
            } label: {
                Label(PlannerCopy.text(.sendVerificationCode, language: appLanguage), systemImage: "number.circle")
            }
            .disabled(phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || accountStore.isAuthenticating)
            TextField(PlannerCopy.text(.verificationCode, language: appLanguage), text: $verificationCode)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var wechatButton: some View {
        Button {
            accountStore.signInWeChat()
        } label: {
            Label(PlannerCopy.text(.wechat, language: appLanguage), systemImage: "message")
        }
        .disabled(accountStore.isAuthenticating)
    }

    private var accountStatusContent: some View {
        Section {
            if accountStore.isAuthenticating {
                ProgressView()
                    .controlSize(.small)
            }

            if let passwordResetMessage {
                Text(passwordResetMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastError = accountStore.lastError {
                Text(AccountErrorMessageFormatter.message(for: lastError, language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(MeowPlannerTheme.blush)
            }
        }
    }

    private func resetPasswordResetState() {
        verificationCode = ""
        newPassword = ""
        passwordResetMessage = nil
    }
}
