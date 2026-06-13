import MeowPlannerCore
import SwiftData
import SwiftUI

struct AccountGatedRootView: View {
    let legacyModelContainer: ModelContainer
    @ObservedObject var focusTimerStore: FocusTimerStore
    @StateObject private var accountStore = AccountSessionStore.shared
    @StateObject private var accountContainerStore = AccountScopedModelContainerStore.shared

    var body: some View {
        AccountContainerGate(
            legacyModelContainer: legacyModelContainer,
            accountStore: accountStore,
            accountContainerStore: accountContainerStore
        ) {
            RootView()
                .environmentObject(focusTimerStore)
        }
        .onChange(of: accountStore.currentProfile?.remoteUserID) { _, newValue in
            if newValue == nil {
                focusTimerStore.reset(defaultDurationSeconds: focusTimerStore.durationSeconds)
            }
        }
    }
}

struct AccountGatedSettingsView: View {
    let legacyModelContainer: ModelContainer
    @StateObject private var accountStore = AccountSessionStore.shared
    @StateObject private var accountContainerStore = AccountScopedModelContainerStore.shared

    var body: some View {
        AccountContainerGate(
            legacyModelContainer: legacyModelContainer,
            accountStore: accountStore,
            accountContainerStore: accountContainerStore
        ) {
            SettingsView()
        }
    }
}

private struct AccountContainerGate<Content: View>: View {
    let legacyModelContainer: ModelContainer
    @ObservedObject var accountStore: AccountSessionStore
    @ObservedObject var accountContainerStore: AccountScopedModelContainerStore
    @Environment(\.appLanguage) private var appLanguage
    @ViewBuilder var signedInContent: () -> Content

    var body: some View {
        Group {
            if accountStore.currentProfile == nil,
               let signedOutModelContainer = accountContainerStore.signedOutModelContainer {
                signedInContent()
                    .modelContainer(signedOutModelContainer)
                    .id(accountContainerStore.signedOutWorkspaceID)
            } else if let accountContainer = accountContainerStore.modelContainer,
                      accountContainerStore.activeUserID == accountStore.currentProfile?.remoteUserID {
                signedInContent()
                    .modelContainer(accountContainer)
                    .id(accountContainerStore.activeUserID)
            } else if let loadError = accountContainerStore.loadError {
                accountLoadErrorView(loadError)
            } else {
                accountLoadingView
            }
        }
        .onAppear {
            prepareAccountContainer()
        }
        .onChange(of: accountStore.currentProfile?.remoteUserID) { _, _ in
            prepareAccountContainer()
        }
    }

    private func prepareAccountContainer() {
        if accountStore.currentProfile == nil {
            accountContainerStore.prepareSignedOutContainer()
            return
        }

        accountContainerStore.prepareContainer(
            for: accountStore.currentProfile,
            legacyModelContainer: legacyModelContainer
        )
    }

    private var accountLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text(loadingText)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MeowPlannerTheme.plannerGradient)
    }

    private func accountLoadErrorView(_ error: Error) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(MeowPlannerTheme.blush)
            Text(errorTitle)
                .font(.headline)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                prepareAccountContainer()
            } label: {
                Label(retryTitle, systemImage: "arrow.clockwise")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MeowPlannerTheme.plannerGradient)
    }

    private var loadingText: String {
        switch appLanguage {
        case .english: "Preparing your account workspace..."
        case .chinese: "正在准备你的账号空间..."
        }
    }

    private var errorTitle: String {
        switch appLanguage {
        case .english: "Account workspace could not be opened"
        case .chinese: "无法打开账号空间"
        }
    }

    private var retryTitle: String {
        switch appLanguage {
        case .english: "Try Again"
        case .chinese: "重试"
        }
    }
}
