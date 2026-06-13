import Foundation
import Testing

@Suite("Xcode widget project structure")
struct XcodeWidgetProjectTests {
    @Test("macOS app project embeds the WidgetKit extension")
    func macOSAppProjectEmbedsWidgetExtension() throws {
        let root = try packageRoot()
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        #expect(FileManager.default.fileExists(atPath: projectFile.path))

        let project = try String(contentsOf: projectFile, encoding: .utf8)
        #expect(project.contains("MeowPlannerWidgetExtension.appex"))
        #expect(project.contains("com.apple.product-type.app-extension"))
        #expect(project.contains("dstSubfolderSpec = 13"))
        #expect(project.contains("Config/MeowPlannerWidget-Info.plist"))
    }

    @Test("macOS app declares a menu bar extra")
    func macOSAppDeclaresMenuBarExtra() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let menuBarFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)

        #expect(appSource.contains("MenuBarExtra"))
        #expect(appSource.contains("MeowPlannerMenuBarView"))
        #expect(FileManager.default.fileExists(atPath: menuBarFile.path))
        #expect(project.contains("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift"))
    }

    @Test("today widget supports large desktop sizes")
    func todayWidgetSupportsLargeDesktopSizes() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)

        #expect(widgetSource.contains(".systemLarge"))
        #expect(widgetSource.contains(".systemExtraLarge"))
        #expect(widgetSource.contains(".configurationDisplayName(\"MeowPlanner\")"))
    }

    @Test("run script installs latest build into Applications")
    func runScriptInstallsLatestBuildIntoApplications() throws {
        let root = try packageRoot()
        let scriptFile = root
            .appendingPathComponent("script/build_and_run.sh")

        let script = try String(contentsOf: scriptFile, encoding: .utf8)

        #expect(script.contains("INSTALL_BUNDLE=\"/Applications/$APP_NAME.app\""))
        #expect(script.contains("SIGNING_MODE=\"${SIGNING_MODE:-auto}\""))
        #expect(script.contains("detect_development_team()"))
        #expect(script.contains("Apple Development:"))
        #expect(script.contains("security find-certificate -c \"$identity_name\" -p"))
        #expect(script.contains("USE_SIGNED_BUILD=1"))
        #expect(script.contains("verify_installable_app()"))
        #expect(script.contains("Signature=adhoc"))
        #expect(script.contains("TeamIdentifier=not set"))
        #expect(script.contains("Cannot install $APP_NAME without a non-ad-hoc Apple signature"))
        #expect(script.contains("keychain-access-groups"))
        #expect(script.contains("verify_installable_app \"$APP_BUNDLE\""))
        #expect(script.contains("Cannot install $APP_NAME without keychain-access-groups"))
        #expect(script.contains("install_app()"))
        #expect(script.contains("rm -rf \"$INSTALL_BUNDLE\""))
        #expect(script.contains("/usr/bin/ditto \"$APP_BUNDLE\" \"$INSTALL_BUNDLE\""))
        #expect(script.contains("refresh_widget_registration()"))
        #expect(script.contains("WIDGET_BUNDLE=\"$INSTALL_BUNDLE/Contents/PlugIns/MeowPlannerWidgetExtension.appex\""))
        #expect(script.contains("pkill -f \"$INSTALL_BUNDLE/Contents/PlugIns/MeowPlannerWidgetExtension.appex\""))
        #expect(script.contains("/usr/bin/pluginkit -r \"$WIDGET_BUNDLE\""))
        #expect(script.contains("/usr/bin/pluginkit -a \"$WIDGET_BUNDLE\""))
        #expect(script.contains("/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R \"$INSTALL_BUNDLE\""))
        #expect(script.contains("/usr/bin/open -n \"$INSTALL_BUNDLE\""))
        #expect(script.contains("Verified $APP_NAME is running from $INSTALL_BUNDLE"))
        #expect(script.contains("com.apple.security.temporary-exception.files.home-relative-path.read-write"))
        #expect(script.contains("/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/"))
        #expect(script.contains("framework_search_roots"))
        #expect(script.contains("-name \"*.framework\""))
        #expect(script.contains("embedded_framework"))
    }

    @Test("project links Firebase Auth and Firestore and bundles the Firebase config")
    func projectLinksFirebaseAuthFirestoreAndBundlesConfig() throws {
        let root = try packageRoot()
        let packageFile = root.appendingPathComponent("Package.swift")
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let appFile = root.appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let configFile = root.appendingPathComponent("Config/GoogleService-Info.plist")
        let entitlementsFile = root.appendingPathComponent("Config/MeowPlanner.entitlements")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        let packageSource = try String(contentsOf: packageFile, encoding: .utf8)
        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let entitlements = try String(contentsOf: entitlementsFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: configFile.path))
        #expect(packageSource.contains("https://github.com/firebase/firebase-ios-sdk.git"))
        #expect(packageSource.contains(".product(name: \"FirebaseAuth\""))
        #expect(packageSource.contains(".product(name: \"FirebaseCore\""))
        #expect(packageSource.contains(".product(name: \"FirebaseFirestore\""))
        #expect(generatorSource.contains("Config/GoogleService-Info.plist"))
        #expect(generatorSource.contains("FirebaseAuth"))
        #expect(generatorSource.contains("FirebaseCore"))
        #expect(generatorSource.contains("FirebaseFirestore"))
        #expect(project.contains("Config/GoogleService-Info.plist"))
        #expect(project.contains("XCRemoteSwiftPackageReference"))
        #expect(project.contains("FirebaseAuth"))
        #expect(project.contains("FirebaseCore"))
        #expect(project.contains("FirebaseFirestore"))
        #expect(appSource.contains("import FirebaseCore"))
        #expect(appSource.contains("FirebaseApp.configure()"))
        #expect(entitlements.contains("keychain-access-groups"))
        #expect(entitlements.contains("com.apple.security.network.client"))
        #expect(!entitlements.contains("aps-environment"))
        #expect(!entitlements.contains("com.apple.developer.icloud-container-identifiers"))
        #expect(!entitlements.contains("com.apple.developer.icloud-services"))
    }

    @Test("Firestore sync covers every local planner data model")
    func firestoreSyncCoversEveryLocalPlannerDataModel() throws {
        let root = try packageRoot()
        let rootViewFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let syncServiceFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/FirestoreAppDataSyncService.swift")
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        let rootView = try String(contentsOf: rootViewFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let syncService = try String(contentsOf: syncServiceFile, encoding: .utf8)
        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)

        for modelName in [
            "PlannerEvent",
            "TodoGroup",
            "TodoItem",
            "Habit",
            "HabitCheckIn",
            "FocusTag",
            "FocusSession",
            "PlannerPreference",
            "CourseTimetable",
            "CoursePeriod",
            "Course",
            "CourseSession"
        ] {
            #expect(rootView.contains("\\\(modelName)"))
            #expect(syncService.contains("fetch(\(modelName).self"))
        }

        for collectionName in [
            "events",
            "todoGroups",
            "todos",
            "habits",
            "habitCheckIns",
            "focusTags",
            "focusSessions",
            "preferences",
            "courseTimetables",
            "coursePeriods",
            "courses",
            "courseSessions"
        ] {
            #expect(syncService.contains(".\(collectionName)"))
        }

        #expect(rootView.contains("appDataCloudSyncSignature"))
        #expect(rootView.contains("scheduleCloudAppDataSync()"))
        #expect(syncService.contains("CloudDeletionTracker.missingUploadedDocumentIDs"))
        #expect(syncService.contains("CloudRecordMergeDecision.shouldApplyRemoteRecord"))
        #expect(syncService.contains("CloudRecordMergeDecision.shouldApplyRemoteDeletion"))
        #expect(syncService.contains("stageLocalDeletions"))
        #expect(syncService.contains("pendingDeletedDocumentIDs"))
        #expect(syncService.contains("clearPendingDeletedDocumentID"))
        #expect(settingsSource.contains("defaults.set(Date().timeIntervalSince1970, forKey: AppLanguage.updatedAtStorageKey)"))
        #expect(settingsSource.contains("defaults.set(Date().timeIntervalSince1970, forKey: AppAppearancePreference.updatedAtStorageKey)"))
        #expect(rootView.contains("cloudAppLanguageUpdatedAt"))
        #expect(rootView.contains("cloudAppearanceUpdatedAt"))
        #expect(syncService.contains("\"appLanguageUpdatedAt\": languageUpdatedAt"))
        #expect(syncService.contains("\"appearanceUpdatedAt\": appearanceUpdatedAt"))
        #expect(syncService.contains("SyncedUserDefaultMergeDecision.shouldApplyRemoteValue"))
        #expect(syncService.contains("shouldApplyRemoteAppearancePreference"))
        #expect(generatorSource.contains("FirestoreAppDataSyncService.swift"))
        #expect(project.contains("FirestoreAppDataSyncService.swift"))
    }

    @Test("account settings present one login button with account modal flows")
    func accountSettingsPresentOneLoginButtonWithAccountModalFlows() throws {
        let root = try packageRoot()
        let accountSectionFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/AccountSettingsSection.swift")
        let accountModalFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Account/AccountAuthenticationModalView.swift")
        let accountStoreFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AccountSessionStore.swift")
        let authClientFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/FirebaseAccountAuthenticationClient.swift")
        let scriptFile = root
            .appendingPathComponent("script/build_and_run.sh")
        let entitlementsFile = root
            .appendingPathComponent("Config/MeowPlanner.entitlements")

        let accountSectionSource = try String(contentsOf: accountSectionFile, encoding: .utf8)
        let accountModalSource = try String(contentsOf: accountModalFile, encoding: .utf8)
        let accountStoreSource = try String(contentsOf: accountStoreFile, encoding: .utf8)
        let authClientSource = try String(contentsOf: authClientFile, encoding: .utf8)
        let script = try String(contentsOf: scriptFile, encoding: .utf8)
        let entitlements = try String(contentsOf: entitlementsFile, encoding: .utf8)

        #expect(!accountSectionSource.contains("SignInWithAppleButton"))
        #expect(!accountSectionSource.contains("AuthenticationServices"))
        #expect(!accountSectionSource.contains("ASAuthorization"))
        #expect(accountSectionSource.contains("showingAuthenticationModal"))
        #expect(accountSectionSource.contains("AccountAuthenticationModalView"))
        #expect(accountSectionSource.contains("PlannerCopy.text(.loginButton"))
        #expect(!accountSectionSource.contains("LabeledContent(PlannerCopy.text(.provider"))
        #expect(!accountSectionSource.contains("TextField(PlannerCopy.text(.email"))
        #expect(!accountSectionSource.contains("accountStore.registerEmail(email: emailAddress, password: password)"))
        #expect(accountModalSource.contains("enum AccountAuthenticationMode"))
        #expect(accountModalSource.contains("case signIn"))
        #expect(accountModalSource.contains("case createAccount"))
        #expect(accountModalSource.contains("case forgotPassword"))
        #expect(accountModalSource.contains("case linkAccount"))
        #expect(accountModalSource.contains("case deleteAccount"))
        #expect(accountModalSource.contains("AccountLoginMethod.allCases"))
        #expect(accountModalSource.contains("accountStore.linkAccount"))
        #expect(accountModalSource.contains("accountStore.deleteAccount"))
        #expect(accountModalSource.contains("accountStore.registerAccount("))
        #expect(accountModalSource.contains("emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty"))
        #expect(!accountModalSource.contains("emailAddressForAccountRegistration"))
        #expect(!accountModalSource.contains("PlannerCopy.text(.optionalEmail"))
        #expect(accountModalSource.contains("Button(role: .destructive)"))
        #expect(accountModalSource.contains("accountStore.sendEmailVerification"))
        #expect(accountModalSource.contains("accountStore.sendPhoneVerification"))
        #expect(accountModalSource.contains("accountStore.sendPasswordReset"))
        #expect(accountModalSource.contains("PlannerCopy.text(.sendResetLink"))
        #expect(accountModalSource.contains("PlannerCopy.text(.passwordResetLinkSent"))
        #expect(!accountModalSource.contains("enum PasswordResetStep"))
        #expect(!accountModalSource.contains("passwordResetStep = .verifyCode"))
        #expect(!accountModalSource.contains("accountStore.verifyPasswordResetCode"))
        #expect(!accountModalSource.contains("passwordResetStep = .setNewPassword"))
        #expect(!accountModalSource.contains("SecureField(PlannerCopy.text(.confirmNewPassword"))
        #expect(!accountModalSource.contains("accountStore.confirmPasswordReset"))
        #expect(accountModalSource.contains("accountStore.changePassword(currentPassword: currentPassword, newPassword: newPassword)"))
        #expect(accountModalSource.contains(".disabled(currentPassword.isEmpty || newPassword.isEmpty || accountStore.isAuthenticating)"))
        #expect(accountStoreSource.contains("FirebaseAccountAuthenticationClient"))
        #expect(accountStoreSource.contains("Task {"))
        #expect(accountStoreSource.contains("registerAccount(identifier: String, email: String, password: String)"))
        #expect(accountStoreSource.contains("await self.authenticationClient.registerEmail"))
        #expect(accountStoreSource.contains("await self.authenticationClient.signInEmail"))
        #expect(accountStoreSource.contains("linkAccount(identifier:"))
        #expect(accountStoreSource.contains("deleteAccount(currentPassword:"))
        #expect(accountStoreSource.contains("sendEmailVerification"))
        #expect(accountStoreSource.contains("sendPhoneVerification"))
        #expect(accountStoreSource.contains("sendPasswordReset"))
        #expect(accountStoreSource.contains("func verifyPasswordResetCode"))
        #expect(accountStoreSource.contains("authenticationClient.verifyPasswordResetCode"))
        #expect(accountStoreSource.contains("func confirmPasswordReset(code: String, newPassword: String, confirmPassword: String"))
        #expect(accountStoreSource.contains("EmailAddressRules.validatePasswordConfirmation"))
        #expect(accountStoreSource.contains("authenticationClient.confirmPasswordReset"))
        #expect(accountStoreSource.contains("func changePassword(currentPassword: String, newPassword: String)"))
        #expect(accountStoreSource.contains("authenticationClient.changePassword(currentPassword: currentPassword, newPassword: newPassword)"))
        #expect(authClientSource.contains("accountAliases"))
        #expect(authClientSource.contains("AccountAliasRules.emailAddressForAccountRegistration"))
        #expect(!authClientSource.contains("AccountAliasRules.internalEmailAddress"))
        #expect(!authClientSource.contains("signIn(withEmail: internalEmailAddress"))
        #expect(authClientSource.contains("linkAccount(identifier:"))
        #expect(authClientSource.contains("deleteAccount(currentPassword:"))
        #expect(authClientSource.contains("reauthenticate(with:"))
        #expect(authClientSource.contains("user.delete"))
        #expect(authClientSource.contains("sendEmailVerification"))
        #expect(authClientSource.contains("sendPasswordReset"))
        #expect(authClientSource.contains("func verifyPasswordResetCode"))
        #expect(authClientSource.contains("Auth.auth().verifyPasswordResetCode"))
        #expect(authClientSource.contains("func confirmPasswordReset"))
        #expect(authClientSource.contains("Auth.auth().confirmPasswordReset"))
        #expect(authClientSource.contains("sendPhoneVerification"))
        #expect(!authClientSource.contains("PhoneAuthProvider.provider()"))
        #expect(authClientSource.contains("AccountAuthenticationError.providerUnavailable"))
        let firebaseClientStart = try #require(authClientSource.range(of: "struct FirebaseAccountAuthenticationClient"))
        let changePasswordStart = try #require(authClientSource.range(
            of: "func changePassword(",
            range: firebaseClientStart.upperBound..<authClientSource.endIndex
        ))
        let phoneVerificationStart = try #require(authClientSource.range(
            of: "func sendPhoneVerification",
            range: changePasswordStart.upperBound..<authClientSource.endIndex
        ))
        let changePasswordSource = String(authClientSource[changePasswordStart.lowerBound..<phoneVerificationStart.lowerBound])
        #expect(changePasswordSource.contains("currentPassword: String"))
        #expect(!changePasswordSource.contains("confirmPassword"))
        let reauthenticationCall = "try await reauthenticate(with: currentPassword, user: user)"
        let updatePasswordCall = "user.updatePassword(to: newPassword)"
        let reauthenticationRange = try #require(changePasswordSource.range(of: reauthenticationCall))
        let updatePasswordRange = try #require(changePasswordSource.range(of: updatePasswordCall))
        #expect(reauthenticationRange.lowerBound < updatePasswordRange.lowerBound)
        #expect(!accountStoreSource.contains("signInWithApple"))
        #expect(!accountStoreSource.contains("appleAuthorizationFailed"))
        #expect(!script.contains("verify_apple_signin_entitlement"))
        #expect(!script.contains("com.apple.developer.applesignin"))
        #expect(script.contains("com.apple.security.network.client"))
        #expect(!entitlements.contains("com.apple.developer.applesignin"))
    }

    @Test("Firebase rules allow linked account aliases without exposing private planner data")
    func firebaseRulesAllowLinkedAccountAliasesWithoutExposingPrivatePlannerData() throws {
        let root = try packageRoot()
        let firebaseConfigFile = root.appendingPathComponent("firebase.json")
        let firestoreRulesFile = root.appendingPathComponent("firestore.rules")

        #expect(FileManager.default.fileExists(atPath: firebaseConfigFile.path))
        #expect(FileManager.default.fileExists(atPath: firestoreRulesFile.path))

        let firebaseConfig = try String(contentsOf: firebaseConfigFile, encoding: .utf8)
        let rules = try String(contentsOf: firestoreRulesFile, encoding: .utf8)

        #expect(firebaseConfig.contains("\"firestore\""))
        #expect(firebaseConfig.contains("\"rules\": \"firestore.rules\""))
        #expect(rules.contains("match /users/{userID}/{document=**}"))
        #expect(rules.contains("allow read, write: if isSignedIn() && request.auth.uid == userID;"))
        #expect(rules.contains("match /accountAliases/{aliasID}"))
        #expect(rules.contains("allow get: if true;"))
        #expect(rules.contains("allow list: if isSignedIn() && resource.data.userID == request.auth.uid;"))
        #expect(rules.contains("request.resource.data.userID == request.auth.uid"))
        #expect(rules.contains("resource.data.userID == request.auth.uid"))
        #expect(rules.contains("request.resource.data.keys().hasOnly(["))
        #expect(rules.contains("'identifier'"))
        #expect(rules.contains("'emailAddress'"))
        #expect(rules.contains("'userID'"))
        #expect(rules.contains("'createdAt'"))
        #expect(rules.contains("'updatedAt'"))
    }

    @Test("planner surfaces stay mounted while signed out with an empty workspace")
    func plannerSurfacesStayMountedWhileSignedOutWithEmptyWorkspace() throws {
        let root = try packageRoot()
        let appFile = root.appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let gatedRootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Account/AccountGatedRootView.swift")
        let accountContainerFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AccountScopedModelContainerStore.swift")
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let rootViewFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let menuBarFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")
        let languageFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let gatedRootSource = sourceIfPresent(gatedRootFile)
        let accountContainerSource = sourceIfPresent(accountContainerFile)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let menuBarSource = try String(contentsOf: menuBarFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let sheetModifierCount = settingsSource.components(separatedBy: ".sheet(").count - 1
        let settingsFormSource = try sourceWindow(
            in: settingsSource,
            from: "private func settingsForm",
            length: 900
        )
        let deleteAccountButtonSource = try sourceWindow(
            in: settingsSource,
            from: "showingDeleteAccountConfirmation = true",
            length: 900
        )

        #expect(appSource.contains("AccountGatedRootView"))
        #expect(appSource.contains("AccountGatedSettingsView"))
        #expect(!gatedRootSource.contains("SignedOutAccountGateView"))
        #expect(gatedRootSource.contains("accountStore.currentProfile"))
        #expect(gatedRootSource.contains(".modelContainer(accountContainer)"))
        #expect(gatedRootSource.contains(".modelContainer(signedOutModelContainer)"))
        #expect(accountContainerSource.contains("ModelContainerFactory.makeAccountScoped"))
        #expect(accountContainerSource.contains("ModelContainerFactory.makeSignedOutWorkspace"))
        #expect(accountContainerSource.contains("signedOutModelContainer"))
        #expect(accountContainerSource.contains("prepareSignedOutContainer"))
        #expect(accountContainerSource.contains("migrateLegacyLocalDataIfNeeded"))
        #expect(rootViewSource.contains("SignedOutWorkspaceReadOnlyModifier"))
        #expect(rootViewSource.contains("isSignedOutWorkspace && section != .settings"))
        #expect(rootViewSource.contains(".disabled(isEnabled)"))
        #expect(rootViewSource.contains("scheduleSync(for: accountStore.currentProfile?.remoteUserID"))
        #expect(menuBarSource.contains("accountStore.currentProfile"))
        #expect(!menuBarSource.contains("SignedOutMenuBarView"))
        #expect(menuBarSource.contains("signedOutModelContainer"))
        #expect(settingsSource.contains("accountActionsSection"))
        #expect(settingsSource.contains("Button(role: .destructive)"))
        #expect(settingsSource.contains("PlannerCopy.text(.signOut"))
        #expect(settingsSource.contains("PlannerCopy.text(.changePassword"))
        #expect(settingsSource.contains("PlannerCopy.text(.linkAccount"))
        #expect(settingsSource.contains("PlannerCopy.text(.deleteAccount"))
        #expect(settingsSource.contains("showingDeleteAccountConfirmation"))
        #expect(settingsSource.contains(".alert(PlannerCopy.text(.deleteAccountConfirmationMessage"))
        #expect(settingsSource.contains("Button(PlannerCopy.text(.deleteAccount, language: appLanguage), role: .destructive)"))
        #expect(settingsSource.contains("private enum SettingsSheet: String, Identifiable"))
        #expect(settingsSource.contains("@State private var activeSettingsSheet: SettingsSheet?"))
        #expect(sheetModifierCount == 1)
        #expect(settingsFormSource.contains(".sheet(item: $activeSettingsSheet)"))
        #expect(settingsSource.contains("activeSettingsSheet = .deleteAccount"))
        #expect(settingsSource.contains("activeSettingsSheet = .changePassword"))
        #expect(settingsSource.contains("activeSettingsSheet = .linkAccount"))
        #expect(settingsSource.contains("case .changePassword"))
        #expect(settingsSource.contains("initialMode: .changePassword"))
        #expect(!settingsSource.contains("showingDeleteAccountModal"))
        #expect(!settingsSource.contains("showingChangePasswordModal"))
        #expect(!settingsSource.contains("showingLinkAccountModal"))
        #expect(deleteAccountButtonSource.contains("SettingsDangerActionLabel("))
        #expect(deleteAccountButtonSource.contains(".buttonStyle(.plain)"))
        #expect(settingsSource.contains("private struct SettingsDangerActionLabel"))
        #expect(settingsSource.contains(".foregroundStyle(.red)"))
        #expect(settingsSource.contains(".background(.red.opacity(0.10)"))
        #expect(settingsSource.contains(".stroke(.red.opacity(0.28)"))
        #expect(languageSource.contains(".deleteAccountConfirmationMessage: \"是否确认删除账号，删除账号不可找回\""))
    }

    @Test("sign out clears local presentation state for private account data")
    func signOutClearsLocalPresentationStateForPrivateAccountData() throws {
        let root = try packageRoot()
        let accountStoreFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AccountSessionStore.swift")
        let containerStoreFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AccountScopedModelContainerStore.swift")
        let timelineSyncFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/WidgetTimelineSyncService.swift")
        let coreSnapshotFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")
        let syncServiceFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/FirestoreAppDataSyncService.swift")

        let accountStoreSource = try String(contentsOf: accountStoreFile, encoding: .utf8)
        let containerStoreSource = sourceIfPresent(containerStoreFile)
        let timelineSyncSource = try String(contentsOf: timelineSyncFile, encoding: .utf8)
        let coreSnapshotSource = try String(contentsOf: coreSnapshotFile, encoding: .utf8)
        let syncServiceSource = try String(contentsOf: syncServiceFile, encoding: .utf8)

        #expect(accountStoreSource.contains("WidgetTimelineSyncService.clearSnapshotAndReload()"))
        #expect(accountStoreSource.contains("AccountScopedModelContainerStore.shared.unload()"))
        #expect(containerStoreSource.contains("func unload()"))
        #expect(timelineSyncSource.contains("clearSnapshotAndReload"))
        #expect(coreSnapshotSource.contains("public static func clear("))
        #expect(syncServiceSource.contains("func scheduleSync(for userID: String?"))
        #expect(syncServiceSource.contains("guard currentUserID == userID"))
    }

    @Test("account session does not restore stale local profile without Firebase auth")
    func accountSessionDoesNotRestoreStaleLocalProfileWithoutFirebaseAuth() throws {
        let root = try packageRoot()
        let accountStoreFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AccountSessionStore.swift")

        let accountStoreSource = try String(contentsOf: accountStoreFile, encoding: .utf8)

        #expect(accountStoreSource.contains("currentProfile = authenticationClient.currentProfile()"))
        #expect(!accountStoreSource.contains("?? Self.decode(AccountProfile.self"))
        #expect(accountStoreSource.contains("defaults.removeObject(forKey: Self.sessionStorageKey)"))
    }

    @Test("widget bundle version is bumped for WidgetKit metadata refresh")
    func widgetBundleVersionIsBumpedForWidgetKitMetadataRefresh() throws {
        let root = try packageRoot()
        let widgetPlist = root
            .appendingPathComponent("Config/MeowPlannerWidget-Info.plist")

        let data = try Data(contentsOf: widgetPlist)
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])

        #expect(plist["CFBundleShortVersionString"] as? String == "1.0.12")
        #expect(plist["CFBundleVersion"] as? String == "13")
    }

    @Test("month widget has interactive FuFu navigation")
    func monthWidgetHasInteractiveFuFuNavigation() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let coreIntentFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WidgetAppIntents.swift")
        let appIntentPackageFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerAppIntentsPackage.swift")
        let widgetIntentPackageFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerWidgetIntentsPackage.swift")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let coreIntentSource = try String(contentsOf: coreIntentFile, encoding: .utf8)
        let appIntentPackageSource = try String(contentsOf: appIntentPackageFile, encoding: .utf8)
        let widgetIntentPackageSource = try String(contentsOf: widgetIntentPackageFile, encoding: .utf8)
        let projectSource = try String(contentsOf: projectFile, encoding: .utf8)

        #expect(widgetSource.contains("import AppIntents"))
        #expect(widgetSource.contains("ChangeWidgetMonthIntent"))
        #expect(widgetSource.contains("Button(intent: ChangeWidgetMonthIntent"))
        #expect(widgetSource.contains(".contentMarginsDisabled()"))
        #expect(widgetSource.contains("private var monthHeader"))
        #expect(widgetSource.contains("calendarGrid(rowHeight:"))
        #expect(coreIntentSource.contains("WidgetCenter.shared.reloadTimelines"))
        #expect(coreIntentSource.contains("widgetMonthOffset"))
        #expect(!widgetSource.contains("defaults.synchronize()"))
        #expect(widgetSource.contains("fufuWidgetMascot"))
        #expect(widgetSource.contains("fufuPawWatermark"))
        #expect(widgetSource.contains("let maxVisibleItems: Int = family == .systemExtraLarge ? 2 : 1"))
        #expect(widgetSource.contains("hex: item.colorHex"))
        #expect(!widgetSource.contains("if family == .systemExtraLarge {"))
        #expect(widgetSource.contains("ForEach(Array(weekdaySymbols.enumerated()), id: \\.offset)"))
        #expect(widgetSource.contains("weekdayHeaderCell"))
        #expect(widgetSource.contains("weekdaySeparatorColor"))
        #expect(widgetSource.contains("snapshot?.weekStartPreference ?? .sunday"))
        #expect(!widgetSource.contains("ForEach(calendar.veryShortWeekdaySymbols, id: \\.self)"))
        #expect(!widgetSource.contains("return AnyShapeStyle(Color.white.opacity(0.24))"))
        #expect(!widgetSource.contains("public struct ChangeWidgetMonthIntent"))
        #expect(!widgetSource.contains("public struct RefreshWidgetTimelineIntent"))
        #expect(FileManager.default.fileExists(atPath: coreIntentFile.path))
        #expect(coreIntentSource.contains("import AppIntents"))
        #expect(coreIntentSource.contains("import WidgetKit"))
        #expect(coreIntentSource.contains("public struct MeowPlannerCoreAppIntentsPackage: AppIntentsPackage"))
        #expect(coreIntentSource.contains("public struct ChangeWidgetMonthIntent: AppIntent"))
        #expect(coreIntentSource.contains("public struct RefreshWidgetTimelineIntent: AppIntent"))
        #expect(coreIntentSource.contains("public enum WidgetMonthSelectionStore"))
        #expect(appIntentPackageSource.contains("struct MeowPlannerAppIntentsPackage: AppIntentsPackage"))
        #expect(appIntentPackageSource.contains("MeowPlannerCoreAppIntentsPackage.self"))
        #expect(widgetIntentPackageSource.contains("struct MeowPlannerWidgetIntentsPackage: AppIntentsPackage"))
        #expect(widgetIntentPackageSource.contains("MeowPlannerCoreAppIntentsPackage.self"))
        #expect(projectSource.contains("Sources/MeowPlannerCore/Support/WidgetAppIntents.swift"))
        #expect(projectSource.contains("Sources/MeowPlannerApp/Support/MeowPlannerAppIntentsPackage.swift"))
        #expect(projectSource.contains("Sources/MeowPlannerWidget/MeowPlannerWidgetIntentsPackage.swift"))

        let changeMonthIntentSource = try #require(
            coreIntentSource.range(of: "public struct ChangeWidgetMonthIntent")
                .flatMap { startRange in
                    coreIntentSource.range(of: "public struct RefreshWidgetTimelineIntent")
                        .map { endRange in String(coreIntentSource[startRange.lowerBound..<endRange.lowerBound]) }
                }
        )
        #expect(changeMonthIntentSource.contains("WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)"))
        #expect(!changeMonthIntentSource.contains("WidgetCenter.shared.reloadAllTimelines()"))

        let refreshIntentSource = try #require(
            coreIntentSource.range(of: "public struct RefreshWidgetTimelineIntent")
                .map { String(coreIntentSource[$0.lowerBound...]) }
        )
        #expect(refreshIntentSource.contains("WidgetCenter.shared.reloadAllTimelines()"))
    }

    @Test("widget placeholder avoids shared preferences")
    func widgetPlaceholderAvoidsSharedPreferences() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let makeEntryRange = try #require(
            widgetSource.range(of: "private func makeEntry"),
            "Expected widget entry builder."
        )
        let nextRefreshDateRange = try #require(
            widgetSource.range(of: "private static func nextRefreshDate"),
            "Expected timeline refresh helper after entry builder."
        )
        let makeEntrySource = String(widgetSource[makeEntryRange.lowerBound..<nextRefreshDateRange.lowerBound])

        #expect(makeEntrySource.contains("includeSamplePlans ? .sunday"))
        #expect(makeEntrySource.contains("includeSamplePlans ? 0 : WidgetMonthSelectionStore.currentMonthOffset"))
        #expect(!makeEntrySource.contains("WidgetPlannerPreferenceStore.weekStartPreference"))
    }

    @Test("desktop widget uses snapshots and scheduled timeline entries")
    func desktopWidgetUsesSnapshotsAndScheduledTimelineEntries() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let rootSyncFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/WidgetTimelineSyncService.swift")
        let coreFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")
        let coreIntentFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WidgetAppIntents.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let rootSyncSource = try String(contentsOf: rootSyncFile, encoding: .utf8)
        let coreSource = try String(contentsOf: coreFile, encoding: .utf8)
        let coreIntentSource = try String(contentsOf: coreIntentFile, encoding: .utf8)

        #expect(coreSource.contains("public struct WidgetPlannerSnapshot"))
        #expect(coreSource.contains("public enum WidgetPlannerSnapshotStore"))
        #expect(coreSource.contains("private static var snapshotFileURL: URL?"))
        #expect(coreSource.contains("public static func loadFromFiles()"))
        #expect(coreSource.contains("load(defaults: defaults, fileURLs: snapshotFileURLs)"))
        #expect(coreSource.contains("save(snapshot, defaults: defaults, fileURLs: snapshotFileURLs)"))
        #expect(coreSource.contains("UserDefaults(suiteName: WidgetPlannerPreferenceStore.suiteName) ?? .standard"))
        #expect(coreSource.contains("Data(contentsOf: fileURL)"))
        #expect(coreSource.contains("data.write(to: fileURL, options: .atomic)"))
        #expect(widgetSource.contains("WidgetPlannerSnapshotStore.loadFromFiles()"))
        #expect(!widgetSource.contains("makeSnapshotFromPersistentStore()"))
        #expect(!widgetSource.contains("WidgetPlannerPreferenceStore.showChineseCalendar"))
        #expect(widgetSource.contains("let entry = makeEntry(date: Date(), snapshot: snapshot)"))
        #expect(widgetSource.contains("Timeline(entries: [entry], policy: .after(Self.nextRefreshDate(after: entry.date)))"))
        #expect(widgetSource.contains("private static func nextRefreshDate"))
        #expect(widgetSource.contains("min(shortRefreshDate, nextMidnightRefreshDate)"))
        #expect(coreIntentSource.contains("WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()"))
        #expect(!widgetSource.contains("WidgetPlannerSnapshotStore.save(liveSnapshot)"))
        #expect(!widgetSource.contains("let events = includeSamplePlans ? sampleEvents(anchor: visibleMonthDate) : []"))
        #expect(rootSyncSource.contains("WidgetPlannerSnapshotStore.save"))
        #expect(rootSyncSource.contains("WidgetPlannerSnapshotBuilder.makeSnapshotFromPersistentStore()"))
        #expect(rootSyncSource.contains("refreshSnapshotFromPersistentStore()"))
        #expect(rootSyncSource.contains("WidgetCenter.shared.reloadTimelines"))
    }

    @Test("desktop widget event pills adapt text and background for non full color rendering")
    func desktopWidgetEventPillsAdaptTextAndBackgroundForNonFullColorRendering() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let eventPillStart = try #require(widgetSource.range(of: "ForEach(day.items.prefix(maxVisibleItems))"))
        let eventPillEnd = try #require(widgetSource[eventPillStart.lowerBound...].range(of: "Spacer(minLength: 0)"))
        let eventPillSource = String(widgetSource[eventPillStart.lowerBound..<eventPillEnd.lowerBound])

        #expect(eventPillSource.contains("eventPill(item)"))
        #expect(widgetSource.contains("Text(item.title)"))
        #expect(widgetSource.contains("@Environment(\\.widgetRenderingMode)"))
        #expect(widgetSource.contains("widgetRenderingMode == .fullColor"))
        #expect(widgetSource.contains("private func eventPillTitleColor"))
        #expect(widgetSource.contains("private func eventPillBackground"))
        #expect(widgetSource.contains(".widgetAccentable(!usesFullColorRendering)"))
        #expect(widgetSource.contains("AnyShapeStyle(Color.primary)"))
        #expect(widgetSource.contains("Color.primary.opacity(0.14)"))
    }

    @Test("today widget opens MeowPlanner when tapped")
    func todayWidgetOpensMeowPlannerWhenTapped() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let appPlist = root
            .appendingPathComponent("Config/MeowPlanner-Info.plist")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let data = try Data(contentsOf: appPlist)
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let urlTypes = try #require(plist["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = urlTypes.flatMap { ($0["CFBundleURLSchemes"] as? [String]) ?? [] }

        #expect(widgetSource.contains(".widgetURL(WidgetConstants.appLaunchURL)"))
        #expect(widgetSource.contains("static let appLaunchURL") == false)
        #expect(schemes.contains("meowplanner"))
    }

    @Test("widget URL focuses the system-created main window without opening a duplicate")
    func widgetURLFocusesSystemCreatedMainWindowWithoutOpeningDuplicate() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        #expect(rootSource.contains("focusSystemCreatedMainWindowFromExternalURL"))
        #expect(rootSource.contains("openWindow: @escaping () -> Void"))
        #expect(!rootSource.contains(".onOpenURL"))
        #expect(!rootSource.contains("private func handleAppURL"))
        #expect(appSource.contains("func application(_ application: NSApplication, open urls: [URL])"))
        #expect(appSource.contains("NotificationCenter.default.post(name: .meowPlannerExternalOpenURL"))
        #expect(rootSource.contains("MainWindowLaunchCoordinator.focusSystemCreatedMainWindowFromExternalURL") == false)
        #expect(rootSource.contains("static func focusSystemCreatedMainWindowFromExternalURL"))
        #expect(rootSource.contains("settlingAttempts: Int = 40"))
        #expect(appSource.contains("func applicationDidFinishLaunching"))
        #expect(appSource.contains("AppMainWindowPresenter.shared.openConfiguredMainWindow()"))

        let navigationSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift"),
            encoding: .utf8
        )
        let menuBarSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift"),
            encoding: .utf8
        )

        #expect(navigationSource.contains("meowPlannerExternalOpenURL"))
        #expect(menuBarSource.contains(".onReceive(NotificationCenter.default.publisher(for: .meowPlannerExternalOpenURL))"))
        #expect(menuBarSource.contains("MainWindowLaunchCoordinator.focusSystemCreatedMainWindowFromExternalURL"))
        #expect(menuBarSource.contains("openWindow(id: \"main\")"))
    }

    @Test("widget URL refreshes existing calendar content when the menu bar app is already running")
    func widgetURLRefreshesExistingCalendarContentWhenMenuBarAppIsAlreadyRunning() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)

        #expect(rootSource.contains("@State private var calendarRenderToken = UUID()"))
        #expect(rootSource.contains(".onReceive(NotificationCenter.default.publisher(for: .meowPlannerExternalOpenURL))"))
        #expect(rootSource.contains("refreshCalendarAfterExternalOpen()"))
        #expect(rootSource.contains("calendarRenderToken = UUID()"))
        #expect(rootSource.contains("CalendarHomeView()"))
        #expect(rootSource.contains(".id(calendarRenderToken)"))
    }

    @Test("focus timer follows stored default focus minutes")
    func focusTimerFollowsStoredDefaultFocusMinutes() throws {
        let root = try packageRoot()
        let focusFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")

        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)

        #expect(focusSource.contains("@Query private var preferences: [PlannerPreference]"))
        #expect(focusSource.contains("private var defaultFocusMinutes: Int"))
        #expect(focusSource.contains("private func syncTimerDurationWithPreference()"))
        #expect(focusSource.contains("private func syncCustomDurationWithPreference()"))
        #expect(focusSource.contains(".onChange(of: defaultFocusMinutes)"))
        #expect(focusSource.contains("customFocusMinutes = defaultFocusMinutes"))
        #expect(focusSource.contains("focusTimerStore.syncDuration(customFocusSeconds)"))
        #expect(focusSource.contains("focusTimerStore.reset(defaultDurationSeconds: customFocusSeconds)"))
        #expect(!focusSource.contains("timer = FocusTimerState(durationSeconds: 1_500)"))
    }

    @Test("focus page uses circular timer with scroll editable time and two round controls")
    func focusPageUsesCircularTimerWithScrollEditableTimeAndTwoRoundControls() throws {
        let root = try packageRoot()
        let focusFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")

        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)

        #expect(focusSource.contains("@State private var customFocusMinutes"))
        #expect(focusSource.contains("focusTimerPanel"))
        #expect(focusSource.contains("focusCircularTimer"))
        #expect(!focusSource.contains("focusDurationControls"))
        #expect(focusSource.contains("TextField(PlannerCopy.text(.focusTitle"))
        #expect(focusSource.contains("focusControlButtons"))
        #expect(focusSource.contains("Circle().trim(from: 0, to: focusProgress)"))
        #expect(focusSource.contains("private var focusProgress: Double"))
        #expect(focusSource.contains("FocusDurationScrollView"))
        #expect(focusSource.contains("adjustCustomFocusMinutes(by:"))
        #expect(focusSource.contains("onAdjustment"))
        #expect(focusSource.contains("onInteractionChanged"))
        #expect(focusSource.contains("NSViewRepresentable"))
        #expect(focusSource.contains(".disabled(focusTimerStore.hasActiveSession)"))
        #expect(focusSource.contains("customFocusSeconds"))
        #expect(focusSource.contains("focusTimerStore.start(defaultDurationSeconds: customFocusSeconds)"))
        #expect(focusSource.contains("focusTimerStore.syncDuration(customFocusSeconds)"))
        #expect(focusSource.contains("syncCustomDurationWithPreference()"))
        #expect(focusSource.contains("pauseOrStartFocus()"))
        #expect(focusSource.contains("Image(systemName: focusTimerStore.isRunning ? \"pause.fill\" : \"play.fill\")"))
        #expect(focusSource.contains("Image(systemName: \"stop.fill\")"))
        #expect(focusSource.contains(".background(MeowPlannerTheme.cocoa, in: Circle())"))
        #expect(!focusSource.contains("PlannerCopy.text(.resume"))
        #expect(!focusSource.contains("PlannerCopy.text(.time"))
        #expect(!focusSource.contains("一次只做一件事的 \\(defaultFocusMinutes) 分钟安静计时器。"))
    }

    @Test("focus duration edits from themed timer face with throttled drag feedback")
    func focusDurationEditsFromThemedTimerFaceWithThrottledDragFeedback() throws {
        let root = try packageRoot()
        let focusFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")

        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)

        #expect(focusSource.contains("private var focusTitleField: some View"))
        #expect(focusSource.contains("MeowPlannerTheme.warmCream.opacity(0.34)"))
        #expect(focusSource.contains("MeowPlannerTheme.cocoa.opacity(0.22)"))
        #expect(focusSource.contains("@State private var isEditingFocusDuration = false"))
        #expect(focusSource.contains("@State private var draftFocusMinutes = \"\""))
        #expect(focusSource.contains("@State private var durationDragOffset: CGFloat = 0"))
        #expect(focusSource.contains("beginEditingFocusDuration()"))
        #expect(focusSource.contains("commitFocusDurationEdit()"))
        #expect(focusSource.contains("commitFocusDurationEditIfNeeded()"))
        #expect(focusSource.contains("focusDurationOutsideCommitLayer"))
        #expect(focusSource.contains("focusTimerPanelOutsideCommitLayer"))
        #expect(focusSource.contains("focusDurationOutsideTapGesture"))
        #expect(focusSource.contains("if isEditingFocusDuration {"))
        #expect(focusSource.contains("Color.clear.contentShape(Rectangle())"))
        #expect(focusSource.contains(".onTapGesture {"))
        #expect(focusSource.contains("commitFocusDurationEdit()"))
        #expect(focusSource.contains(".zIndex(1)"))
        #expect(focusSource.contains("focusTitleField.simultaneousGesture(focusDurationOutsideTapGesture)"))
        #expect(focusSource.contains("focusControlButtons.simultaneousGesture(focusDurationOutsideTapGesture)"))
        #expect(focusSource.contains("recentSessions.simultaneousGesture(focusDurationOutsideTapGesture)"))
        #expect(focusSource.contains("focusDurationEditingFace"))
        #expect(focusSource.contains("draftFocusMinutes = draftFocusMinutes.filter(\\.isNumber)"))
        #expect(focusSource.contains("Text(\":00\")"))
        #expect(focusSource.contains(".frame(width: 92, alignment: .trailing)"))
        #expect(focusSource.contains("durationAdjustmentPreview"))
        #expect(focusSource.contains("FocusDurationScrollView("))
        #expect(focusSource.contains("onEditRequested: {"))
        #expect(focusSource.contains("onAdjustment: { delta, dragOffset in"))
        #expect(focusSource.contains("adjustCustomFocusMinutes(by: -delta)"))
        #expect(focusSource.contains("durationDragOffset = -dragOffset"))
        #expect(focusSource.contains("durationPreviewMinuteText(for:"))
        #expect(focusSource.contains("Text(durationPreviewMinuteText(for: customFocusMinutes - 1))"))
        #expect(focusSource.contains("Text(durationPreviewMinuteText(for: customFocusMinutes + 1))"))
        #expect(focusSource.contains(".frame(width: 82, alignment: .trailing)"))
        #expect(focusSource.contains(".offset(x: -44"))
        #expect(!focusSource.contains("FocusTimerStore.timeString(clampedFocusMinutes(customFocusMinutes + 1) * 60)"))
        #expect(!focusSource.contains("FocusTimerStore.timeString(clampedFocusMinutes(customFocusMinutes - 1) * 60)"))
        #expect(focusSource.contains(".allowsHitTesting(!isEditingFocusDuration && !focusTimerStore.hasActiveSession)"))
        #expect(focusSource.contains("scrollThreshold: CGFloat = 44"))
        #expect(focusSource.contains("dragThreshold: CGFloat = 20"))
        #expect(focusSource.contains("didDrag"))
        #expect(focusSource.contains("event.clickCount >= 2"))
        #expect(focusSource.contains("override func mouseDown(with event: NSEvent)"))
        #expect(focusSource.contains("override func mouseDragged(with event: NSEvent)"))
        #expect(focusSource.contains("override func mouseUp(with event: NSEvent)"))
        #expect(focusSource.contains("onInteractionChanged"))
        #expect(!focusSource.contains("onScrollUp"))
        #expect(!focusSource.contains("onScrollDown"))
    }

    @Test("menu bar shows navigation when idle and a themed countdown panel while focusing")
    func menuBarShowsNavigationWhenIdleAndCountdownPanelWhileFocusing() throws {
        let root = try packageRoot()
        let appFile = root.appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
        let menuBarFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")
        let focusFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let menuBarSource = try String(contentsOf: menuBarFile, encoding: .utf8)
        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)

        #expect(appSource.contains("@StateObject private var focusTimerStore: FocusTimerStore"))
        #expect(appSource.contains("_focusTimerStore = StateObject(wrappedValue: focusTimerStore)"))
        #expect(appSource.contains(".environmentObject(focusTimerStore)"))
        #expect(appSource.contains("MeowPlannerMenuBarLabel(openAppKitMainWindow: openAppKitMainWindow)"))
        #expect(appSource.contains("legacyModelContainer: legacyModelContainer"))
        #expect(appSource.contains(".menuBarExtraStyle(.window)"))
        #expect(navigationSource.contains("AppNavigationRequest.open(.focus)"))
        #expect(navigationSource.contains("AppNavigationRequest.open(.calendar)"))
        #expect(navigationSource.contains("AppNavigationRequest.open(.settings)"))
        #expect(rootSource.contains(".onReceive(NotificationCenter.default.publisher(for: .meowPlannerOpenSection))"))
        #expect(rootSource.contains("selection = section"))
        #expect(menuBarSource.contains("struct MeowPlannerMenuBarLabel: View"))
        #expect(menuBarSource.contains("focusTimerStore.hasActiveSession ? focusTimerStore.formattedRemainingTime"))
        #expect(menuBarSource.contains("Label(\"MeowPlanner\", systemImage: \"calendar.badge.clock\")"))
        #expect(menuBarSource.contains("if focusTimerStore.hasActiveSession"))
        #expect(menuBarSource.contains("FocusTimerMenuPanel("))
        #expect(menuBarSource.contains(".modelContainer(accountContainer)"))
        #expect(menuBarSource.contains("inactiveMenu"))
        #expect(menuBarSource.contains("openCalendarPage()"))
        #expect(menuBarSource.contains("openFocusPage()"))
        #expect(menuBarSource.contains("openSettingsPage()"))
        #expect(menuBarSource.contains("NSApplication.shared.terminate(nil)"))
        #expect(menuBarSource.contains(".keyboardShortcut(\"q\", modifiers: [.command])"))
        #expect(menuBarSource.contains("PlannerCopy.text(.openMeowPlanner"))
        #expect(menuBarSource.contains("PlannerCopy.text(.focusTimer"))
        #expect(menuBarSource.contains("PlannerCopy.text(.settings"))
        #expect(menuBarSource.contains("PlannerCopy.text(.quitMeowPlanner"))
        #expect(menuBarSource.contains("private struct FocusTimerMenuPanel: View"))
        #expect(menuBarSource.contains("circularProgressRing"))
        #expect(menuBarSource.contains("Circle().trim(from: 0, to: progress)"))
        #expect(menuBarSource.contains("FuFuAssetImage(size: 42)"))
        #expect(menuBarSource.contains("MeowPlannerTheme.fufuPlannerBackground"))
        #expect(menuBarSource.contains("focusTimerStore.pause"))
        #expect(menuBarSource.contains("focusTimerStore.resume"))
        #expect(menuBarSource.contains("finishFromMenuBar()"))
        #expect(menuBarSource.contains("modelContext.insert(session)"))
        #expect(focusSource.contains("final class FocusTimerStore: ObservableObject"))
        #expect(focusSource.contains("@EnvironmentObject private var focusTimerStore: FocusTimerStore"))
        #expect(focusSource.contains("focusTimerStore.start"))
        #expect(!menuBarSource.contains("PlannerCopy.text(.todaySchedule"))
    }

    @Test("recent focus sessions can be edited and deleted")
    func recentFocusSessionsCanBeEditedAndDeleted() throws {
        let root = try packageRoot()
        let focusFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")
        let languageFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)

        #expect(focusSource.contains("@State private var editingSession: FocusSession?"))
        #expect(focusSource.contains("FocusSessionEditorView(session: editingSession, tags: focusTags)"))
        #expect(focusSource.contains("editingSession = session"))
        #expect(focusSource.contains("deleteFocusSession(session)"))
        #expect(focusSource.contains("private struct FocusSessionEditorView: View"))
        #expect(focusSource.contains("DatePicker(PlannerCopy.text(.startDate"))
        #expect(focusSource.contains("DatePicker(PlannerCopy.text(.end"))
        #expect(focusSource.contains("session.completedDurationSeconds = completedMinutes * 60"))
        #expect(focusSource.contains("modelContext.delete(session)"))
        #expect(languageSource.contains("case editFocusSession"))
        #expect(languageSource.contains("case completedMinutes"))
    }

    @Test("focus center exposes timer timeline insights and tags")
    func focusCenterExposesTimerTimelineInsightsAndTags() throws {
        let root = try packageRoot()
        let focusFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")
        let modelFile = root.appendingPathComponent("Sources/MeowPlannerCore/Models/FocusSession.swift")
        let containerFile = root.appendingPathComponent("Sources/MeowPlannerCore/Stores/ModelContainerFactory.swift")
        let languageFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")
        let menuBarFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")

        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)
        let modelSource = try String(contentsOf: modelFile, encoding: .utf8)
        let containerSource = try String(contentsOf: containerFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let menuBarSource = try String(contentsOf: menuBarFile, encoding: .utf8)

        #expect(modelSource.contains("public enum FocusMode"))
        #expect(modelSource.contains("public final class FocusTag"))
        #expect(modelSource.contains("public enum FocusAnalytics"))
        #expect(modelSource.contains("public var tagID: UUID?"))
        #expect(modelSource.contains("public var modeRawValue"))
        #expect(containerSource.contains("FocusTag.self"))
        #expect(focusSource.contains("private enum FocusSection"))
        #expect(focusSource.contains("@Query(sort: \\FocusTag.sortOrder)"))
        #expect(focusSource.contains("Picker(\"\", selection: $selectedSection)"))
        #expect(focusSource.contains("focusModePicker"))
        #expect(focusSource.contains("focusTagPicker"))
        #expect(focusSource.contains("FocusTagEditorView"))
        #expect(focusSource.contains("focusTimelineView"))
        #expect(focusSource.contains("FocusAnalytics.timelineEntries"))
        #expect(focusSource.contains("focusInsightsView"))
        #expect(focusSource.contains("FocusAnalytics.summary"))
        #expect(focusSource.contains("focusHourDistributionChart"))
        #expect(focusSource.contains("focusTagShareChart"))
        #expect(focusSource.contains("mode: focusTimerStore.focusMode"))
        #expect(focusSource.contains("tagID: focusTimerStore.focusTagID"))
        #expect(menuBarSource.contains("mode: focusTimerStore.focusMode"))
        #expect(menuBarSource.contains("tagID: focusTimerStore.focusTagID"))
        #expect(languageSource.contains("case focusTimeline"))
        #expect(languageSource.contains("case focusInsights"))
        #expect(languageSource.contains("case focusModeCountdown"))
        #expect(languageSource.contains("case focusModeStopwatch"))
        #expect(languageSource.contains("case focusTag"))
        #expect(languageSource.contains("case uncategorizedFocus"))
    }

    @Test("numeric settings use direct input fields instead of steppers")
    func numericSettingsUseDirectInputFieldsInsteadOfSteppers() throws {
        let root = try packageRoot()
        let timetableFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let calendarFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let calendarSource = try String(contentsOf: calendarFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)
        let combinedSource = [timetableSource, settingsSource, calendarSource, themeSource].joined(separator: "\n")

        #expect(!combinedSource.contains("Stepper("))
        #expect(timetableSource.contains("PlannerNumberInputRow("))
        #expect(settingsSource.contains("PlannerNumberInputRow("))
        #expect(calendarSource.contains("PlannerNumberInputRow("))
        #expect(themeSource.contains("TextField(\"\", text: $draftText)"))
        #expect(themeSource.contains("@FocusState private var isInputFocused"))
        #expect(themeSource.contains(".focused($isInputFocused)"))
        #expect(themeSource.contains(".onChange(of: value)"))
        #expect(themeSource.contains(".onChange(of: isInputFocused)"))
        #expect(themeSource.contains("if !newValue {"))
        #expect(themeSource.contains("NumericInputOutsideClickCommitter"))
        #expect(themeSource.contains("NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown)"))
        #expect(themeSource.contains("!rectInWindow.contains(event.locationInWindow)"))
    }

    @Test("app supports system, light, and dark FuFu appearance modes")
    func appSupportsSystemLightAndDarkFuFuAppearanceModes() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(appSource.contains("AccountGatedRootView("))
        #expect(appSource.contains("AccountGatedSettingsView("))
        #expect(appSource.contains("@AppStorage(AppAppearancePreference.storageKey)"))
        #expect(appSource.contains(".preferredColorScheme(appAppearance.preferredColorScheme)"))
        #expect(appSource.contains("AppAppearancePreferenceApplicator.apply(appAppearance)"))
        #expect(appSource.contains(".onChange(of: appearanceID)"))
        #expect(appSource.contains("AppAppearancePreferenceApplicator.apply(AppAppearancePreference(storedValue: newValue))"))
        #expect(appSource.contains("NSApp.appearance"))
        #expect(appSource.contains("NSAppearance(named: .aqua)"))
        #expect(appSource.contains("NSAppearance(named: .darkAqua)"))
        #expect(appSource.contains("case .system:\n            NSApp.appearance = nil"))
        #expect(!appSource.contains(".preferredColorScheme(.light)"))
        #expect(settingsSource.contains("@AppStorage(AppAppearancePreference.storageKey)"))
        #expect(settingsSource.contains("Picker(appearanceSystemModeTitle"))
        #expect(settingsSource.contains("Picker(appearanceManualModeTitle"))
        #expect(settingsSource.contains("AppAppearancePreference.system.rawValue"))
        #expect(settingsSource.contains("AppAppearancePreference.light.rawValue"))
        #expect(settingsSource.contains("AppAppearancePreference.dark.rawValue"))
        #expect(themeSource.contains("static func adaptiveColor(light: Color, dark: Color) -> Color"))
        #expect(themeSource.contains("static let cocoa = adaptiveColor"))
        #expect(themeSource.contains("static let fufuPlannerBackground = adaptiveColor"))
    }

    @Test("dark appearance uses macOS system gray backgrounds instead of warm brown theme colors")
    func darkAppearanceUsesSystemGrayBackgroundsInsteadOfWarmBrownThemeColors() throws {
        let root = try packageRoot()
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(themeSource.contains("static func macOSSystemColor(_ color: NSColor) -> Color"))
        #expect(themeSource.contains("macOSSystemColor(.windowBackgroundColor)"))
        #expect(themeSource.contains("macOSSystemColor(.underPageBackgroundColor)"))
        #expect(themeSource.contains("macOSSystemColor(.controlBackgroundColor)"))
        #expect(themeSource.contains("macOSSystemColor(.separatorColor)"))
        #expect(!themeSource.contains("dark: Color(red: 0.10, green: 0.06, blue: 0.045)"))
        #expect(!themeSource.contains("dark: Color(red: 0.18, green: 0.12, blue: 0.09)"))
        #expect(!themeSource.contains("dark: Color(red: 0.82, green: 0.52, blue: 0.31)"))
        #expect(!themeSource.contains("dark: Color(red: 0.520, green: 0.315, blue: 0.220)"))
    }

    @Test("dark calendar chrome uses white text and soft brown highlights instead of blue accent")
    func darkCalendarChromeUsesWhiteTextAndSoftBrownHighlightsInsteadOfBlueAccent() throws {
        let root = try packageRoot()
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)

        #expect(themeSource.contains("static let accentText = adaptiveColor"))
        #expect(themeSource.contains("static let softBrownHighlight = adaptiveColor"))
        #expect(themeSource.contains("static let pawButtonBrown = adaptiveColor"))
        #expect(themeSource.contains("static let creamRing = adaptiveColor"))
        #expect(!themeSource.contains("macOSSystemColor(.controlAccentColor)"))
        #expect(!themeSource.contains("macOSSystemColor(.selectedContentBackgroundColor)"))

        #expect(monthGridSource.contains(".foregroundStyle(MeowPlannerTheme.accentText)"))
        #expect(monthGridSource.contains("info.isFestival ? MeowPlannerTheme.blush : MeowPlannerTheme.accentText.opacity(0.86)"))
        #expect(calendarHomeSource.contains(".background(MeowPlannerTheme.pawButtonBrown, in: Circle())"))
        #expect(calendarHomeSource.contains(".stroke(MeowPlannerTheme.creamRing"))
        #expect(calendarHomeSource.contains(".foregroundStyle(MeowPlannerTheme.accentText)"))
        #expect(!calendarHomeSource.contains(".tint(MeowPlannerTheme.fufuBlue)"))
        #expect(rootViewSource.contains("SidebarSectionRow("))
        #expect(rootViewSource.contains("isSelected: selection == section"))
        #expect(rootViewSource.contains("MeowPlannerTheme.softBrownHighlight"))
    }

    @Test("segmented controls use FuFu brown tint instead of system blue")
    func segmentedControlsUseFuFuBrownTintInsteadOfSystemBlue() throws {
        let root = try packageRoot()
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")
        let pickerFiles = [
            "Sources/MeowPlannerApp/Views/Account/AccountAuthenticationModalView.swift",
            "Sources/MeowPlannerApp/Views/Focus/FocusView.swift",
            "Sources/MeowPlannerApp/Views/RootView.swift",
            "Sources/MeowPlannerApp/Views/Settings/SettingsView.swift"
        ]

        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(themeSource.contains("func fufuSegmentedPickerStyle() -> some View"))
        #expect(themeSource.contains(".pickerStyle(.segmented)"))
        #expect(themeSource.contains(".tint(MeowPlannerTheme.pawButtonBrown)"))

        for pickerFile in pickerFiles {
            let source = try String(contentsOf: root.appendingPathComponent(pickerFile), encoding: .utf8)

            #expect(source.contains(".fufuSegmentedPickerStyle()"))
            #expect(!source.contains(".pickerStyle(.segmented)"))
        }
    }

    @Test("toggles checkboxes and popup pickers use FuFu brown tint instead of system blue")
    func togglesCheckboxesAndPopupPickersUseFuFuBrownTintInsteadOfSystemBlue() throws {
        let root = try packageRoot()
        let themeSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift"),
            encoding: .utf8
        )
        let settingsSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift"),
            encoding: .utf8
        )
        let timetableSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift"),
            encoding: .utf8
        )
        let calendarSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift"),
            encoding: .utf8
        )
        let todoSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoEditorView.swift"),
            encoding: .utf8
        )
        let focusSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift"),
            encoding: .utf8
        )
        let habitsSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Habits/HabitsView.swift"),
            encoding: .utf8
        )
        let emptyStateSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Components/FuFuEmptyStateView.swift"),
            encoding: .utf8
        )

        #expect(themeSource.contains("func fufuControlTint() -> some View"))
        #expect(themeSource.contains(".tint(MeowPlannerTheme.pawButtonBrown)"))

        for marker in [
            "Toggle(PlannerCopy.text(.showDockIcon",
            "Toggle(PlannerCopy.text(.defaultAllDaySchedule",
            "Toggle(PlannerCopy.text(.hideCompletedSchedules",
            "Toggle(PlannerCopy.text(.completedScheduleStrikethrough",
            "Toggle(PlannerCopy.text(.showChineseCalendar",
            "Toggle(PlannerCopy.text(.timeCollapse",
            "Toggle(PlannerCopy.text(.localReminders",
            "Picker(PlannerCopy.text(.weekStartsOn"
        ] {
            #expect(try sourceWindow(in: settingsSource, from: marker).contains(".fufuControlTint()"))
        }

        #expect(try sourceWindow(in: timetableSource, from: "Toggle(PlannerCopy.text(.skipHolidays").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: todoSource, from: "Picker(PlannerCopy.text(.todoGroup").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: todoSource, from: "Toggle(PlannerCopy.text(.dueDate").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: calendarSource, from: "Toggle(PlannerCopy.text(.allDay").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: calendarSource, from: "Toggle(PlannerCopy.text(.multiDayTask").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: calendarSource, from: "Toggle(PlannerCopy.text(.reminder").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: calendarSource, from: "Picker(PlannerCopy.text(.repeatSchedule").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: calendarSource, from: "Toggle(PlannerCopy.text(.hasEndTime").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: focusSource, from: "Picker(PlannerCopy.text(.focusTag").contains(".fufuControlTint()"))
        #expect(try sourceWindow(in: habitsSource, from: "Picker(PlannerCopy.text(.icon").contains(".fufuControlTint()"))
        #expect(!habitsSource.contains(".tint(MeowPlannerTheme.fufuBlue)"))
        #expect(!habitsSource.contains("? MeowPlannerTheme.fufuBlue"))
        #expect(!emptyStateSource.contains(".tint(MeowPlannerTheme.fufuBlue)"))
    }

    @Test("sidebar selection uses custom row highlight instead of native blue list selection")
    func sidebarSelectionUsesCustomRowHighlightInsteadOfNativeBlueListSelection() throws {
        let root = try packageRoot()
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let macOSSidebarStart = try #require(rootViewSource.range(of: "#if os(macOS)\n        NavigationSplitView"))
        let macOSSidebarEnd = try #require(rootViewSource[macOSSidebarStart.lowerBound...].range(of: "} detail:"))
        let macOSSidebarSource = String(rootViewSource[macOSSidebarStart.lowerBound..<macOSSidebarEnd.lowerBound])
        let sidebarRowStart = try #require(rootViewSource.range(of: "private struct SidebarSectionRow: View"))
        let sidebarRowSource = String(rootViewSource[sidebarRowStart.lowerBound...])
        let selectableRowStart = try #require(rootViewSource.range(of: "private func selectableSidebarSectionRow(for section: AppSection) -> some View"))
        let selectableRowEnd = try #require(rootViewSource[selectableRowStart.lowerBound...].range(of: "private func draggableSidebarSectionRow"))
        let selectableRowSource = String(rootViewSource[selectableRowStart.lowerBound..<selectableRowEnd.lowerBound])

        #expect(!macOSSidebarSource.contains("List(selection: $selection)"))
        #expect(!macOSSidebarSource.contains(".tag(section)"))
        #expect(macOSSidebarSource.contains("sidebarSectionRow(for: section)"))
        #expect(selectableRowSource.contains("Button {"))
        #expect(selectableRowSource.contains(".buttonStyle(.plain)"))
        #expect(selectableRowSource.contains(".frame(maxWidth: .infinity, alignment: .leading)"))
        #expect(sidebarRowSource.contains(".contentShape(Rectangle())"))
        #expect(selectableRowSource.contains(".listRowInsets(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8))"))
        #expect(selectableRowSource.contains(".listRowSeparator(.hidden)"))
        #expect(macOSSidebarSource.contains(".listStyle(.plain)"))
        #expect(selectableRowSource.contains("selectSidebarSection(section)"))
        #expect(selectableRowSource.contains("SidebarSectionRow("))
        #expect(selectableRowSource.contains("isReordering: isEditingSidebarOrder"))
        #expect(sidebarRowSource.contains("Spacer(minLength: 0)"))
        #expect(rootViewSource.contains("MeowPlannerTheme.softBrownHighlight"))
    }

    @Test("settings subpage navigation resets when sidebar section changes")
    func settingsSubpageNavigationResetsWhenSidebarSectionChanges() throws {
        let root = try packageRoot()
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")

        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let selectSectionSource = try sourceWindow(
            in: rootViewSource,
            from: "private func selectSidebarSection(_ section: AppSection)",
            length: 420
        )
        let settingsSectionSource = try sourceWindow(
            in: rootViewSource,
            from: "case .settings:",
            length: 180
        )

        #expect(rootViewSource.contains("@State private var settingsNavigationPath: [SettingsDestination] = []"))
        #expect(settingsSectionSource.contains("SettingsView(navigationPath: $settingsNavigationPath)"))
        #expect(selectSectionSource.contains("settingsNavigationPath.removeAll()"))
        #expect(settingsSource.contains("enum SettingsDestination: Hashable"))
        #expect(settingsSource.contains("@Binding private var navigationPath: [SettingsDestination]"))
        #expect(settingsSource.contains("init(navigationPath: Binding<[SettingsDestination]> = .constant([]))"))
        #expect(settingsSource.contains("NavigationStack(path: $navigationPath)"))
    }

    @Test("macOS sidebar uses custom collapse and expand controls without overflow")
    func macOSSidebarUsesCustomCollapseAndExpandControlsWithoutOverflow() throws {
        let root = try packageRoot()
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let macOSSidebarStart = try #require(rootViewSource.range(of: "#if os(macOS)\n        NavigationSplitView"))
        let macOSSidebarEnd = try #require(rootViewSource[macOSSidebarStart.lowerBound...].range(of: "} detail:"))
        let macOSSidebarSource = String(rootViewSource[macOSSidebarStart.lowerBound..<macOSSidebarEnd.lowerBound])
        let detailStart = try #require(rootViewSource.range(of: "} detail: {"))
        let detailEnd = try #require(rootViewSource[detailStart.lowerBound...].range(of: "\n        .toolbar(removing: .sidebarToggle)"))
        let detailSource = String(rootViewSource[detailStart.lowerBound..<detailEnd.lowerBound])

        #expect(rootViewSource.contains("@State private var sidebarVisibility: NavigationSplitViewVisibility = .all"))
        #expect(macOSSidebarSource.contains("NavigationSplitView(columnVisibility: $sidebarVisibility)"))
        #expect(rootViewSource.contains(".toolbar(removing: .sidebarToggle)"))
        #expect(rootViewSource.contains("SidebarToolbarOverflowCleaner(trigger: sidebarVisibility)"))
        #expect(rootViewSource.contains("var trigger: NavigationSplitViewVisibility"))
        #expect(rootViewSource.contains("_ = trigger"))
        #expect(rootViewSource.contains("window.toolbar = nil"))
        #expect(rootViewSource.contains("sidebarCollapseButton"))
        #expect(rootViewSource.contains("collapsedSidebarControlBar"))
        #expect(rootViewSource.contains("private var collapsedSidebarExpandButton: some View"))
        #expect(rootViewSource.contains("private var sidebarExpandTitle: String"))
        #expect(rootViewSource.contains("expandSidebar()"))
        #expect(detailSource.contains("VStack(spacing: 0)"))
        #expect(detailSource.contains("if sidebarVisibility == .detailOnly"))
        #expect(detailSource.contains("collapsedSidebarControlBar"))
        #expect(detailSource.contains("sectionView"))
        #expect(rootViewSource.contains(".padding(.top, 16)"))
        #expect(rootViewSource.contains(".padding(.trailing, 34)"))
        #expect(detailSource.contains("sectionView"))
        #expect(!detailSource.contains(".overlay(alignment: .topTrailing)"))
        #expect(!detailSource.contains("sidebarRevealRail"))
        #expect(!rootViewSource.contains("CalendarHomeView(sidebarExpandAction:"))
        #expect(!rootViewSource.contains("private var collapsedSidebarExpandAction: (() -> Void)?"))
        #expect(calendarHomeSource.contains("scheduleDisplayFilterButton"))
        #expect(!calendarHomeSource.contains("sidebarExpandAction"))
        #expect(!calendarHomeSource.contains("headerTrailingControls"))
        #expect(!calendarHomeSource.contains("sidebarExpandTitle"))
        #expect(!calendarHomeSource.contains(".offset(y: 34)"))
        #expect(!rootViewSource.contains("private var sidebarRevealRail: some View"))
        #expect(!rootViewSource.contains(".frame(width: 64)"))
        #expect(!detailSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)"))
        #expect(!detailSource.contains(".zIndex(2)"))
        #expect(rootViewSource.contains("private func collapseSidebar()"))
        #expect(rootViewSource.contains("sidebarVisibility = .detailOnly"))
        #expect(rootViewSource.contains("private func expandSidebar()"))
        #expect(rootViewSource.contains("sidebarVisibility = .all"))
        #expect(!rootViewSource.contains("ToolbarItem(placement: .navigation)"))
        #expect(!rootViewSource.contains("Button(action: toggleSidebarVisibility)"))
        #expect(!rootViewSource.contains("Label(sidebarToggleTitle, systemImage: sidebarToggleSystemImage)"))
        #expect(!rootViewSource.contains("private func toggleSidebarVisibility()"))
    }

    @Test("main window uses FuFu chrome instead of default titlebar background")
    func mainWindowUsesFuFuChromeInsteadOfDefaultTitlebarBackground() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)

        #expect(appSource.contains("MainWindowChromeConfigurator.apply(to: window)"))
        #expect(appSource.contains("window.titlebarAppearsTransparent = true"))
        #expect(appSource.contains("window.titleVisibility = .hidden"))
        #expect(appSource.contains("window.styleMask.insert(.fullSizeContentView)"))
        #expect(appSource.contains("window.backgroundColor = NSColor(MeowPlannerTheme.fufuPlannerBackground)"))
        #expect(appSource.contains("window.titlebarSeparatorStyle = .none"))
        #expect(rootViewSource.contains(".toolbarBackground(.hidden, for: .windowToolbar)"))
        #expect(rootViewSource.contains("MainWindowChromeConfigurator.apply(to: window)"))
        #expect(rootViewSource.contains("window.toolbar = nil"))
        #expect(!rootViewSource.contains(".navigationTitle(\"MeowPlanner\")"))
        #expect(!calendarHomeSource.contains(".navigationTitle(\"MeowPlanner\")"))
    }

    @Test("app navigation removes habits and adds schedule agenda")
    func appNavigationRemovesHabitsAndAddsScheduleAgenda() throws {
        let root = try packageRoot()
        let navigationFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let menuBarFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")

        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let menuBarSource = try String(contentsOf: menuBarFile, encoding: .utf8)

        #expect(navigationSource.contains("case schedule"))
        #expect(!navigationSource.contains("case habits"))
        #expect(rootSource.contains("ScheduleAgendaView"))
        #expect(!rootSource.contains("HabitsView"))
        #expect(!menuBarSource.contains("PlannerCopy.text(.habits"))
    }

    @Test("app navigation adds standalone course timetable section")
    func appNavigationAddsStandaloneCourseTimetableSection() throws {
        let root = try packageRoot()
        let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let copyFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let copySource = try String(contentsOf: copyFile, encoding: .utf8)

        #expect(navigationSource.contains("case timetable"))
        #expect(navigationSource.contains("case calendar\n    case todo\n    case schedule\n    case timetable\n    case focus\n    case settings"))
        #expect(navigationSource.contains("PlannerCopy.text(.timetable"))
        #expect(navigationSource.contains("\"tablecells\""))
        #expect(rootSource.contains("CourseTimetableView()"))
        #expect(copySource.contains("case timetable"))
        #expect(copySource.contains(".timetable: \"Schedule\""))
        #expect(copySource.contains(".timetable: \"课程表\""))
    }

    @Test("app navigation adds standalone todo section")
    func appNavigationAddsStandaloneTodoSection() throws {
        let root = try packageRoot()
        let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let todoFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift")
        let copyFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let copySource = try String(contentsOf: copyFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: todoFile.path))
        #expect(navigationSource.contains("case todo"))
        #expect(navigationSource.contains("static let defaultSidebarOrder: [AppSection] = [\n        .calendar,\n        .todo,"))
        #expect(navigationSource.contains("PlannerCopy.text(.todo"))
        #expect(navigationSource.contains("\"checklist\""))
        #expect(rootSource.contains("TodoHomeView()"))
        #expect(copySource.contains("case allTodos"))
        #expect(copySource.contains("case defaultTodoGroup"))
        #expect(copySource.contains("case newTodoGroup"))
        #expect(copySource.contains(".allTodos: \"All\""))
        #expect(copySource.contains(".defaultTodoGroup: \"Default\""))
        #expect(copySource.contains(".todo: \"To-do\""))
        #expect(copySource.contains(".schedule: \"Agenda\""))
        #expect(copySource.contains(".timetable: \"Schedule\""))
        #expect(copySource.contains(".fufuTimePlanner: \"FuFu's time planner\""))
        #expect(copySource.contains(".allTodos: \"全部\""))
        #expect(copySource.contains(".defaultTodoGroup: \"默认\""))
    }

    @Test("todo groups expose custom colors in editor and rows")
    func todoGroupsExposeCustomColorsInEditorAndRows() throws {
        let root = try packageRoot()
        let groupFile = root.appendingPathComponent("Sources/MeowPlannerCore/Models/TodoGroup.swift")
        let plannerFile = root.appendingPathComponent("Sources/MeowPlannerCore/Services/TodoListPlanner.swift")
        let todoHomeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift")

        let groupSource = try String(contentsOf: groupFile, encoding: .utf8)
        let plannerSource = try String(contentsOf: plannerFile, encoding: .utf8)
        let todoHomeSource = try String(contentsOf: todoHomeFile, encoding: .utf8)

        #expect(groupSource.contains("public static let defaultColorHex"))
        #expect(groupSource.contains("public var colorHex: String = TodoGroup.defaultColorHex"))
        #expect(plannerSource.contains("groupColorHex"))
        #expect(todoHomeSource.contains("ColorSwatchButton("))
        #expect(todoHomeSource.contains("PaletteColorEditorView("))
        #expect(todoHomeSource.contains("openPaletteColorEditor(nil)"))
        #expect(todoHomeSource.contains("addPaletteColor"))
        #expect(todoHomeSource.contains("deletePaletteColor"))
        #expect(todoHomeSource.contains("persistPaletteColors"))
        #expect(todoHomeSource.contains("preferences.first?.eventColorHexes"))
        #expect(!todoHomeSource.contains("ColorPicker(PlannerCopy.text(.color"))
        #expect(todoHomeSource.contains("let groupColorHex = TodoListPlanner.groupColorHex"))
        #expect(todoHomeSource.contains("MeowPlannerTheme.color(hex: groupColorHex)"))
        #expect(todoHomeSource.contains("group.colorHex = colorHex"))
        #expect(!todoHomeSource.contains("group.colorHex = MeowPlannerTheme.hex(color: color)"))
    }

    @Test("todo module supports persisted drag reordering")
    func todoModuleSupportsPersistedDragReordering() throws {
        let root = try packageRoot()
        let todoModelFile = root.appendingPathComponent("Sources/MeowPlannerCore/Models/TodoItem.swift")
        let plannerFile = root.appendingPathComponent("Sources/MeowPlannerCore/Services/TodoListPlanner.swift")
        let todoHomeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift")
        let todoEditorFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoEditorView.swift")
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let todoModelSource = try String(contentsOf: todoModelFile, encoding: .utf8)
        let plannerSource = try String(contentsOf: plannerFile, encoding: .utf8)
        let todoHomeSource = try String(contentsOf: todoHomeFile, encoding: .utf8)
        let todoEditorSource = try String(contentsOf: todoEditorFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)

        #expect(todoModelSource.contains("public var sortOrder: Int?"))
        #expect(plannerSource.contains("public static func reorderedTodos("))
        #expect(todoHomeSource.contains(".draggable(todo.id.uuidString)"))
        #expect(todoHomeSource.contains(".dropDestination(for: String.self)"))
        #expect(todoHomeSource.contains("private func moveTodo"))
        #expect(todoHomeSource.contains("TodoListPlanner.reorderedTodos"))
        #expect(todoHomeSource.contains("TodoListPlanner.reorderedTodosAfterCompletionChange"))
        #expect(todoEditorSource.contains("defaultSortOrder"))
        #expect(todoEditorSource.contains("sortOrder: defaultSortOrder"))
        #expect(rootSource.contains("String(todo.sortOrder ?? -1)"))
    }

    @Test("settings header localizes FuFu planner subtitle")
    func settingsHeaderLocalizesFuFuPlannerSubtitle() throws {
        let root = try packageRoot()
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)

        #expect(settingsSource.contains("PlannerCopy.text(.fufuTimePlanner, language: appLanguage)"))
        #expect(!settingsSource.contains("Text(\"FuFu 的喵系时间规划器\")"))
    }

    @Test("macOS sidebar supports persisted drag reordering")
    func macOSSidebarSupportsPersistedDragReordering() throws {
        let root = try packageRoot()
        let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)

        #expect(navigationSource.contains("defaultSidebarOrder"))
        #expect(navigationSource.contains("orderedSections(from storageValue:"))
        #expect(navigationSource.contains("sidebarStorageValue"))
        #expect(rootSource.contains("@AppStorage(\"meowplanner.sidebar.sectionOrder\")"))
        #expect(rootSource.contains("ForEach(orderedSections)"))
        #expect(rootSource.contains(".draggable(section.rawValue)"))
        #expect(rootSource.contains(".dropDestination(for: String.self)"))
        #expect(rootSource.contains("sidebarBottomDropTarget"))
        #expect(rootSource.contains("moveSidebarSection(draggedRawValue: draggedRawValue, before: section)"))
        #expect(rootSource.contains("moveSidebarSection(draggedRawValue: draggedRawValue, before: nil)"))
        #expect(rootSource.contains("private func moveSidebarSection(draggedRawValue: String, before targetSection: AppSection?) -> Bool"))
        #expect(rootSource.contains("sidebarSectionOrderRaw = AppSection.sidebarStorageValue(for: reordered)"))
    }

    @Test("macOS sidebar reorder handles are actual drag sources and drop targets")
    func macOSSidebarReorderHandlesAreActualDragSourcesAndDropTargets() throws {
        let root = try packageRoot()
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let macOSSidebarStart = try #require(rootSource.range(of: "#if os(macOS)\n        NavigationSplitView"))
        let macOSSidebarEnd = try #require(rootSource[macOSSidebarStart.lowerBound...].range(of: "} detail:"))
        let macOSSidebarSource = String(rootSource[macOSSidebarStart.lowerBound..<macOSSidebarEnd.lowerBound])

        #expect(macOSSidebarSource.contains("sidebarSectionRow(for: section)"))
        #expect(rootSource.contains("@State private var sidebarDropTargetSection: AppSection?"))
        #expect(rootSource.contains("private func sidebarSectionRow(for section: AppSection) -> some View"))
        #expect(rootSource.contains("private func draggableSidebarSectionRow(for section: AppSection) -> some View"))
        #expect(rootSource.contains(".draggable(section.rawValue)"))
        #expect(rootSource.contains("SidebarDragPreviewView("))
        #expect(rootSource.contains(".dropDestination(for: String.self)"))
        #expect(rootSource.contains("sidebarDropTargetSection = isTargeted ? section : nil"))
        #expect(rootSource.contains(".scaleEffect(sidebarDropTargetSection == section ? 1.015 : 1)"))
        #expect(rootSource.contains("guard !isEditingSidebarOrder else"))
        #expect(!rootSource.contains(".onMove(perform: moveSidebarSections)"))
    }

    @Test("macOS sidebar exposes an explicit reorder edit button")
    func macOSSidebarExposesExplicitReorderEditButton() throws {
        let root = try packageRoot()
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let macOSSidebarStart = try #require(rootSource.range(of: "#if os(macOS)\n        NavigationSplitView"))
        let macOSSidebarEnd = try #require(rootSource[macOSSidebarStart.lowerBound...].range(of: "} detail:"))
        let macOSSidebarSource = String(rootSource[macOSSidebarStart.lowerBound..<macOSSidebarEnd.lowerBound])
        let sidebarRowStart = try #require(rootSource.range(of: "private struct SidebarSectionRow: View"))
        let sidebarRowSource = String(rootSource[sidebarRowStart.lowerBound...])

        #expect(rootSource.contains("@State private var isEditingSidebarOrder = false"))
        #expect(macOSSidebarSource.contains("sidebarHeader"))
        #expect(rootSource.contains("private func draggableSidebarSectionRow(for section: AppSection) -> some View"))
        #expect(rootSource.contains("guard isEditingSidebarOrder,"))
        #expect(rootSource.contains("private var sidebarOrderEditButton: some View"))
        #expect(rootSource.contains("toggleSidebarOrderEditing()"))
        #expect(rootSource.contains("isEditingSidebarOrder.toggle()"))
        #expect(rootSource.contains("private var sidebarOrderEditTitle: String"))
        #expect(rootSource.contains("appLanguage == .chinese ? \"自定义顺序\" : \"Customize order\""))
        #expect(rootSource.contains("appLanguage == .chinese ? \"完成\" : \"Done\""))
        #expect(rootSource.contains("SidebarSectionRow("))
        #expect(rootSource.contains("isReordering: isEditingSidebarOrder"))
        #expect(sidebarRowSource.contains("var isReordering: Bool"))
        #expect(sidebarRowSource.contains("Image(systemName: \"line.3.horizontal\")"))
        #expect(navigationSource.contains("case .schedule: PlannerCopy.text(.timeline"))
    }

    @Test("global toolbar add button is removed")
    func globalToolbarAddButtonIsRemoved() throws {
        let root = try packageRoot()
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)

        #expect(!rootSource.contains("shouldShowPrimaryToolbarAddButton"))
        #expect(!rootSource.contains("Label(PlannerCopy.text(.newSchedule"))
        #expect(!rootSource.contains("systemImage: \"plus\""))
    }

    @Test("course timetable view exposes semester setup form")
    func courseTimetableViewExposesSemesterSetupForm() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        #expect(FileManager.default.fileExists(atPath: timetableFile.path))
        let source = try String(contentsOf: timetableFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)

        #expect(source.contains("struct CourseTimetableView"))
        #expect(source.contains("CourseTimetableSetupView"))
        #expect(source.contains("@Query(sort: \\CourseTimetable.createdAt"))
        #expect(source.contains("CourseTimetablePlanner.defaultPeriods"))
        #expect(source.contains("PlannerCopy.text(.timetableName"))
        #expect(source.contains("PlannerCopy.text(.semesterStartDate"))
        #expect(source.contains("PlannerCopy.text(.semesterWeeks"))
        #expect(source.contains("PlannerCopy.text(.periodsPerDay"))
        #expect(source.contains("PlannerCopy.text(.lessonDuration"))
        #expect(source.contains("PlannerCopy.text(.breakDuration"))
        #expect(source.contains("PlannerCopy.text(.skipHolidays"))
        #expect(source.contains("timetable: CourseTimetable? = nil"))
        #expect(source.contains("dismissOnSave: Bool = true"))
        #expect(source.contains("CourseTimetableSetupView(onSave: { timetableID in"))
        #expect(source.contains("}, dismissOnSave: false)"))
        #expect(source.contains("alignment: .center"))
        #expect(source.contains("timetableSetupHeader"))
        #expect(source.contains(".frame(maxWidth: 920"))
        #expect(source.contains(".frame(minWidth: 760, minHeight: 640"))
        #expect(source.contains("if dismissOnSave"))
        #expect(source.contains("saveTimetable"))
        #expect(project.contains("Sources/MeowPlannerCore/Models/CourseTimetable.swift"))
        #expect(project.contains("Sources/MeowPlannerCore/Services/CourseTimetablePlanner.swift"))
        #expect(project.contains("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift"))
    }

    @Test("course timetable renders standard weekly class grid")
    func courseTimetableRendersStandardWeeklyClassGrid() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let source = try String(contentsOf: timetableFile, encoding: .utf8)

        #expect(source.contains("CourseTimetableGridView"))
        #expect(source.contains("weekdayHeader"))
        #expect(source.contains("periodRows"))
        #expect(source.contains("courseBlock"))
        #expect(source.contains("courseBlockHeight"))
        #expect(source.contains("selectedWeek"))
        #expect(source.contains("W\\(selectedWeek)"))
        #expect(source.contains("visibleSessions"))
        #expect(source.contains("isSkippedHoliday"))
        #expect(source.contains("CourseTimetablePlanner.weekNumber"))
        #expect(source.contains("CourseTimetablePlanner.weekDates(forWeek: selectedWeek"))
        #expect(source.contains("@Query private var preferences: [PlannerPreference]"))
        #expect(source.contains("weekStartPreference.configuredCalendar"))
        #expect(source.contains("onEditCourse"))
        #expect(source.contains(".onTapGesture(count: 2)"))
        #expect(source.contains("editingCourseID = course.id"))
        #expect(source.contains("CourseEditorView("))
        #expect(source.contains("course: editingCourse"))
        #expect(source.contains("ChineseCalendarInfoProvider.info"))
        #expect(source.contains("skipHolidays"))
    }

    @Test("course timetable supports multiple selectable schedules and settings editing")
    func courseTimetableSupportsMultipleSelectableSchedulesAndSettingsEditing() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let source = try String(contentsOf: timetableFile, encoding: .utf8)

        #expect(source.contains("@State private var selectedTimetableID: UUID?"))
        #expect(source.contains("selectedTimetable"))
        #expect(source.contains("timetableTitleMenu"))
        #expect(source.contains("ForEach(timetables) { option in"))
        #expect(source.contains("selectedTimetableID = option.id"))
        #expect(source.contains("showingTimetableCreator"))
        #expect(source.contains("showingTimetableSettingsEditor"))
        #expect(source.contains("CourseTimetableSetupView(timetable: timetable"))
        #expect(source.contains("onDelete: handleTimetableDeleted"))
        #expect(source.contains("deleteTimetable"))
        #expect(source.contains("modelContext.delete(timetable)"))
        #expect(source.contains("role: .destructive"))
        #expect(source.contains("timetableToolbarButton(systemImage: \"square.and.pencil\""))
        #expect(source.contains("selectedWeek = 1"))
    }

    @Test("course timetable forms use unified FuFu theme and date picker")
    func courseTimetableFormsUseUnifiedFuFuThemeAndDatePicker() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let source = try String(contentsOf: timetableFile, encoding: .utf8)

        #expect(source.contains("TimetableDatePickerRow"))
        #expect(source.contains("TimetableInlineDatePickerPanel"))
        #expect(source.contains("timetableFormCard"))
        #expect(source.contains("MeowPlannerTheme.fufuPlannerBackground"))
        #expect(source.contains("timetableBackgroundMotifs"))
        #expect(source.contains("timetableSetupHeader"))
        #expect(source.contains("FuFuAssetImage(size: 72)"))
        #expect(source.contains("displayedComponents: .hourAndMinute"))
        #expect(source.contains("ChineseCalendarInfoProvider.info"))
        #expect(source.contains(".background(MeowPlannerTheme.fufuPlannerBackground"))
        #expect(!source.contains(".background(MeowPlannerTheme.plannerGradient)"))
    }

    @Test("course timetable adopts reference FuFu theme layout")
    func courseTimetableAdoptsReferenceFuFuThemeLayout() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let source = try String(contentsOf: timetableFile, encoding: .utf8)

        #expect(source.contains("timetableReferenceBackground"))
        #expect(source.contains("@State private var showingWeekPicker = false"))
        #expect(source.contains("weekPickerButton"))
        #expect(source.contains("weekPickerSheet"))
        #expect(source.contains("timetableTitleMenu"))
        #expect(source.contains("timetableGridHeaderIdentity"))
        #expect(source.contains("FuFuAssetImage(size: 58)"))
        #expect(source.contains(".font(.largeTitle.bold())"))
        #expect(source.contains("timetableToolbarButton(systemImage: \"square.and.pencil\""))
        #expect(source.contains("sideDateColumn"))
        #expect(source.contains("periodLabel(for: period)"))
        #expect(source.contains("timetableWatermarks"))
        #expect(source.contains("Image(systemName: \"pawprint.fill\""))
        #expect(source.contains("MeowPlannerTheme.fufuCalendarBackground.opacity(0.34)"))
        #expect(source.contains(".foregroundStyle(MeowPlannerTheme.caramel)"))
        #expect(!source.contains("DragGesture(minimumDistance: 28)"))
        #expect(source.contains("HorizontalSwipeScrollDetector"))
        #expect(source.contains("switchWeek(by: horizontal < 0 ? 1 : -1)"))
        #expect(source.contains("switchWeek(by:"))
        #expect(source.contains("weekDateRangeText(for: week)"))
        #expect(!source.contains("timetableToolbarButton(systemImage: \"square.and.arrow.up\""))
        #expect(!source.contains("shareTimetableSummary"))
        #expect(!source.contains("Image(systemName: \"star\""))
    }

    @Test("horizontal swipe detector fires once per gesture and ignores momentum")
    func horizontalSwipeDetectorFiresOncePerGestureAndIgnoresMomentum() throws {
        let root = try packageRoot()
        let themeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")
        let source = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(source.contains("struct HorizontalSwipeScrollDetector"))
        #expect(source.contains("didTriggerForCurrentSwipe"))
        #expect(source.contains("event.momentumPhase != []"))
        #expect(source.contains("scheduleIdleReset()"))
        #expect(source.contains("guard !didTriggerForCurrentSwipe"))
        #expect(source.contains("didTriggerForCurrentSwipe = true"))
    }

    @Test("course editor captures course metadata and sessions")
    func courseEditorCapturesCourseMetadataAndSessions() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let source = try String(contentsOf: timetableFile, encoding: .utf8)

        #expect(source.contains("struct CourseEditorView"))
        #expect(source.contains("course: Course? = nil"))
        #expect(source.contains("courseSessions: [CourseSession] = []"))
        #expect(source.contains("PlannerCopy.text(.cancel"))
        #expect(source.contains("cancelCourseEdit"))
        #expect(source.contains("editorTitle"))
        #expect(source.contains("selectedWeekdays"))
        #expect(source.contains("startPeriodIndex"))
        #expect(source.contains("endPeriodIndex"))
        #expect(source.contains("startWeek"))
        #expect(source.contains("endWeek"))
        #expect(source.contains("teacherName"))
        #expect(source.contains("location"))
        #expect(source.contains("PlannerCopy.text(.addOtherSessions"))
        #expect(source.contains("modelContext.insert(course)"))
        #expect(source.contains("course.updatedAt = Date()"))
        #expect(source.contains("modelContext.delete(session)"))
        #expect(source.contains("modelContext.insert(session)"))
    }

    @Test("schedule agenda supports daily and weekly schedule tables")
    func scheduleAgendaSupportsDailyAndWeeklyScheduleTables() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)

        #expect(rootSource.contains("private struct ScheduleAgendaView"))
        #expect(rootSource.contains("ScheduleAgendaMode"))
        #expect(rootSource.contains("case daily"))
        #expect(rootSource.contains("case weekly"))
        #expect(rootSource.contains("Picker(PlannerCopy.text(.scheduleView"))
        #expect(rootSource.contains("scheduleModePicker"))
        #expect(rootSource.contains("FuFuAssetImage(size: 58)"))
        #expect(rootSource.contains("HorizontalSwipeScrollDetector"))
        #expect(rootSource.contains("ScheduleDatePickerPanel"))
        #expect(rootSource.contains(".popover(isPresented: $showingScheduleDatePicker"))
        #expect(!rootSource.contains("scheduleSwipeGesture"))
        #expect(rootSource.contains("moveDate(by: horizontal < 0 ? 1 : -1)"))
        #expect(!rootSource.contains("private var dateControls"))
        #expect(!rootSource.contains("DatePicker(\"\", selection: $selectedDate, displayedComponents: .date)"))
        #expect(rootSource.contains("events(on:"))
        #expect(rootSource.contains("weekDates"))
    }

    @Test("schedule agenda renders warm hourly timeline with collapsible early morning")
    func scheduleAgendaRendersWarmHourlyTimelineWithCollapsibleEarlyMorning() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)

        #expect(rootSource.contains("ScheduleTimeGridView"))
        #expect(rootSource.contains("allDayLane"))
        #expect(rootSource.contains("currentTimeLine"))
        #expect(rootSource.contains("eventBlock"))
        #expect(rootSource.contains("hourRowHeight"))
        #expect(rootSource.contains("visibleHours"))
        #expect(rootSource.contains("earlyMorningHours"))
        #expect(rootSource.contains("isEarlyMorningExpanded"))
        #expect(rootSource.contains("collapsedStartHour"))
        #expect(rootSource.contains("collapsedEndHour"))
        #expect(rootSource.contains("timeDisplayPreference"))
        #expect(rootSource.contains("formatHour("))
        #expect(rootSource.contains("formatTime("))
        #expect(rootSource.contains("preferences.first?.scheduleCollapsedStartHour"))
        #expect(rootSource.contains("preferences.first?.scheduleCollapsedEndHour"))
        #expect(rootSource.contains("MeowPlannerTheme.fufuPlannerBackground"))
        #expect(rootSource.contains("scheduleBackgroundMotifs"))
        #expect(rootSource.contains("FuFuAssetImage(size: 58)"))
        #expect(!rootSource.contains("private let earlyMorningHours = Array(0..<6)"))
        #expect(!rootSource.contains("Text(\"0:00-6:00\")"))
        #expect(!rootSource.contains("dayScheduleSection(for:"))
    }

    @Test("settings exposes week start preference for app and widget")
    func settingsExposesWeekStartPreferenceForAppAndWidget() throws {
        let root = try packageRoot()
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(settingsSource.contains("weekStartPreference"))
        #expect(settingsSource.contains("WeekStartPreference.allCases"))
        #expect(settingsSource.contains("scheduleCollapsedStartHour"))
        #expect(settingsSource.contains("scheduleCollapsedEndHour"))
        #expect(settingsSource.contains("timeDisplayPreference"))
        #expect(settingsSource.contains("TimeDisplayPreference.allCases"))
        #expect(settingsSource.contains("WidgetPlannerPreferenceStore.weekStartPreference = newValue"))
        #expect(settingsSource.contains("preference.localRemindersEnabled = newValue"))
        #expect(monthGridSource.contains("@Query private var preferences: [PlannerPreference]"))
        #expect(monthGridSource.contains("weekStartPreference.configuredCalendar"))
        #expect(monthGridSource.contains("ForEach(Array(weekdaySymbols.enumerated()), id: \\.offset)"))
        #expect(monthGridSource.contains("HorizontalSwipeScrollDetector"))
        #expect(monthGridSource.contains("moveMonth(by: horizontal < 0 ? 1 : -1)"))
        #expect(!monthGridSource.contains("DragGesture(minimumDistance: 28)"))
    }

    @Test("settings groups preferences and uses collapsible time controls")
    func settingsGroupsPreferencesAndUsesCollapsibleTimeControls() throws {
        let root = try packageRoot()
        let settingsSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift"),
            encoding: .utf8
        )
        let preferenceSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerCore/Models/PlannerPreference.swift"),
            encoding: .utf8
        )
        let languageSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift"),
            encoding: .utf8
        )
        let rootSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift"),
            encoding: .utf8
        )

        #expect(settingsSource.contains("Section(PlannerCopy.text(.language"))
        #expect(settingsSource.contains("Section(appearanceSectionTitle"))
        #expect(settingsSource.contains("Section(PlannerCopy.text(.focusSettings"))
        #expect(settingsSource.contains("range: 0...Int.max"))
        #expect(!settingsSource.contains("range: 5...90"))
        #expect(settingsSource.contains("Section(PlannerCopy.text(.personalizationSettings"))
        #expect(settingsSource.contains("Toggle(PlannerCopy.text(.timeCollapse"))
        #expect(settingsSource.contains("timeCollapseSettingsButton"))
        #expect(settingsSource.contains(".popover(isPresented: $showingTimeCollapsePanel"))
        #expect(settingsSource.contains("showingTimeCollapsePanel = true"))
        #expect(settingsSource.contains("timeCollapseSettingsPanel"))
        #expect(settingsSource.contains("PlannerCopy.text(.eventColors"))
        #expect(settingsSource.contains(".padding(.horizontal, 12)"))
        #expect(preferenceSource.contains("scheduleTimeCollapseEnabled"))
        #expect(languageSource.contains("case focusSettings"))
        #expect(languageSource.contains("case personalizationSettings"))
        #expect(languageSource.contains("case timeCollapse"))
        #expect(languageSource.contains(".eventColors: \"Colors\""))
        #expect(languageSource.contains(".eventColors: \"颜色\""))
        #expect(rootSource.contains("scheduleTimeCollapseEnabled"))
        #expect(rootSource.contains("timeCollapseEnabled: scheduleTimeCollapseEnabled"))
        #expect(rootSource.contains("if timeCollapseEnabled"))
        #expect(rootSource.contains("if !timeCollapseEnabled || isEarlyMorningExpanded"))
    }

    @Test("primary page scroll containers disable horizontal page scrolling")
    func primaryPageScrollContainersDisableHorizontalPageScrolling() throws {
        let root = try packageRoot()
        let themeSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift"),
            encoding: .utf8
        )
        let calendarSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift"),
            encoding: .utf8
        )
        let todoSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift"),
            encoding: .utf8
        )
        let rootSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift"),
            encoding: .utf8
        )
        let timetableSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift"),
            encoding: .utf8
        )
        let settingsSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift"),
            encoding: .utf8
        )
        let habitsSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Habits/HabitsView.swift"),
            encoding: .utf8
        )
        let focusSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift"),
            encoding: .utf8
        )

        #expect(themeSource.contains("struct VerticalOnlyScrollConfigurator"))
        #expect(themeSource.contains("horizontalScrollElasticity = .none"))
        #expect(themeSource.contains("hasHorizontalScroller = false"))
        #expect(themeSource.contains("documentFrame.origin.x = 0"))
        #expect(themeSource.contains("scrollView.documentView?.frame = documentFrame"))
        #expect(calendarSource.contains("ScrollView(.vertical)"))
        #expect(calendarSource.contains(".verticalPageScrollOnly()"))
        #expect(todoSource.contains("ScrollView(.vertical)"))
        #expect(todoSource.contains(".verticalPageScrollOnly()"))
        #expect(rootSource.contains(".verticalPageScrollOnly()"))
        #expect(timetableSource.contains(".verticalPageScrollOnly()"))
        #expect(focusSource.contains("ScrollView(.vertical)"))
        #expect(focusSource.contains(".verticalPageScrollOnly()"))
        #expect(settingsSource.contains(".verticalPageScrollOnly()"))
        #expect(habitsSource.contains("ScrollView(.vertical)"))
        #expect(habitsSource.contains(".verticalPageScrollOnly()"))
    }

    @Test("settings exposes completed schedule display preferences")
    func settingsExposesCompletedScheduleDisplayPreferences() throws {
        let root = try packageRoot()
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let preferenceFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Models/PlannerPreference.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let preferenceSource = try String(contentsOf: preferenceFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)

        #expect(preferenceSource.contains("showCompletedSchedules"))
        #expect(preferenceSource.contains("completedSchedulesUseStrikethrough"))
        #expect(settingsSource.contains("@State private var showCompletedSchedules"))
        #expect(settingsSource.contains("@State private var hideCompletedSchedules"))
        #expect(settingsSource.contains("@State private var completedSchedulesUseStrikethrough"))
        #expect(settingsSource.contains("PlannerCopy.text(.hideCompletedSchedules"))
        #expect(settingsSource.contains("PlannerCopy.text(.completedScheduleStrikethrough"))
        #expect(settingsSource.contains("preference.showCompletedSchedules = !newValue"))
        #expect(settingsSource.contains("preference.completedSchedulesUseStrikethrough = newValue"))
        #expect(languageSource.contains("case hideCompletedSchedules"))
        #expect(languageSource.contains("case showCompletedSchedules"))
        #expect(languageSource.contains("case completedScheduleStrikethrough"))
    }

    @Test("calendar and schedule surfaces honor completed schedule display settings")
    func calendarAndScheduleSurfacesHonorCompletedScheduleDisplaySettings() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let dayAgendaFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let coreWidgetSnapshotFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let dayAgendaSource = try String(contentsOf: dayAgendaFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let coreWidgetSnapshotSource = try String(contentsOf: coreWidgetSnapshotFile, encoding: .utf8)

        #expect(homeSource.contains("showCompletedSchedules"))
        #expect(homeSource.contains("completedSchedulesUseStrikethrough"))
        #expect(homeSource.contains("displayedEvents"))
        #expect(homeSource.contains("completedLastEvents"))
        #expect(homeSource.contains("showCompletedSchedules || !event.isCompleted"))
        #expect(dayAgendaSource.contains("completedSchedulesUseStrikethrough"))
        #expect(dayAgendaSource.contains(".strikethrough(isCompleted && completedSchedulesUseStrikethrough)"))
        #expect(monthGridSource.contains("completedSchedulesUseStrikethrough"))
        #expect(monthGridSource.contains(".strikethrough(item.isCompleted && completedSchedulesUseStrikethrough)"))
        #expect(rootSource.contains("showCompletedSchedules"))
        #expect(rootSource.contains("completedSchedulesUseStrikethrough"))
        #expect(rootSource.contains("String(widgetPreference.showCompletedSchedules)"))
        #expect(rootSource.contains("String(widgetPreference.completedSchedulesUseStrikethrough)"))
        #expect(rootSource.contains("showCompletedSchedules || !event.isCompleted"))
        #expect(rootSource.contains(".strikethrough(event.isCompleted && completedSchedulesUseStrikethrough)"))
        #expect(coreWidgetSnapshotSource.contains("showCompletedSchedules: preference.showCompletedSchedules"))
        #expect(coreWidgetSnapshotSource.contains("completedSchedulesUseStrikethrough: preference.completedSchedulesUseStrikethrough"))
        #expect(widgetSource.contains("completedSchedulesUseStrikethrough"))
        #expect(widgetSource.contains("snapshot?.showCompletedSchedules ?? true"))
        #expect(widgetSource.contains("showCompletedSchedules || !$0.isCompleted"))
        #expect(widgetSource.contains(".strikethrough(item.isCompleted && entry.completedSchedulesUseStrikethrough)"))
        #expect(widgetSource.contains("private var completedEventPillOpacity"))
        #expect(widgetSource.contains(".opacity(item.isCompleted ? completedEventPillOpacity : 1)"))
    }

    @Test("calendar surface no longer owns todo creation or todo rows")
    func calendarSurfaceNoLongerOwnsTodoCreationOrTodoRows() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let dayAgendaFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift")
        let todoEditorFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoEditorView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let dayAgendaSource = try String(contentsOf: dayAgendaFile, encoding: .utf8)
        let todoEditorSource = try String(contentsOf: todoEditorFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: todoEditorFile.path))
        #expect(!homeSource.contains("@Query(sort: \\TodoItem.createdAt)"))
        #expect(!homeSource.contains("showingTodoEditor"))
        #expect(!homeSource.contains("editingTodo"))
        #expect(!homeSource.contains("TodoEditorView"))
        #expect(!homeSource.contains("completeTodo"))
        #expect(!homeSource.contains("deleteTodo"))
        #expect(!dayAgendaSource.contains("var todos: [TodoItem]"))
        #expect(!dayAgendaSource.contains("onAddTodo"))
        #expect(!dayAgendaSource.contains("onCompleteTodo"))
        #expect(!dayAgendaSource.contains("onDeleteTodo"))
        #expect(todoEditorSource.contains("struct TodoEditorView"))
        #expect(todoEditorSource.contains("Picker(PlannerCopy.text(.todoGroup"))
        #expect(todoEditorSource.contains("todo.groupID = selectedGroupID"))
    }

    @Test("app and widget render Chinese calendar information")
    func appAndWidgetRenderChineseCalendarInformation() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let dayAgendaFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift")
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let providerFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Services/ChineseCalendarInfoProvider.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let dayAgendaSource = try String(contentsOf: dayAgendaFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: providerFile.path))
        #expect(monthGridSource.contains("chineseCalendarBadge(day.chineseCalendarInfo)"))
        #expect(monthGridSource.contains("info.isFestival"))
        #expect(dayAgendaSource.contains("ChineseCalendarInfoProvider.info(for: selectedDate"))
        #expect(rootSource.contains("ChineseCalendarInfoProvider.info(for: selectedDate"))
        #expect(widgetSource.contains("day.chineseCalendarInfo.displayText"))
        #expect(widgetSource.contains("day.chineseCalendarInfo.isFestival"))
        #expect(widgetSource.contains("ChineseCalendarInfoProvider.info(for: entry.date"))
        #expect(widgetSource.contains("if entry.showChineseCalendar"))
    }

    @Test("settings can disable Chinese calendar information")
    func settingsCanDisableChineseCalendarInformation() throws {
        let root = try packageRoot()
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let preferenceFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Models/PlannerPreference.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")
        let weekStartFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let dayAgendaFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift")
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let preferenceSource = try String(contentsOf: preferenceFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let weekStartSource = try String(contentsOf: weekStartFile, encoding: .utf8)
        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let dayAgendaSource = try String(contentsOf: dayAgendaFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)

        #expect(preferenceSource.contains("showChineseCalendar"))
        #expect(settingsSource.contains("@State private var showChineseCalendar"))
        #expect(settingsSource.contains("PlannerCopy.text(.showChineseCalendar"))
        #expect(settingsSource.contains("preference.showChineseCalendar = newValue"))
        #expect(settingsSource.contains("WidgetPlannerPreferenceStore.showChineseCalendar = newValue"))
        #expect(languageSource.contains("case showChineseCalendar"))
        #expect(weekStartSource.contains("showChineseCalendarKey"))
        #expect(weekStartSource.contains("public static var showChineseCalendar"))
        #expect(homeSource.contains("showChineseCalendar"))
        #expect(homeSource.contains("showChineseCalendar: showChineseCalendar"))
        #expect(monthGridSource.contains("var showChineseCalendar: Bool = true"))
        #expect(monthGridSource.contains("if showChineseCalendar"))
        #expect(dayAgendaSource.contains("var showChineseCalendar: Bool = true"))
        #expect(dayAgendaSource.contains("if showChineseCalendar"))
        #expect(rootSource.contains("showChineseCalendar"))
        #expect(rootSource.contains("if showChineseCalendar"))
        #expect(widgetSource.contains("snapshot?.showChineseCalendar ?? true"))
        #expect(widgetSource.contains("entry.showChineseCalendar"))
    }

    @Test("settings manages custom event color palette")
    func settingsManagesCustomEventColorPalette() throws {
        let root = try packageRoot()
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let preferenceFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Models/PlannerPreference.swift")
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let preferenceSource = try String(contentsOf: preferenceFile, encoding: .utf8)
        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)

        #expect(preferenceSource.contains("defaultEventColorHexes"))
        #expect(preferenceSource.contains("#F57C6E"))
        #expect(preferenceSource.contains("#F2A7DA"))
        #expect(settingsSource.contains("eventColorHexes"))
        #expect(settingsSource.contains("addEventColor"))
        #expect(settingsSource.contains("deleteEventColor"))
        #expect(settingsSource.contains("activeSettingsSheet = .eventColorEditor"))
        #expect(!settingsSource.contains("showingEventColorEditor"))
        #expect(settingsSource.contains("SettingsEventColorEditorView"))
        #expect(settingsSource.contains("ScrollView(.horizontal"))
        #expect(settingsSource.contains("SettingsEventColorSwatch"))
        #expect(settingsSource.contains("contextMenu"))
        #expect(settingsSource.contains("onEdit: { openEventColorEditor(colorHex) }"))
        #expect(settingsSource.contains("Label(PlannerCopy.text(.editColor"))
        #expect(settingsSource.contains("updateEventColor(from: originalColorHex, to: colorHex)"))
        #expect(settingsSource.contains("Button(role: .destructive)"))
        #expect(settingsSource.contains("Image(systemName: \"plus.circle.fill\")"))
        #expect(!settingsSource.contains("Text(colorHex)"))
        #expect(!settingsSource.contains("TextField(\"#F57C6E\", text: $newEventColorHexInput)"))
        #expect(languageSource.contains("case editColor"))
        #expect(languageSource.contains(".editColor: \"Edit color\""))
        #expect(languageSource.contains(".editColor: \"编辑颜色\""))
        #expect(homeSource.contains("@Query private var preferences: [PlannerPreference]"))
        #expect(homeSource.contains("preferences.first?.eventColorHexes"))
        #expect(homeSource.contains("syncInitialColorWithPalette"))
        #expect(!homeSource.contains("private static let eventColorOptions"))
    }

    @Test("calendar surface has cute styling floating add and event metadata controls")
    func calendarSurfaceHasCuteStylingFloatingAddAndEventMetadataControls() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let dayAgendaFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let dayAgendaSource = try String(contentsOf: dayAgendaFile, encoding: .utf8)

        #expect(homeSource.contains("floatingAddScheduleButton"))
        #expect(homeSource.contains(".overlay(alignment: .bottomTrailing)"))
        #expect(homeSource.contains("openEventEditor(on date:"))
        #expect(monthGridSource.contains("onDayDoubleClick"))
        #expect(monthGridSource.contains("onEventDoubleClick"))
        #expect(homeSource.contains("onEventDoubleClick: editEvent"))
        #expect(monthGridSource.contains("TapGesture(count: 2)"))
        #expect(homeSource.contains("tagName"))
        #expect(homeSource.contains("@State private var selectedEventTagName: String?"))
        #expect(homeSource.contains("selectedEventTagName == nil || event.tagName == selectedEventTagName"))
        #expect(homeSource.contains("scheduleDisplayFilterButton"))
        #expect(homeSource.contains("ScheduleDisplayTagFilterMenu"))
        #expect(homeSource.contains("PlannerCopy.text(.scheduleDisplay"))
        #expect(homeSource.contains("PlannerCopy.text(.allSchedules"))
        #expect(homeSource.contains("colorHex"))
        #expect(homeSource.contains("eventColorOptions"))
        #expect(homeSource.contains("repeatRuleSelection"))
        #expect(homeSource.contains("RepeatRuleSelection.allCases"))
        #expect(homeSource.contains("repeatRule = repeatRuleSelection.rule(for: normalizedStartDate"))
        #expect(homeSource.contains("TagSelectionSheet"))
        #expect(homeSource.contains("showingTagSelector"))
        #expect(homeSource.contains("addEventTag"))
        #expect(homeSource.contains("preferences.first?.eventTagNames"))
        #expect(homeSource.contains("defaultEventIsAllDay"))
        #expect(homeSource.contains("localRemindersEnabled"))
        #expect(homeSource.contains("ColorSwatchButton"))
        #expect(homeSource.contains("onSelect: { applyColorHex(option) }"))
        #expect(homeSource.contains(".contextMenu"))
        #expect(homeSource.contains("onDelete"))
        #expect(monthGridSource.contains("calendarWatermark"))
        #expect(monthGridSource.contains("HorizontalSwipeScrollDetector"))
        #expect(monthGridSource.contains("MeowPlannerTheme.color(hex: item.colorHex)"))
        #expect(!monthGridSource.contains("Text(item.tagName)"))
        #expect(!monthGridSource.contains("if !item.tagName.isEmpty"))
        #expect(dayAgendaSource.contains("DayAgendaView"))
        #expect(!dayAgendaSource.contains(".background(.regularMaterial"))
    }

    @Test("calendar floating add button scales with window and keeps equal edge limits")
    func calendarFloatingAddButtonScalesWithWindowAndKeepsEqualEdgeLimits() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)

        #expect(homeSource.contains("let buttonSize = floatingAddButtonSize(for: proxy.size)"))
        #expect(homeSource.contains("let inset = calendarFloatingAddButtonEdgeInset(for: buttonSize)"))
        #expect(homeSource.contains("floatingAddScheduleButton(size: buttonSize)"))
        #expect(homeSource.contains("private func floatingAddButtonSize(for availableSize: CGSize) -> CGFloat"))
        #expect(homeSource.contains("private func calendarFloatingAddButtonEdgeInset(for buttonSize: CGFloat) -> CGFloat"))
        #expect(homeSource.contains("private func floatingAddScheduleButton(size: CGFloat) -> some View"))
        #expect(homeSource.contains("let shortSide = min(availableSize.width, availableSize.height)"))
        #expect(homeSource.contains("let iconSize = size * 24 / 62"))
        #expect(!homeSource.contains("let buttonSize: CGFloat = 62"))
        #expect(!homeSource.contains("let inset: CGFloat = 28"))
        #expect(!homeSource.contains(".frame(width: 62, height: 62)"))
    }

    @Test("event editor uses a FuFu themed date picker row")
    func eventEditorUsesFuFuThemedDatePickerRow() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)

        #expect(homeSource.contains("FuFuDatePickerRow"))
        #expect(homeSource.contains("datePickerRows"))
        #expect(homeSource.contains("FuFuInlineDatePickerPanel"))
        #expect(homeSource.contains("monthNavigationButton"))
        #expect(homeSource.contains("inlineCalendarDays"))
        #expect(homeSource.contains("selectDate("))
        #expect(!homeSource.contains("popover(isPresented:"))
        #expect(homeSource.contains("displayedComponents: .hourAndMinute"))
        #expect(homeSource.contains("ChineseCalendarInfoProvider.info"))
        #expect(!homeSource.contains("DatePicker(\n                    isAllDay ? PlannerCopy.text(.date"))
        #expect(homeSource.contains("isMultiDay"))
        #expect(homeSource.contains("PlannerCopy.text(.multiDayTask"))
        #expect(homeSource.contains("PlannerCopy.text(.deadlineDate"))
        #expect(homeSource.contains("normalizedEndDate"))
        #expect(languageSource.contains("case multiDayTask"))
        #expect(languageSource.contains("多天任务"))
        #expect(languageSource.contains("case deadlineDate"))
        #expect(languageSource.contains("截止日期"))
    }

    @Test("primary app surfaces use the unified FuFu warm background")
    func primaryAppSurfacesUseUnifiedFuFuWarmBackground() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let focusFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)

        #expect(rootSource.contains("MeowPlannerTheme.plannerGradient"))
        #expect(rootSource.contains(".scrollContentBackground(.hidden)"))
        #expect(rootSource.contains(".ignoresSafeArea()"))
        #expect(rootSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
        #expect(homeSource.contains("MeowPlannerTheme.plannerGradient"))
        #expect(homeSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
        #expect(focusSource.contains("MeowPlannerTheme.plannerGradient"))
        #expect(focusSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
        #expect(settingsSource.contains("MeowPlannerTheme.plannerGradient"))
        #expect(settingsSource.contains(".scrollContentBackground(.hidden)"))
        #expect(settingsSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
    }

    @Test("main window supports compact free resizing")
    func mainWindowSupportsCompactFreeResizing() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(appSource.contains("mainWindowDefaultContentSize"))
        #expect(appSource.contains("mainWindowCompactContentMinSize"))
        #expect(!appSource.contains("NSSize(width: 720, height: 540)"))
        #expect(!rootSource.contains(".frame(minWidth: 720, minHeight: 540)"))
        #expect(homeSource.contains("compactMonthGridMinHeight"))
        #expect(monthGridSource.contains("monthGridLayoutMetrics"))
        #expect(monthGridSource.contains("minimumVisiblePlannerItemRows"))
        #expect(monthGridSource.contains("GeometryReader"))
    }

    @Test("month calendar card bounds grid rows inside the compact background")
    func monthCalendarCardBoundsGridRowsInsideCompactBackground() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(monthGridSource.contains("MonthGridLayoutMetrics"))
        #expect(monthGridSource.contains("monthGridLayoutMetrics(for: proxy.size, dayCount: visiblePlannerDays.count)"))
        #expect(monthGridSource.contains("height: layoutMetrics.dayCellHeight"))
        #expect(monthGridSource.contains(".frame(height: layoutMetrics.gridHeight, alignment: .top)"))
        #expect(monthGridSource.contains(".frame(height: height, alignment: .top)"))
        #expect(!monthGridSource.contains(".frame(minHeight: minHeight, alignment: .top)"))
    }

    @Test("compact month calendar keeps one schedule title visible and hides daily overflow scrollers")
    func compactMonthCalendarKeepsOneScheduleTitleVisibleAndHidesDailyOverflowScrollers() throws {
        let root = try packageRoot()
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(calendarHomeSource.contains("compactMonthGridMinHeight: CGFloat = 520"))
        #expect(monthGridSource.contains("minimumVisiblePlannerItemRows: CGFloat = 1"))
        #expect(monthGridSource.contains("dayContentSpacing: CGFloat = 2"))
        #expect(monthGridSource.contains("plannerItemListHeight(for: minimumVisiblePlannerItemRows)"))
        #expect(monthGridSource.contains("let visiblePlannerDays = plannerDays(maxVisibleItems: Int.max)"))
        #expect(monthGridSource.contains("VStack(alignment: .leading, spacing: dayContentSpacing)"))
        #expect(monthGridSource.contains("plannerItemList(day, height: plannerItemListHeight, visibleDays: visibleDays)"))
        #expect(monthGridSource.contains("ScrollView(.vertical)"))
        #expect(monthGridSource.contains(".hiddenVerticalScrollIndicatorsOnMac()"))
        #expect(monthGridSource.contains(".frame(height: height, alignment: .top)"))
        #expect(themeSource.contains("func hiddenVerticalScrollIndicatorsOnMac()"))
        #expect(themeSource.contains("struct HiddenVerticalScrollIndicatorConfigurator"))
        #expect(themeSource.contains("scrollView.hasVerticalScroller = false"))
        #expect(themeSource.contains("scrollView.scrollerStyle = .overlay"))
        #expect(!monthGridSource.contains("maxVisibleItems(for:"))
        #expect(!monthGridSource.contains("showsOverflowCount"))
        #expect(!monthGridSource.contains("Text(\"+\\(day.overflowCount)\")"))
    }

    @Test("hidden Dock launch temporarily promotes activation policy before showing the main window")
    func hiddenDockLaunchTemporarilyPromotesActivationPolicyBeforeShowingMainWindow() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let dockControllerFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AppDockIconController.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let dockControllerSource = try String(contentsOf: dockControllerFile, encoding: .utf8)

        #expect(dockControllerSource.contains("static var currentShowDockIconPreference: Bool"))
        #expect(dockControllerSource.contains("prepareForMainWindowPresentation(showDockIcon:"))
        #expect(dockControllerSource.contains("restorePreferredActivationPolicyAfterMainWindowPresentation(showDockIcon:"))
        #expect(dockControllerSource.contains("application.setActivationPolicy(.regular)"))
        #expect(dockControllerSource.contains("application.setActivationPolicy(.accessory)"))
        #expect(appSource.contains("AppDockIconController.currentShowDockIconPreference"))
        #expect(appSource.contains("AppDockIconController.prepareForMainWindowPresentation(showDockIcon: showDockIcon)"))
        #expect(appSource.contains("AppDockIconController.restorePreferredActivationPolicyAfterMainWindowPresentation(showDockIcon: showDockIcon)"))
    }

    @Test("Dock icon visibility can be hidden and customized from settings")
    func dockIconVisibilityCanBeHiddenAndCustomizedFromSettings() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let dockControllerFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AppDockIconController.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")
        let iconInstallerFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/AppIconInstaller.swift")
        let menuBarFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let infoPlistFile = root
            .appendingPathComponent("Config/MeowPlanner-Info.plist")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let dockControllerSource = try String(contentsOf: dockControllerFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let iconInstallerSource = try String(contentsOf: iconInstallerFile, encoding: .utf8)
        let menuBarSource = try String(contentsOf: menuBarFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let infoPlistSource = try String(contentsOf: infoPlistFile, encoding: .utf8)

        #expect(dockControllerSource.contains("enum AppDockIconController"))
        #expect(dockControllerSource.contains("static let storageKey = \"meowplanner.showDockIcon\""))
        #expect(dockControllerSource.contains("static let defaultShowDockIcon = false"))
        #expect(dockControllerSource.contains("relaunchIfNeeded: Bool = false"))
        #expect(dockControllerSource.contains("application.setActivationPolicy(showDockIcon ? .regular : .accessory)"))
        #expect(dockControllerSource.contains("scheduleRelaunchForDockRegistrationIfNeeded"))
        #expect(dockControllerSource.contains("NSWorkspace.shared.openApplication"))
        #expect(appSource.contains("@AppStorage(AppDockIconController.storageKey) private var showDockIcon = AppDockIconController.defaultShowDockIcon"))
        #expect(appSource.contains("AppIconInstaller.apply(showDockIcon: showDockIcon)"))
        #expect(appSource.contains(".onChange(of: showDockIcon)"))
        #expect(settingsSource.contains("@AppStorage(AppDockIconController.storageKey) private var showDockIcon = AppDockIconController.defaultShowDockIcon"))
        #expect(settingsSource.contains("Section(PlannerCopy.text(.dockIcon"))
        #expect(settingsSource.contains("Toggle(PlannerCopy.text(.showDockIcon"))
        #expect(settingsSource.contains("AppDockIconController.apply(showDockIcon: newValue, relaunchIfNeeded: true)"))
        #expect(languageSource.contains("case dockIcon"))
        #expect(languageSource.contains("case showDockIcon"))
        #expect(!iconInstallerSource.contains("application.setActivationPolicy(.regular)"))
        #expect(appSource.contains("AppMainWindowPresenter.shared.open("))
        #expect(menuBarSource.contains("MainWindowLaunchCoordinator.openInitialMainWindowIfNeeded"))
        #expect(menuBarSource.contains("openAppKitMainWindow()"))
        #expect(rootViewSource.contains("static private var didRequestInitialMainWindow = false"))
        #expect(infoPlistSource.contains("<key>LSUIElement</key>"))
        #expect(infoPlistSource.contains("<true/>"))
    }

    @Test("main calendar background and floating add use only paw motifs")
    func mainCalendarBackgroundAndFloatingAddUseOnlyPawMotifs() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(homeSource.contains("mainBackgroundMotifs"))
        #expect(homeSource.contains("floatingAddScheduleButton"))
        #expect(homeSource.contains("pawprint.fill"))
        #expect(homeSource.contains("fufuPlannerBackground"))
        #expect(homeSource.contains("centerPawWatermark"))
        #expect(homeSource.contains("cornerPawWatermark"))
        #expect(homeSource.contains("pawMotif"))
        #expect(homeSource.contains("fufuPawTint.opacity(0.13)"))
        #expect(homeSource.contains("caramel.opacity(0.15)"))
        #expect(homeSource.contains("blush.opacity(0.12)"))
        #expect(homeSource.contains("warmCream.opacity(0.09)"))
        #expect(!homeSource.contains("pawTrail"))
        #expect(!homeSource.contains("PawStep"))
        #expect(!homeSource.contains("fufuPawTint.opacity(0.12)"))
        #expect(!homeSource.contains("Image(systemName: \"plus\")"))
        #expect(monthGridSource.contains("pawWatermark"))
        #expect(monthGridSource.contains("pawprint.fill"))
        #expect(themeSource.contains("fufuPlannerBackground"))
        #expect(themeSource.contains("fufuCalendarBackground"))
        #expect(!homeSource.contains("CatEarsMotif"))
        #expect(!monthGridSource.contains("CatEarsMotif"))
        #expect(!themeSource.contains("struct CatEarsMotif"))
        #expect(!monthGridSource.contains("FuFuAssetImage"))
    }

    @Test("month grid connects multi-day all-day events as one visual bar")
    func monthGridConnectsMultiDayAllDayEventsAsOneVisualBar() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(monthGridSource.contains("multiDayEventSegment"))
        #expect(monthGridSource.contains("multiDayEventSpan"))
        #expect(monthGridSource.contains("multiDayContinuationPlaceholder"))
        #expect(monthGridSource.contains("multiDaySpanTopSpacerCount"))
        #expect(monthGridSource.contains("multiDayTopSpacingPlaceholders"))
        #expect(monthGridSource.contains("multiDaySegmentPosition"))
        #expect(monthGridSource.contains("multiDaySpanWidth"))
        #expect(monthGridSource.contains("MultiDaySegmentPosition"))
        #expect(monthGridSource.contains("isMultiDayAllDayEvent"))
        #expect(monthGridSource.contains("GeometryReader"))
        #expect(monthGridSource.contains("UnevenRoundedRectangle"))
        #expect(monthGridSource.contains("event.endDate"))
        #expect(monthGridSource.contains("event.isAllDay"))
        #expect(monthGridSource.contains("multiDaySegmentHeight"))
        #expect(monthGridSource.contains("segmentPlaceholder"))
        #expect(monthGridSource.contains(".frame(height: multiDaySegmentHeight"))
        #expect(!monthGridSource.contains("minHeight: 18"))
        #expect(monthGridSource.contains("dayCellGridBackground"))
        #expect(monthGridSource.contains(".background(dayCellGridBackground"))
    }

    @Test("dark mode month grid avoids washed out white cell highlights")
    func darkModeMonthGridAvoidsWashedOutWhiteCellHighlights() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(monthGridSource.contains("monthGridSelectedDayBackground"))
        #expect(monthGridSource.contains("monthGridCurrentMonthCellBackground"))
        #expect(monthGridSource.contains("monthGridOutsideMonthCellBackground"))
        #expect(monthGridSource.contains("monthGridDivider"))
        #expect(monthGridSource.contains("monthGridHeaderBackground"))
        #expect(themeSource.contains("static let monthGridSelectedDayBackground = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridCurrentMonthCellBackground = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridOutsideMonthCellBackground = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridDivider = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridHeaderBackground = adaptiveColor"))
        #expect(!monthGridSource.contains("Color.white.opacity(0.30)"))
        #expect(!monthGridSource.contains("Color.primary.opacity(0.025)"))
    }

    @Test("month calendar opens on today and only click selection changes the highlighted day")
    func monthCalendarOpensOnTodayAndOnlyClickSelectionChangesTheHighlightedDay() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let monthGridBodySource = try #require(sourceBlock(
            in: monthGridSource,
            from: "struct MonthGridView: View {",
            to: "    private func monthGridLayoutMetrics"
        ))
        let moveMonthSource = try #require(sourceBlock(
            in: monthGridSource,
            from: "    private func moveMonth(by value: Int) {",
            to: "\n    }\n\n}"
        ))

        #expect(rootSource.contains("selectSidebarSection(section)"))
        #expect(rootSource.contains("private func selectSidebarSection(_ section: AppSection)"))
        #expect(rootSource.contains("case .calendar:\n            refreshCalendarAfterExternalOpen()"))
        #expect(rootSource.contains("CalendarHomeView()"))
        #expect(rootSource.contains(".id(calendarRenderToken)"))
        #expect(monthGridSource.contains("@State private var displayedMonth = Date()"))
        #expect(monthGridBodySource.contains("Button {\n                            resetToToday()"))
        #expect(monthGridBodySource.contains("Label(PlannerCopy.text(.today"))
        #expect(monthGridSource.contains("MonthPlannerGridBuilder.days(\n            for: displayedMonth"))
        #expect(monthGridSource.contains("calendar.isDate(day.date, inSameDayAs: selectedDate)"))
        #expect(monthGridSource.contains("private func selectDate(_ date: Date)"))
        #expect(monthGridSource.contains("selectedDate = date"))
        #expect(monthGridSource.contains("displayedMonth = monthStart(for: date)"))
        #expect(monthGridSource.contains("private func resetToToday()"))
        #expect(monthGridSource.contains("let today = Date()"))
        #expect(monthGridSource.contains("selectedDate = today"))
        #expect(monthGridSource.contains("displayedMonth = monthStart(for: today)"))
        #expect(moveMonthSource.contains("displayedMonth ="))
        #expect(!moveMonthSource.contains("selectedDate = calendar.date(byAdding: .month"))
    }

    @Test("event editor manages palette colors from a popup editor")
    func eventEditorSupportsCustomColorPickerAndHexInput() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)

        #expect(homeSource.contains("ColorPicker"))
        #expect(homeSource.contains("colorHexInput"))
        #expect(homeSource.contains("syncColorFromPicker"))
        #expect(homeSource.contains("syncColorFromHexInput"))
        #expect(homeSource.contains("ColorSwatchButton"))
        #expect(homeSource.contains("PaletteColorEditorView"))
        #expect(homeSource.contains("showingPaletteColorEditor"))
        #expect(homeSource.contains("openPaletteColorEditor"))
        #expect(homeSource.contains("addPaletteColor"))
        #expect(homeSource.contains("deletePaletteColor"))
        #expect(homeSource.contains("paletteColorControls"))
        #expect(homeSource.contains("contextMenu"))
        #expect(homeSource.contains("Button(role: .destructive)"))
        #expect(themeSource.contains("normalizedHex"))
        #expect(themeSource.contains("hex(color:"))
        #expect(!homeSource.contains(".pickerStyle(.segmented)"))
    }

    @Test("calendar event editor folds optional end time into the start time picker")
    func calendarEventEditorFoldsOptionalEndTimeIntoStartTimePicker() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let dateRowsSource = try #require(sourceBlock(
            in: homeSource,
            from: "    private var datePickerRows: some View {",
            to: "    private var paletteColorControls: some View {"
        ))
        let inlinePanelSource = try #require(sourceBlock(
            in: homeSource,
            from: "private struct FuFuInlineDatePickerPanel",
            to: "private enum RepeatRuleSelection"
        ))

        #expect(dateRowsSource.contains("endSelection: $endDate"))
        #expect(dateRowsSource.contains("hasEndTime: $hasEndDate"))
        #expect(dateRowsSource.contains("allowsEndTime: !isAllDay && !isMultiDay"))
        #expect(!dateRowsSource.contains("} else if !isAllDay && hasEndDate {"))
        #expect(!homeSource.contains("Toggle(PlannerCopy.text(.hasEndTime, language: appLanguage), isOn: $hasEndDate)"))
        #expect(inlinePanelSource.contains("private var timeControls: some View"))
        #expect(inlinePanelSource.contains("Toggle(PlannerCopy.text(.hasEndTime"))
        #expect(inlinePanelSource.contains("DatePicker(\"\", selection: endTimeSelectionBinding(endSelection)"))
        #expect(inlinePanelSource.contains("syncEndTimeAfterStartChange()"))
    }

    @Test("calendar time picker commits edits when clicking outside focused time fields")
    func calendarTimePickerCommitsEditsWhenClickingOutsideFocusedTimeFields() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let inlinePanelSource = try #require(sourceBlock(
            in: homeSource,
            from: "private struct FuFuInlineDatePickerPanel",
            to: "private enum RepeatRuleSelection"
        ))

        #expect(inlinePanelSource.contains("timeEditingCommitGesture"))
        #expect(inlinePanelSource.contains("commitTimeEditingAndNormalize()"))
        #expect(inlinePanelSource.contains("resignTimeFieldFocus()"))
        #expect(inlinePanelSource.contains("makeFirstResponder(nil)"))
        #expect(inlinePanelSource.contains(".simultaneousGesture(timeEditingCommitGesture)"))
        #expect(inlinePanelSource.contains("binding.wrappedValue = normalizedEndTime(for: newValue)"))
        #expect(inlinePanelSource.contains("calendar.date(byAdding: .hour, value: 1, to: selection)"))
    }

    private func packageRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.path != "/" {
            let candidate = url.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return url
            }
            url.deleteLastPathComponent()
        }

        throw CocoaError(.fileNoSuchFile)
    }

    private func sourceIfPresent(_ fileURL: URL) -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }

    private func sourceWindow(in source: String, from marker: String, length: Int = 700) throws -> String {
        let markerRange = try #require(source.range(of: marker))
        let endIndex = source.index(
            markerRange.lowerBound,
            offsetBy: length,
            limitedBy: source.endIndex
        ) ?? source.endIndex

        return String(source[markerRange.lowerBound..<endIndex])
    }

    private func sourceBlock(in source: String, from startMarker: String, to endMarker: String) -> String? {
        guard let startRange = source.range(of: startMarker),
              let endRange = source[startRange.upperBound...].range(of: endMarker) else {
            return nil
        }

        return String(source[startRange.lowerBound..<endRange.lowerBound])
    }
}
