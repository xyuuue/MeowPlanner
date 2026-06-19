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

    @Test("iOS app project embeds an iPhone WidgetKit extension")
    func iOSAppProjectEmbedsIPhoneWidgetExtension() throws {
        let root = try packageRoot()
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let widgetInfoFile = root.appendingPathComponent("Config/MeowPlannerWidget-iOS-Info.plist")
        let widgetEntitlementsFile = root.appendingPathComponent("Config/MeowPlannerWidget-iOS.entitlements")

        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)
        let entitlements = try String(contentsOf: widgetEntitlementsFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: widgetInfoFile.path))
        #expect(FileManager.default.fileExists(atPath: widgetEntitlementsFile.path))
        #expect(generatorSource.contains("ios_widget_target = oid(\"target:MeowPlannerWidgetExtension-iOS\")"))
        #expect(generatorSource.contains("ios_widget_product = oid(\"product:MeowPlannerWidgetExtension-iOS.appex\")"))
        #expect(generatorSource.contains("ios_app_widget_dependency"))
        #expect(generatorSource.contains("ios_widget_core_dependency"))
        #expect(generatorSource.contains("MeowPlannerWidgetExtension-iOS"))
        #expect(generatorSource.contains("\"CODE_SIGN_ENTITLEMENTS\": \"Config/MeowPlannerWidget-iOS.entitlements\""))
        #expect(generatorSource.contains("\"INFOPLIST_FILE\": \"Config/MeowPlannerWidget-iOS-Info.plist\""))
        #expect(generatorSource.contains("\"TARGETED_DEVICE_FAMILY\": \"1\""))
        #expect(generatorSource.contains("ios_app_embed_extensions = copy_phase(\"MeowPlanner-iOS\", \"Embed App Extensions\", \"13\""))
        #expect(generatorSource.contains("f\"\\t\\t\\t\\t{ios_widget_target} = {{CreatedOnToolsVersion = 26.5; ProvisioningStyle = Automatic; }};\""))
        #expect(generatorSource.contains("active_targets.extend([ios_app_target, ios_core_target, ios_widget_target])"))
        #expect(generatorSource.contains("MeowPlannerWidgetExtension-iOS.appex"))
        #expect(project.contains("MeowPlannerWidgetExtension-iOS"))
        #expect(project.contains("MeowPlannerWidgetExtension-iOS.appex"))
        #expect(project.contains("Config/MeowPlannerWidget-iOS-Info.plist"))
        #expect(project.contains("Config/MeowPlannerWidget-iOS.entitlements"))
        #expect(project.contains("TargetAttributes = {"))
        #expect(project.contains("ProvisioningStyle = Automatic"))
        #expect(project.contains("SDKROOT = iphoneos"))
        #expect(project.contains("TARGETED_DEVICE_FAMILY = 1"))
        #expect(entitlements.contains("group.com.yuelingqiu.MeowPlanner"))
        #expect(!entitlements.contains("com.apple.security.app-sandbox"))
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
        #expect(widgetSource.contains("private static var supportedFamilies: [WidgetFamily]"))
        #expect(widgetSource.contains("#if os(iOS)\n        return [.systemSmall, .systemMedium, .systemLarge]"))
        #expect(widgetSource.contains("#else\n        return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]"))
        #expect(widgetSource.contains(".supportedFamilies(Self.supportedFamilies)"))
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
        #expect(script.contains("pkill -f \"MeowPlannerWidgetExtension.appex/Contents/MacOS/MeowPlannerWidgetExtension\""))
        #expect(script.contains("STALE_WIDGET_BUNDLES=("))
        #expect(script.contains("$ROOT_DIR/build/XcodeRun/Build/Products/Debug/$APP_NAME.app/Contents/PlugIns/MeowPlannerWidgetExtension.appex"))
        #expect(script.contains("$ROOT_DIR/build/XcodeRun/Build/Products/Release/$APP_NAME.app/Contents/PlugIns/MeowPlannerWidgetExtension.appex"))
        #expect(script.contains("/private/tmp/MeowPlannerManualSign.app/Contents/PlugIns/MeowPlannerWidgetExtension.appex"))
        #expect(script.contains("for stale_widget_bundle in \"${STALE_WIDGET_BUNDLES[@]}\""))
        #expect(script.contains("/usr/bin/pluginkit -r \"$stale_widget_bundle\""))
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
        #expect(appSource.contains("import FirebaseAuth"))
        #expect(appSource.contains("FirebaseApp.configure()"))
        #expect(appSource.contains("FirebaseAuthKeychainConfigurator.apply()"))
        #expect(appSource.contains("Bundle.main.object(forInfoDictionaryKey: \"AppIdentifierPrefix\")"))
        #expect(appSource.contains("rawPrefix.hasSuffix(\".\")"))
        #expect(appSource.contains("Auth.auth().useUserAccessGroup(accessGroup)"))
        #expect(entitlements.contains("keychain-access-groups"))
        #expect(entitlements.contains("com.apple.security.network.client"))
        #expect(entitlements.contains("com.apple.security.temporary-exception.files.home-relative-path.read-write"))
        #expect(entitlements.contains("/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/"))
        #expect(!entitlements.contains("aps-environment"))
        #expect(!entitlements.contains("com.apple.developer.icloud-container-identifiers"))
        #expect(!entitlements.contains("com.apple.developer.icloud-services"))
    }

    @Test("macOS app exits duplicate launches before Firebase starts")
    func macOSAppExitsDuplicateLaunchesBeforeFirebaseStarts() throws {
        let root = try packageRoot()
        let appFile = root.appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let appStructStart = try #require(appSource.range(of: "struct MeowPlannerApp: App"))
        let appStructSource = String(appSource[appStructStart.lowerBound...])
        let initSource = try sourceWindow(in: appStructSource, from: "init() {", length: 900)
        let singleInstanceGuardRange = try #require(
            initSource.range(of: "MeowPlannerSingleInstanceGuard.exitIfAnotherInstanceIsRunning()")
        )
        let firebaseConfigureRange = try #require(initSource.range(of: "FirebaseApp.configure()"))

        #expect(appSource.contains("private enum MeowPlannerSingleInstanceGuard"))
        #expect(appSource.contains(".runningApplications(withBundleIdentifier:"))
        #expect(appSource.contains("activate(options:"))
        #expect(appSource.contains("exit(0)"))
        #expect(singleInstanceGuardRange.lowerBound < firebaseConfigureRange.lowerBound)
    }

    @Test("Firebase Firestore clients create databases lazily")
    func firebaseFirestoreClientsCreateDatabasesLazily() throws {
        let root = try packageRoot()
        let syncServiceFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/FirestoreAppDataSyncService.swift")
        let authClientFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/FirebaseAccountAuthenticationClient.swift")

        let syncServiceSource = try String(contentsOf: syncServiceFile, encoding: .utf8)
        let authClientSource = try String(contentsOf: authClientFile, encoding: .utf8)

        #expect(syncServiceSource.contains("private var database: Firestore {"))
        #expect(authClientSource.contains("private var database: Firestore {"))
        #expect(!syncServiceSource.contains("database: Firestore = Firestore.firestore()"))
        #expect(!syncServiceSource.contains("private let database: Firestore"))
        #expect(!authClientSource.contains("private let database = Firestore.firestore()"))
    }

    @Test("project declares a separate iOS app target and scheme")
    func projectDeclaresSeparateIOSAppTargetAndScheme() throws {
        let root = try packageRoot()
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let iosInfoPlistFile = root.appendingPathComponent("Config/MeowPlanner-iOS-Info.plist")
        let iosEntitlementsFile = root.appendingPathComponent("Config/MeowPlanner-iOS.entitlements")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let iosSchemeFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("xcschemes")
            .appendingPathComponent("MeowPlanner-iOS.xcscheme")

        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: iosInfoPlistFile.path))
        #expect(FileManager.default.fileExists(atPath: iosEntitlementsFile.path))
        #expect(FileManager.default.fileExists(atPath: iosSchemeFile.path))
        #expect(generatorSource.contains("ios_app_target"))
        #expect(generatorSource.contains("MeowPlanner-iOS"))
        #expect(generatorSource.contains("Config/MeowPlanner-iOS-Info.plist"))
        #expect(generatorSource.contains("Config/MeowPlanner-iOS.entitlements"))
        #expect(generatorSource.contains("MEOWPLANNER_IOS_DEVELOPMENT_TEAM"))
        #expect(project.contains("MeowPlanner-iOS"))
        #expect(project.contains("Config/MeowPlanner-iOS-Info.plist"))
        #expect(project.contains("Config/MeowPlanner-iOS.entitlements"))
        #expect(project.contains("IPHONEOS_DEPLOYMENT_TARGET = 17.0"))
        #expect(
            project.contains("SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\"")
                || project.contains("SUPPORTED_PLATFORMS = (\n\t\t\t\t\tiphoneos,\n\t\t\t\t\tiphonesimulator,")
        )
        #expect(project.contains("SDKROOT = iphoneos"))
        #expect(project.contains("PRODUCT_MODULE_NAME = MeowPlannerCore"))
        #expect(!project.contains("path = MeowPlannerCore-iOS.framework"))
        #expect(!project.contains("MeowPlanner-iOS.app/Contents/PlugIns"))

        let plistData = try Data(contentsOf: iosInfoPlistFile)
        let plist = try #require(PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any])
        #expect(plist["CFBundleDisplayName"] as? String == "MeowPlanner")
        #expect(plist["CFBundleURLTypes"] != nil)
        #expect(plist["LSUIElement"] == nil)
        #expect(plist["NSPrincipalClass"] == nil)
        #expect(plist["LSMinimumSystemVersion"] == nil)
        #expect(plist["UIApplicationSceneManifest"] == nil)
        #expect(plist["AppIdentifierPrefix"] as? String == "$(AppIdentifierPrefix)")
        let supportedOrientations = try #require(plist["UISupportedInterfaceOrientations"] as? [String])
        #expect(supportedOrientations.contains("UIInterfaceOrientationPortrait"))
        #expect(supportedOrientations.contains("UIInterfaceOrientationPortraitUpsideDown"))
        #expect(supportedOrientations.contains("UIInterfaceOrientationLandscapeLeft"))
        #expect(supportedOrientations.contains("UIInterfaceOrientationLandscapeRight"))

        let entitlements = try String(contentsOf: iosEntitlementsFile, encoding: .utf8)
        #expect(entitlements.contains("com.apple.security.application-groups"))
        #expect(entitlements.contains("group.com.yuelingqiu.MeowPlanner"))
        #expect(entitlements.contains("keychain-access-groups"))
        #expect(entitlements.contains("$(AppIdentifierPrefix)com.yuelingqiu.MeowPlanner"))
        #expect(!entitlements.contains("com.apple.security.app-sandbox"))
        #expect(!entitlements.contains("com.apple.security.network.client"))
    }

    @Test("project generator supports platform-scoped copies")
    func projectGeneratorSupportsPlatformScopedCopies() throws {
        let root = try packageRoot()
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")

        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)

        #expect(generatorSource.contains("MEOWPLANNER_TARGET_PLATFORM"))
        #expect(generatorSource.contains("default_target_platform"))
        #expect(generatorSource.contains("INCLUDE_MACOS"))
        #expect(generatorSource.contains("INCLUDE_IOS"))
        #expect(generatorSource.contains("active_config_files"))
    }

    @Test("iOS app uses one full screen reference background")
    func iOSAppUsesOneFullScreenReferenceBackground() throws {
        let root = try packageRoot()
        let lightBackground = root.appendingPathComponent("Resources/iOSBackground.png")
        let darkBackground = root.appendingPathComponent("Resources/iOSBackgroundDark.png")
        let shellFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let calendarFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let calendarSource = try String(contentsOf: calendarFile, encoding: .utf8)

        #expect(try pngDimensions(at: lightBackground) == CGSizePixels(width: 852, height: 1846))
        #expect(try pngDimensions(at: darkBackground) == CGSizePixels(width: 852, height: 1846))
        #expect(shellSource.contains("private var iosFullScreenBackground: some View"))
        #expect(shellSource.contains("PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(shellSource.contains(".background { iosFullScreenBackground }"))
        #expect(!shellSource.contains("PlannerPawStarBackground(gradientOpacity: 0.84)"))
        #expect(settingsSource.contains("#if os(iOS)\n        PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(calendarSource.contains("#if os(iOS)\n            Color.clear\n            #else"))
        #expect(!settingsSource.contains("PlannerPawStarBackground(gradientOpacity: 0.82)"))
    }

    @Test("iOS root uses custom app navigation shell instead of system tab bar")
    func iosRootUsesCustomAppNavigationShellInsteadOfSystemTabBar() throws {
        let root = try packageRoot()
        let rootViewFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let shellFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")
        let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")

        let rootSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)
        let iosRootSource = try sourceWindow(
            in: rootSource,
            from: "IOSNavigationShellView(",
            length: 1_500
        )
        let iosCalendarSource = try sourceWindow(
            in: rootSource,
            from: "CalendarHomeView(",
            length: 260
        )
        let sidebarCloseButtonSource = try sourceWindow(
            in: shellSource,
            from: "Button {\n                    closeSidebar()",
            length: 460
        )
        let bottomOverlaySource = try sourceWindow(
            in: shellSource,
            from: ".overlay(alignment: .bottom)",
            length: 420
        )
        let topNavigationBackgroundSource = try sourceWindow(
            in: shellSource,
            from: "private var topNavigationBackground",
            length: 280
        )
        let bottomNavigationBackgroundSource = try sourceWindow(
            in: shellSource,
            from: "private var bottomNavigationBackground",
            length: 220
        )
        let bottomNavigationButtonSource = try sourceWindow(
            in: shellSource,
            from: "private func bottomNavigationButton",
            length: 1_000
        )

        #expect(rootSource.contains("@AppStorage(AppSection.iosBottomNavigationStorageKey)"))
        #expect(rootSource.contains("@StateObject private var iosCalendarNavigationState = IOSCalendarNavigationState()"))
        #expect(iosRootSource.contains("IOSNavigationShellView("))
        #expect(iosRootSource.contains("bottomSections: iosBottomNavigationSections"))
        #expect(iosRootSource.contains("calendarNavigationState: iosCalendarNavigationState"))
        #expect(iosRootSource.contains("onSelect: selectSidebarSection"))
        #expect(iosCalendarSource.contains("CalendarHomeView("))
        #expect(iosCalendarSource.contains("iosNavigationState: iosCalendarNavigationState"))
        #expect(iosCalendarSource.contains("newScheduleRequestToken: calendarAddScheduleRequestToken"))
        #expect(!iosRootSource.contains("TabView(selection: $selection)"))
        #expect(shellSource.contains("#if os(iOS)"))
        #expect(shellSource.contains("safeAreaInset(edge: .top"))
        #expect(shellSource.contains("private var topNavigationBar: some View"))
        #expect(shellSource.contains("private var topNavigationBackground: some View"))
        #expect(shellSource.contains("private var shouldShowSidebarButton: Bool"))
        #expect(shellSource.contains("selection != .settings"))
        #expect(shellSource.contains("if shouldShowSidebarButton"))
        #expect(!shellSource.contains("private var navigationContentShield: some View"))
        #expect(shellSource.contains(".ignoresSafeArea(edges: .top)"))
        #expect(shellSource.contains("safeAreaInset(edge: .bottom"))
        #expect(shellSource.contains("bottomNavigationReservation(safeAreaInsets: proxy.safeAreaInsets)"))
        #expect(shellSource.contains(".overlay(alignment: .bottom)"))
        #expect(shellSource.contains("bottomNavigationBar(safeAreaInsets: proxy.safeAreaInsets)"))
        #expect(bottomOverlaySource.contains("bottomNavigationBar(safeAreaInsets: proxy.safeAreaInsets)"))
        #expect(bottomOverlaySource.contains(".offset(y: proxy.safeAreaInsets.bottom)"))
        #expect(bottomOverlaySource.contains(".ignoresSafeArea(edges: .bottom)"))
        #expect(shellSource.contains("private func bottomNavigationReservation(safeAreaInsets: EdgeInsets) -> some View"))
        #expect(shellSource.contains("static func bottomNavigationReservedHeight(safeAreaInsets: EdgeInsets)"))
        #expect(shellSource.contains("Color.clear\n            .frame(height: IOSAppNavigationMetrics.bottomNavigationReservedHeight(safeAreaInsets: safeAreaInsets))"))
        #expect(shellSource.contains("private func bottomNavigationBar(safeAreaInsets: EdgeInsets) -> some View"))
        #expect(shellSource.contains("bottomNavigationBackground\n                .ignoresSafeArea(edges: .bottom)"))
        #expect(topNavigationBackgroundSource.contains("Color.clear"))
        #expect(!topNavigationBackgroundSource.contains("navigationContentShield"))
        #expect(bottomNavigationBackgroundSource.contains("Color.clear"))
        #expect(!bottomNavigationBackgroundSource.contains("navigationContentShield"))
        #expect(!bottomNavigationBackgroundSource.contains("if"))
        #expect(!shellSource.contains("shouldUseTransparentBottomNavigationBackground"))
        #expect(shellSource.contains("IOSAppNavigationMetrics.bottomNavigationChromeHeight(safeAreaInsets: safeAreaInsets)"))
        #expect(shellSource.contains("static func bottomNavigationBottomPadding(for safeAreaInsets: EdgeInsets)"))
        #expect(shellSource.contains("bottomNavigationBottomPadding(for: safeAreaInsets)"))
        #expect(shellSource.contains("bottomNavigationMinimumBottomPadding: CGFloat = 0"))
        #expect(shellSource.contains("max(safeAreaInsets.bottom, bottomNavigationMinimumBottomPadding)"))
        #expect(shellSource.contains("static let bottomNavigationRaisedPadding: CGFloat = 40"))
        #expect(shellSource.contains("+ bottomNavigationRaisedPadding"))
        #expect(shellSource.contains(".padding(.bottom, IOSAppNavigationMetrics.bottomNavigationRaisedPadding)"))
        #expect(!shellSource.contains("bottomNavigationButtonBottomInset"))
        #expect(!shellSource.contains("bottomNavigationButtonVerticalOffset"))
        #expect(!shellSource.contains(".offset(y: buttonVerticalOffset)"))
        #expect(shellSource.contains(".frame(height: IOSAppNavigationMetrics.bottomNavigationChromeHeight(safeAreaInsets: safeAreaInsets), alignment: .bottom)"))
        #expect(!shellSource.contains("safeAreaInsets.bottom * 0.28"))
        #expect(bottomNavigationButtonSource.contains("in: Capsule()"))
        #expect(bottomNavigationButtonSource.contains(".contentShape(Capsule())"))
        #expect(!bottomNavigationButtonSource.contains("RoundedRectangle(cornerRadius: 8)"))
        #expect(shellSource.contains("calendarNavigationBarCenter"))
        #expect(shellSource.contains("calendarScheduleDisplayMenu"))
        #expect(shellSource.contains("calendarNavigationState.presentMonthPicker()"))
        #expect(shellSource.contains("calendarNavigationState.resetToToday()"))
        #expect(shellSource.contains("sidebarOverlay"))
        #expect(shellSource.contains("sidebarOverlay(panelWidth: sidebarWidth(for: proxy.size.width), safeAreaInsets: proxy.safeAreaInsets)"))
        #expect(shellSource.contains("sidebarPanel(width: panelWidth, safeAreaInsets: safeAreaInsets)"))
        #expect(shellSource.contains("private let sidebarHeaderTopPadding: CGFloat = 16"))
        #expect(!shellSource.contains("private let sidebarHeaderTopExtraPadding"))
        #expect(shellSource.contains("private let sidebarHeaderBottomPadding: CGFloat = 8"))
        #expect(shellSource.contains("private let sidebarListTopPadding: CGFloat = 4"))
        #expect(shellSource.contains("private let sidebarRowHeight: CGFloat = 44"))
        #expect(shellSource.contains("private let sidebarRowSpacing: CGFloat = 4"))
        #expect(shellSource.contains(".padding(.top, sidebarHeaderTopPadding)"))
        #expect(!shellSource.contains(".padding(.top, safeAreaInsets.top + sidebarHeaderTopExtraPadding)"))
        #expect(shellSource.contains(".padding(.bottom, sidebarHeaderBottomPadding)"))
        #expect(sidebarCloseButtonSource.contains("Image(systemName: \"sidebar.left\")"))
        #expect(sidebarCloseButtonSource.contains(".symbolRenderingMode(.hierarchical)"))
        #expect(!sidebarCloseButtonSource.contains("Image(systemName: \"xmark\")"))
        #expect(shellSource.contains("VStack(spacing: sidebarRowSpacing)"))
        #expect(shellSource.contains(".padding(.top, sidebarListTopPadding)"))
        #expect(shellSource.contains(".frame(height: sidebarRowHeight)"))
        #expect(shellSource.contains("sidebarDecorativeBackground(width: width, safeAreaInsets: safeAreaInsets)"))
        #expect(shellSource.contains("PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(shellSource.contains("sidebarPawWatermark("))
        #expect(shellSource.contains("sidebarStarWatermark("))
        #expect(!shellSource.contains("sidebarFufuWatermark("))
        #expect(!shellSource.contains("FuFuAssetImage(size: footerSize)"))
        #expect(!shellSource.contains("let footerSize"))
        #expect(!shellSource.contains(".ignoresSafeArea(edges: .vertical)"))
        #expect(shellSource.contains("ForEach(allSections)"))
        #expect(shellSource.contains("ForEach(bottomSections)"))
        #expect(navigationSource.contains("static let defaultIOSBottomNavigationSections: [AppSection] = ["))
        #expect(navigationSource.contains(".calendar,\n        .todo,\n        .schedule,\n        .settings"))
        #expect(generatorSource.contains("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift"))
        #expect(project.contains("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift"))
    }

    @Test("iOS calendar uses continuous month swiping and hides app chrome behind agenda cards")
    func iosCalendarUsesContinuousMonthSwipingAndHidesAppChromeBehindAgendaCards() throws {
        let root = try packageRoot()
        let shellFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")
        let calendarFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let calendarSource = try String(contentsOf: calendarFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let pagerSource = try sourceWindow(
            in: monthGridSource,
            from: "private func iosContinuousMonthPager",
            length: 3_600
        )

        #expect(shellSource.contains("@Published var isCalendarAgendaOverlayPresented = false"))
        #expect(shellSource.contains("private var shouldShowNavigationBars"))
        #expect(shellSource.contains("if shouldShowNavigationBars"))
        #expect(!shellSource.contains("bottomNavigationBackgroundMotifs"))
        #expect(!shellSource.contains("bottomNavigationPawMotif("))
        #expect(!shellSource.contains("FuFuAssetImage(size: 34)"))
        #expect(shellSource.contains("Color.clear"))
        #expect(!shellSource.contains("shouldUseTransparentBottomNavigationBackground"))
        #expect(!shellSource.contains("MeowPlannerTheme.fufuCalendarBackground.opacity(0.98)"))
        #expect(calendarSource.contains("iosNavigationState.setAgendaOverlayPresented(true)"))
        #expect(calendarSource.contains("iosNavigationState.setAgendaOverlayPresented(false)"))
        #expect(calendarSource.contains("private let iosCalendarBottomReserve: CGFloat = IOSAppNavigationMetrics.bottomNavigationRaisedPadding"))
        #expect(!calendarSource.contains("private let iosCalendarBottomReserve: CGFloat = -IOSAppNavigationMetrics.bottomNavigationRaisedPadding"))
        #expect(calendarSource.contains("private let iosAgendaCardHeight: CGFloat = 500"))
        #expect(calendarSource.contains("private let iosAgendaCardHorizontalInset: CGFloat = 28"))
        #expect(!monthGridSource.contains("private let iosAdjacentMonthPeek"))
        #expect(monthGridSource.contains("@State private var iosPagerAnchorMonth: Date?"))
        #expect(monthGridSource.contains("private func plannerDays(for month: Date, maxVisibleItems: Int)"))
        #expect(monthGridSource.contains("private func iosPagerMonths(centeredOn month: Date)"))
        #expect(pagerSource.contains("let pageWidth = max(1, proxy.size.width)"))
        #expect(pagerSource.contains("let pagerCenterMonth = iosPagerAnchorMonth ?? displayedMonth"))
        #expect(monthGridSource.contains("iosPagerAnchorMonth = initialMonth"))
        #expect(pagerSource.contains("ScrollView(.horizontal, showsIndicators: false)"))
        #expect(monthGridSource.contains("if #available(iOS 18.0, *)"))
        #expect(monthGridSource.contains(".scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))"))
        #expect(monthGridSource.contains(".scrollTargetBehavior(.viewAligned)"))
        #expect(pagerSource.contains(".scrollPosition(id: $iosScrollPosition)"))
        #expect(!pagerSource.contains(".contentMargins(.horizontal"))
    }

    @Test("iOS settings customize bottom navigation membership and order")
    func iosSettingsCustomizeBottomNavigationMembershipAndOrder() throws {
        let root = try packageRoot()
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let languageFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let sectionSource = try sourceWindow(
            in: settingsSource,
            from: "private var iosBottomNavigationSection",
            length: 5_400
        )

        #expect(settingsSource.contains("@AppStorage(AppSection.iosBottomNavigationStorageKey)"))
        #expect(settingsSource.contains("#if os(iOS)\n            iosBottomNavigationSection"))
        #expect(sectionSource.contains("Section(PlannerCopy.text(.bottomNavigation"))
        #expect(sectionSource.contains("Toggle(isOn: iosBottomNavigationSelectionBinding"))
        #expect(sectionSource.contains("iosBottomNavigationRowLabel(for: section)"))
        #expect(sectionSource.contains("iosBottomNavigationActionLabel("))
        #expect(!sectionSource.contains("Label(section.title(language: appLanguage), systemImage: section.systemImage)"))
        #expect(!sectionSource.contains("Label(PlannerCopy.text(.restoreDefault, language: appLanguage), systemImage: \"arrow.counterclockwise\")"))
        #expect(sectionSource.contains(".symbolRenderingMode(.monochrome)"))
        #expect(sectionSource.contains(".foregroundStyle(MeowPlannerTheme.caramel)"))
        #expect(sectionSource.contains(".buttonStyle(.plain)"))
        #expect(sectionSource.contains("systemImage: \"chevron.up\""))
        #expect(sectionSource.contains("systemImage: \"chevron.down\""))
        #expect(sectionSource.contains("resetIOSBottomNavigation()"))
        #expect(sectionSource.contains("iosBottomNavigationIsLastSelectedSection"))
        #expect(settingsSource.contains("selectedSections + remainingSections"))
        #expect(settingsSource.contains("sections.swapAt(currentIndex, newIndex)"))
        #expect(settingsSource.contains("AppSection.storageValue(for: normalizedSections)"))
        #expect(languageSource.contains("case bottomNavigation"))
        #expect(languageSource.contains(".bottomNavigation: \"Bottom navigation\""))
        #expect(languageSource.contains(".bottomNavigation: \"底部导航\""))
        #expect(languageSource.contains("case restoreDefault"))
        #expect(languageSource.contains(".restoreDefault: \"Restore default\""))
        #expect(languageSource.contains(".restoreDefault: \"恢复默认\""))
    }

    @Test("iOS settings can choose widget background image or transparent mode")
    func iosSettingsCanChooseWidgetBackgroundImageOrTransparentMode() throws {
        let root = try packageRoot()
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let languageFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")
        let widgetPreferenceFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")
        let widgetFile = root.appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let widgetPreferenceSource = try String(contentsOf: widgetPreferenceFile, encoding: .utf8)
        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let widgetSettingsSource = try sourceWindow(
            in: settingsSource,
            from: "private var widgetSettingsPage",
            length: 7_500
        )

        #expect(settingsSource.contains("import PhotosUI"))
        #expect(settingsSource.contains("case widget"))
        #expect(settingsSource.contains("NavigationLink(value: SettingsDestination.widget)"))
        #expect(settingsSource.contains("@State private var selectedWidgetBackgroundPhotoItem: PhotosPickerItem?"))
        #expect(settingsSource.contains("@State private var widgetBackgroundStyle = WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS)"))
        #expect(settingsSource.contains("@State private var widgetAppearanceID = WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS).rawValue"))
        #expect(widgetSettingsSource.contains("widgetAppearanceSection"))
        #expect(widgetSettingsSource.contains("Section(widgetAppearanceSectionTitle)"))
        #expect(settingsSource.contains("appLanguage == .chinese ? \"小组件外观\" : \"Widget appearance\""))
        #expect(!settingsSource.contains("appLanguage == .chinese ? \"外观\" : \"Appearance\"\n    }\n\n    private var widgetAppearanceSystemModeTitle"))
        #expect(widgetSettingsSource.contains("Picker(widgetAppearanceSystemModeTitle"))
        #expect(widgetSettingsSource.contains("Picker(widgetAppearanceManualModeTitle"))
        #expect(widgetSettingsSource.contains("WidgetPlannerPreferenceStore.setWidgetAppearancePreference(AppAppearancePreference(storedValue: newValue), platform: .iOS)"))
        #expect(settingsSource.contains("persistWidgetAppearancePreference(newValue)"))
        #expect(widgetSettingsSource.contains("WidgetBackgroundStyle.allCases"))
        #expect(widgetSettingsSource.contains("PhotosPicker("))
        #expect(widgetSettingsSource.contains("WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(newValue, platform: .iOS)"))
        #expect(widgetSettingsSource.contains("WidgetPlannerPreferenceStore.saveCustomBackgroundImageData(data, platform: .iOS)"))
        #expect(widgetSettingsSource.contains("WidgetCenter.shared.reloadAllTimelines()"))
        #expect(languageSource.contains("case widgetSettings"))
        #expect(languageSource.contains("case widgetBackground"))
        #expect(languageSource.contains("case chooseBackgroundImage"))
        #expect(widgetPreferenceSource.contains("public enum WidgetBackgroundStyle"))
        #expect(widgetPreferenceSource.contains("case transparent"))
        #expect(widgetPreferenceSource.contains("public enum WidgetPreferencePlatform"))
        #expect(widgetPreferenceSource.contains("case .macOS: .defaultArtwork"))
        #expect(widgetPreferenceSource.contains("case .iOS: .defaultArtwork"))
        #expect(widgetPreferenceSource.contains("widgetBackgroundStyleKey"))
        #expect(widgetPreferenceSource.contains("widgetBackgroundStyleKey(for: platform)"))
        #expect(widgetPreferenceSource.contains("widgetAppearancePreferenceKey"))
        #expect(widgetPreferenceSource.contains("widgetAppearancePreferenceKey(for: platform)"))
        #expect(widgetPreferenceSource.contains("public static var widgetAppearancePreference: AppAppearancePreference"))
        #expect(widgetPreferenceSource.contains("isDarkWidgetAppearance(systemIsDark:"))
        #expect(widgetPreferenceSource.contains("customBackgroundImageURL"))
        #expect(widgetPreferenceSource.contains("saveCustomBackgroundImageData"))
        #expect(widgetSource.contains("WidgetPlannerPreferenceStore.widgetBackgroundStyle"))
        #expect(widgetSource.contains("case .transparent:"))
        #expect(widgetSource.contains("@Environment(\\.showsWidgetContainerBackground)"))
        #expect(widgetSource.contains(".meowPlannerWidgetContainerBackground()"))
        #expect(widgetSource.contains("containerBackground(for: .widget)"))
        #expect(!widgetSource.contains("if WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent {\n            self"))
        #expect(widgetSource.contains(".containerBackgroundRemovable(WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent)"))
        #expect(widgetSource.contains("!showsWidgetContainerBackground || WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent"))
        #expect(widgetSource.contains("usesTransparentWidgetBackground ? Color.clear : WidgetPalette.weeklyGlassFill(isDark: isDarkBackground)"))
        #expect(widgetSource.contains("usesTransparentWidgetBackground ? WidgetPalette.weeklyTransparentSeparator(isDark: isDarkBackground) : WidgetPalette.weeklySeparator(isDark: isDarkBackground)"))
        #expect(!widgetSource.contains("usesTransparentWidgetBackground ? Color.clear : WidgetPalette.weeklySeparator(isDark: isDarkBackground)"))
        #expect(widgetSource.contains("if !hasSchedules && !usesTransparentWidgetBackground"))
        #expect(widgetSource.contains("usesTransparentBackground: usesTransparentWidgetBackground"))
        #expect(widgetSource.contains("var usesTransparentBackground: Bool"))
        #expect(widgetSource.contains("if day.events.isEmpty && !usesTransparentBackground"))
        #expect(widgetSource.contains("customBackgroundImage()"))
        #expect(widgetSource.contains("UIImage(data: data)"))
        #expect(!widgetSource.contains("if let image = WidgetBackgroundImageLoader.image(isDark: colorScheme == .dark)"))
    }

    @Test("iOS settings hide inner system chrome and remove Dock personalization controls")
    func iosSettingsHideInnerSystemChromeAndRemoveDockPersonalizationControls() throws {
        let root = try packageRoot()
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")

        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let settingsFormSource = try sourceWindow(
            in: settingsSource,
            from: "private func settingsForm",
            length: 1_600
        )
        let personalizationSettingsPageSource = try #require(sourceBlock(
            in: settingsSource,
            from: "private var personalizationSettingsPage",
            to: "    #if os(iOS)\n    private var widgetSettingsPage"
        ))
        let personalizationSubtitleSource = try sourceWindow(
            in: settingsSource,
            from: "private var personalizationDestinationSubtitle",
            length: 500
        )

        #expect(settingsSource.contains("private var settingsNavigationStack: some View"))
        #expect(settingsSource.contains(".toolbar(.hidden, for: .navigationBar)"))
        #expect(settingsSource.contains(".toolbarBackground(.hidden, for: .navigationBar)"))
        #expect(settingsSource.contains(".navigationBarTitleDisplayMode(.inline)"))
        #expect(settingsSource.contains(".navigationBarBackButtonHidden(true)"))
        #expect(settingsSource.contains("func settingsPlatformNavigationTitle(_ title: String) -> some View"))
        #expect(settingsSource.contains("#if os(iOS)\n        self\n        #else\n        navigationTitle(title)"))
        #expect(settingsSource.contains(".settingsPlatformNavigationTitle(PlannerCopy.text(.settings"))
        #expect(settingsSource.contains(".settingsPlatformNavigationTitle(PlannerCopy.text(.account"))
        #expect(settingsSource.contains(".settingsPlatformNavigationTitle(PlannerCopy.text(.personalizationSettings"))
        #expect(!settingsSource.contains(".navigationTitle(PlannerCopy.text(.settings"))
        #expect(!settingsSource.contains(".navigationTitle(PlannerCopy.text(.account"))
        #expect(!settingsSource.contains(".navigationTitle(PlannerCopy.text(.personalizationSettings"))
        #expect(settingsFormSource.contains(".listRowSeparator(.hidden)"))
        #expect(settingsFormSource.contains("settingsBottomScrollExpansion"))
        #expect(settingsFormSource.contains("topContentInset settingsTopContentInset: CGFloat = settingsDestinationContentTopInset"))
        #expect(settingsFormSource.contains(".settingsContentTopSpacing(settingsTopContentInset)"))
        #expect(settingsSource.contains("func settingsContentTopSpacing(_ topInset: CGFloat) -> some View"))
        #expect(settingsSource.contains("private let settingsHomeContentTopInset: CGFloat = 24"))
        #expect(settingsSource.contains("private let settingsDestinationContentTopInset: CGFloat = 28"))
        #expect(settingsSource.contains("contentMargins(.top, topInset, for: .scrollContent)"))
        #expect(!settingsSource.contains("private let settingsContentTopInset"))
        #expect(!settingsSource.contains(".padding(.top, settingsTopContentInset)"))
        #expect(!settingsSource.contains(".padding(.top, settingsContentTopInset)"))
        #expect(settingsSource.contains("settingsForm(topContentInset: settingsHomeContentTopInset)"))
        #expect(settingsSource.contains("private func settingsContentBottomNavigationMaskHeight(safeAreaInsets: EdgeInsets) -> CGFloat"))
        #expect(settingsSource.contains("IOSAppNavigationMetrics.bottomNavigationContentHeight"))
        #expect(settingsSource.contains("+ IOSAppNavigationMetrics.bottomNavigationTopPadding"))
        #expect(settingsSource.contains("+ IOSAppNavigationMetrics.bottomNavigationBottomPadding(for: safeAreaInsets)"))
        #expect(!settingsSource.contains("IOSAppNavigationMetrics.bottomNavigationChromeHeight(safeAreaInsets: safeAreaInsets)"))
        #expect(settingsFormSource.contains("hidesContentBehindBottomNavigation settingsHidesContentBehindBottomNavigation: Bool = false"))
        #expect(settingsFormSource.contains(".settingsBottomNavigationContentMask(isEnabled: settingsHidesContentBehindBottomNavigation)"))
        #expect(settingsSource.contains("let bottomMaskHeight = settingsContentBottomNavigationMaskHeight("))
        #expect(settingsSource.contains("settingsPersonalizationBottomScrollExpansion"))
        #expect(settingsSource.contains("PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(settingsSource.contains(".ignoresSafeArea()"))
        #expect(personalizationSettingsPageSource.contains("settingsForm(\n            bottomScrollExpansion: settingsPersonalizationBottomScrollExpansion,\n            hidesContentBehindBottomNavigation: true"))
        #expect(personalizationSettingsPageSource.contains("iosBottomNavigationSection"))
        #expect(!personalizationSettingsPageSource.contains("settingsBackButton"))
        #expect(settingsFormSource.contains(".tint(MeowPlannerTheme.pawButtonBrown)"))
        #expect(settingsFormSource.contains(".listRowBackground(settingsRowBackground)"))
        #expect(settingsSource.contains("private var settingsRowBackground: some View"))
        #expect(personalizationSettingsPageSource.contains("#if os(macOS)\n            dockIconSection\n            #endif"))
        #expect(personalizationSubtitleSource.contains("#if os(macOS)"))
        #expect(personalizationSubtitleSource.contains("#else"))
        #expect(personalizationSubtitleSource.contains("语言、外观、专注和显示偏好"))
        #expect(personalizationSubtitleSource.contains("Language, appearance, focus, and display preferences"))
    }

    @Test("widget snapshot file discovery avoids iOS unavailable home directory API")
    func widgetSnapshotFileDiscoveryAvoidsIOSUnavailableHomeDirectoryAPI() throws {
        let root = try packageRoot()
        let preferenceFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")

        let source = try String(contentsOf: preferenceFile, encoding: .utf8)
        let snapshotFileURLsStart = try #require(source.range(of: "private static var snapshotFileURLs"))
        let snapshotFileURLsEnd = try #require(
            source[snapshotFileURLsStart.lowerBound...].range(of: "private static var currentHomeDirectory")
        )
        let snapshotFileURLsSource = String(source[snapshotFileURLsStart.lowerBound..<snapshotFileURLsEnd.lowerBound])

        #expect(snapshotFileURLsSource.contains("homeDirectory: currentHomeDirectory"))
        #expect(!snapshotFileURLsSource.contains("homeDirectoryForCurrentUser"))
        #expect(source.contains("private static var currentHomeDirectory: URL"))
        #expect(source.contains("#if os(macOS)\n        return FileManager.default.homeDirectoryForCurrentUser"))
        #expect(source.contains("FileManager.default.urls(\n            for: .applicationSupportDirectory"))
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
        #expect(syncService.contains("appearancePlatform.cloudIDField: appearanceID"))
        #expect(syncService.contains("appearancePlatform.cloudUpdatedAtField: appearanceUpdatedAt"))
        #expect(syncService.contains("AppAppearancePreference.legacyCloudIDField"))
        #expect(syncService.contains("AppAppearancePreference.legacyCloudUpdatedAtField"))
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
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
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
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let accountStoreSource = try String(contentsOf: accountStoreFile, encoding: .utf8)
        let authClientSource = try String(contentsOf: authClientFile, encoding: .utf8)
        let script = try String(contentsOf: scriptFile, encoding: .utf8)
        let entitlements = try String(contentsOf: entitlementsFile, encoding: .utf8)
        let iosAuthenticationDismissSource = try #require(sourceBlock(
            in: accountModalSource,
            from: "#if os(iOS)\n            .onChange(of: accountStore.authenticationSuccessRevision)",
            to: "\n            #else"
        ))

        #expect(!accountSectionSource.contains("SignInWithAppleButton"))
        #expect(!accountSectionSource.contains("AuthenticationServices"))
        #expect(!accountSectionSource.contains("ASAuthorization"))
        #expect(!accountSectionSource.contains("showingAuthenticationModal"))
        #expect(!accountSectionSource.contains(".sheet(isPresented:"))
        #expect(!accountSectionSource.contains("AccountAuthenticationModalView"))
        #expect(accountSectionSource.contains("var onSignIn: () -> Void"))
        #expect(accountSectionSource.contains("onSignIn()"))
        #expect(settingsSource.contains("case signIn"))
        #expect(settingsSource.contains("activeSettingsSheet = .signIn"))
        #expect(settingsSource.contains("initialMode: .signIn"))
        #expect(accountSectionSource.contains("PlannerCopy.text(.loginButton"))
        #expect(accountSectionSource.contains("var onLinkAccount: () -> Void"))
        #expect(accountSectionSource.contains("shouldShowLinkAccountAction(for: profile)"))
        #expect(accountSectionSource.contains("Button(action: onLinkAccount)"))
        #expect(accountSectionSource.contains("PlannerCopy.text(.linkAccount"))
        #expect(accountSectionSource.contains("profile.accountIdentifier == nil"))
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
        #expect(accountStoreSource.contains("authenticationSuccessRevision"))
        #expect(accountStoreSource.contains("authenticationSuccessRevision += 1"))
        #expect(iosAuthenticationDismissSource.contains(".onChange(of: accountStore.authenticationSuccessRevision)"))
        #expect(iosAuthenticationDismissSource.contains(".onChange(of: accountStore.currentProfile?.remoteUserID)"))
        #expect(!iosAuthenticationDismissSource.contains(".onChange(of: accountStore.currentProfile?.id)"))
        #expect(accountModalSource.contains("emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty"))
        #expect(!accountModalSource.contains("emailAddressForAccountRegistration"))
        #expect(!accountModalSource.contains("PlannerCopy.text(.optionalEmail"))
        #expect(accountModalSource.contains("Button(role: .destructive)"))
        #expect(accountModalSource.contains("accountStore.sendEmailVerification"))
        #expect(accountModalSource.contains("accountStore.sendPasswordReset"))
        #expect(accountModalSource.contains("PlannerCopy.text(.sendResetLink"))
        #expect(accountModalSource.contains("PlannerCopy.text(.passwordResetLinkSent"))
        #expect(!accountModalSource.contains("sendPhoneVerification"))
        #expect(!accountModalSource.contains("startPhoneAuthBridge"))
        #expect(!accountModalSource.contains("linkPhone"))
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
        #expect(!accountStoreSource.contains("sendPhoneVerification"))
        #expect(!accountStoreSource.contains("PhoneAuthBridge"))
        #expect(!accountStoreSource.contains("handlePhoneAuthCallback"))
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
        #expect(authClientSource.contains("case .keychainError:"))
        #expect(authClientSource.contains("Firebase Auth could not access the iOS Keychain."))
        #expect(accountSectionSource.contains("isFirebaseKeychainError(message)"))
        #expect(accountSectionSource.contains("iOS Keychain is unavailable. Check the app signing and Keychain configuration."))
        #expect(!authClientSource.contains("sendPhoneVerification"))
        #expect(!authClientSource.contains("PhoneAuthBridgeService"))
        #expect(!authClientSource.contains("signIn(withCustomToken:"))
        #expect(!authClientSource.contains("consumePhoneAuthSession(state:"))
        #expect(authClientSource.contains("Auth.auth().currentUser?.reload"))
        let firebaseClientStart = try #require(authClientSource.range(of: "struct FirebaseAccountAuthenticationClient"))
        let changePasswordStart = try #require(authClientSource.range(
            of: "func changePassword(",
            range: firebaseClientStart.upperBound..<authClientSource.endIndex
        ))
        let wechatStart = try #require(authClientSource.range(
            of: "func signInWeChat",
            range: changePasswordStart.upperBound..<authClientSource.endIndex
        ))
        let changePasswordSource = String(authClientSource[changePasswordStart.lowerBound..<wechatStart.lowerBound])
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
        let accountSectionFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/AccountSettingsSection.swift")
        let settingsFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let rootViewFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let menuBarFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift")
        let languageFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let gatedRootSource = sourceIfPresent(gatedRootFile)
        let accountContainerSource = sourceIfPresent(accountContainerFile)
        let accountSectionSource = try String(contentsOf: accountSectionFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let menuBarSource = try String(contentsOf: menuBarFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let sheetModifierCount = settingsSource.components(separatedBy: ".sheet(").count - 1
        let settingsFormSource = try sourceWindow(
            in: settingsSource,
            from: "private func settingsForm",
            length: 1_500
        )
        let deleteAccountButtonSource = try sourceWindow(
            in: settingsSource,
            from: "showingDeleteAccountConfirmation = true",
            length: 900
        )
        let accountSettingsPageSource = try #require(sourceBlock(
            in: settingsSource,
            from: "private var accountSettingsPage",
            to: "    private var personalizationSettingsPage"
        ))
        let accountActionsSectionSource = try sourceWindow(
            in: settingsSource,
            from: "private var accountActionsSection",
            length: 900
        )
        let signOutButtonSource = try sourceWindow(
            in: settingsSource,
            from: "Button {\n                accountStore.signOut()",
            length: 650
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
        #expect(rootViewSource.contains("disablesContent: isSignedOutWorkspace && section != .settings && section != .calendar"))
        #expect(rootViewSource.contains("var meowPlannerSignedOutReadOnly"))
        #expect(rootViewSource.contains(".environment(\\.meowPlannerSignedOutReadOnly, isEnabled)"))
        #expect(!rootViewSource.contains(".disabled(isEnabled)"))
        #expect(rootViewSource.contains("scheduleSync(for: accountStore.currentProfile?.remoteUserID"))
        #expect(menuBarSource.contains("accountStore.currentProfile"))
        #expect(!menuBarSource.contains("SignedOutMenuBarView"))
        #expect(menuBarSource.contains("signedOutModelContainer"))
        #expect(settingsSource.contains("accountActionsSection"))
        #expect(settingsSource.contains("Button(role: .destructive)"))
        #expect(settingsSource.contains("PlannerCopy.text(.signOut"))
        #expect(settingsSource.contains("PlannerCopy.text(.changePassword"))
        #expect(accountSectionSource.contains("PlannerCopy.text(.linkAccount"))
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
        #expect(accountSettingsPageSource.contains("AccountSettingsSection("))
        #expect(accountSettingsPageSource.contains("accountStore: accountStore"))
        #expect(accountSettingsPageSource.contains("onLinkAccount: {"))
        #expect(accountSettingsPageSource.contains("activeSettingsSheet = .linkAccount"))
        #expect(!accountActionsSectionSource.contains("activeSettingsSheet = .linkAccount"))
        #expect(!accountActionsSectionSource.contains("PlannerCopy.text(.linkAccount"))
        #expect(settingsSource.contains("case .changePassword"))
        #expect(settingsSource.contains("initialMode: .changePassword"))
        #expect(!settingsSource.contains("case .linkPhone"))
        #expect(settingsSource.contains("case .linkEmail"))
        #expect(!settingsSource.contains("initialMode: .linkPhone"))
        #expect(settingsSource.contains("initialMode: .linkEmail"))
        #expect(!settingsSource.contains("showingDeleteAccountModal"))
        #expect(!settingsSource.contains("showingChangePasswordModal"))
        #expect(!settingsSource.contains("showingLinkAccountModal"))
        #expect(deleteAccountButtonSource.contains("SettingsDangerActionLabel("))
        #expect(deleteAccountButtonSource.contains(".buttonStyle(.plain)"))
        #expect(settingsSource.contains("private struct SettingsDangerActionLabel"))
        #expect(settingsSource.contains(".foregroundStyle(.red)"))
        #expect(!settingsSource.contains(".background(.red.opacity(0.10)"))
        #expect(!settingsSource.contains(".stroke(.red.opacity(0.28)"))
        #expect(signOutButtonSource.contains("Button {"))
        #expect(!signOutButtonSource.contains("Button(role: .destructive)"))
        #expect(signOutButtonSource.contains("SettingsAccountActionLabel("))
        #expect(signOutButtonSource.contains(".buttonStyle(.plain)"))
        #expect(settingsSource.contains("private struct SettingsAccountActionLabel"))
        #expect(signOutButtonSource.contains("systemImage: \"rectangle.portrait.and.arrow.right\""))
        #expect(signOutButtonSource.contains("foregroundStyle: MeowPlannerTheme.caramel"))
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

    @Test("macOS app does not expose phone authentication")
    func macOSAppDoesNotExposePhoneAuthentication() throws {
        let root = try packageRoot()
        let vercelConfigFile = root.appendingPathComponent("vercel.json")
        let appFile = root.appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let accountStoreFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AccountSessionStore.swift")
        let bridgeServiceFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/PhoneAuthBridgeService.swift")
        let authClientFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/FirebaseAccountAuthenticationClient.swift")
        let hostingFile = root.appendingPathComponent("website/phone-auth/index.html")
        let apiStartFile = root.appendingPathComponent("api/startPhoneAuthSession.js")
        let apiFinishFile = root.appendingPathComponent("api/finishPhoneAuthSession.js")
        let apiConsumeFile = root.appendingPathComponent("api/consumePhoneAuthSession.js")
        let apiCoreFile = root.appendingPathComponent("api/_phoneAuthBridgeCore.js")
        let apiRulesFile = root.appendingPathComponent("api/_phoneAuthBridgeRules.js")
        let apiAdminFile = root.appendingPathComponent("api/_firebaseAdmin.js")

        let vercelConfig = try String(contentsOf: vercelConfigFile, encoding: .utf8)
        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let accountStoreSource = try String(contentsOf: accountStoreFile, encoding: .utf8)
        let authClientSource = try String(contentsOf: authClientFile, encoding: .utf8)
        let removedFiles = [
            bridgeServiceFile,
            hostingFile,
            apiStartFile,
            apiFinishFile,
            apiConsumeFile,
            apiCoreFile,
            apiRulesFile,
            apiAdminFile,
            root.appendingPathComponent("api/test/phoneAuthBridgeRules.test.js")
        ]

        for removedFile in removedFiles {
            #expect(!FileManager.default.fileExists(atPath: removedFile.path))
        }

        #expect(!vercelConfig.contains("\"/phone-auth\""))
        #expect(!appSource.contains("handlePhoneAuthCallback"))
        #expect(!accountStoreSource.contains("PhoneAuth"))
        #expect(!accountStoreSource.contains("phone-auth"))
        #expect(!authClientSource.contains("PhoneAuth"))
        #expect(!authClientSource.contains("signIn(withCustomToken:"))
        #expect(!authClientSource.contains("PhoneAuthProvider.provider()"))
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

        #expect(plist["CFBundleShortVersionString"] as? String == "2.0.2")
        #expect(plist["CFBundleVersion"] as? String == "22")
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

    @Test("today widget shows an empty state when no shared snapshot is available")
    func todayWidgetShowsEmptyStateWhenNoSharedSnapshotIsAvailable() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let makeEntrySource = try #require(sourceBlock(
            in: widgetSource,
            from: "private func makeEntry",
            to: "    private static func nextRefreshDate"
        ))
        let summarySource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct SummaryWidgetView",
            to: "private struct MonthWidgetView"
        ))
        let monthSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct MonthWidgetView",
            to: "private enum WidgetFuFuImageLoader"
        ))

        #expect(widgetSource.contains("public let showsEmptyState: Bool"))
        #expect(widgetSource.contains("showsEmptyState: snapshot == nil && !includeSamplePlans"))
        #expect(makeEntrySource.contains("scheduleCount: events.count"))
        #expect(makeEntrySource.contains("todoCount: todos.count"))
        #expect(makeEntrySource.contains("habitCount: includeSamplePlans ? 1 : (snapshot?.habitCount ?? 0)"))
        #expect(summarySource.contains("if entry.showsEmptyState"))
        #expect(summarySource.contains("emptyStateSummary"))
        #expect(summarySource.contains("Text(\"No plans yet\")"))
        #expect(monthSource.contains("if entry.showsEmptyState"))
        #expect(monthSource.contains("emptyStateOverlay"))
        #expect(monthSource.contains("fufuWidgetMascot(size: family == .systemExtraLarge ? 28 : 24)"))
        #expect(monthSource.contains("Text(\"No plans yet\")"))
    }

    @Test("medium iPhone widget shows configurable weekly schedule")
    func mediumIPhoneWidgetShowsConfigurableWeeklySchedule() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let coreIntentFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WidgetAppIntents.swift")
        let widgetConstantsFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WidgetConstants.swift")
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let coreIntentSource = try String(contentsOf: coreIntentFile, encoding: .utf8)
        let widgetConstantsSource = try String(contentsOf: widgetConstantsFile, encoding: .utf8)
        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let widgetBodySource = try #require(sourceBlock(
            in: widgetSource,
            from: "public var body: some WidgetConfiguration",
            to: "\n    }\n}"
        ))
        let widgetViewSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct MeowPlannerTodayWidgetView",
            to: "private struct SummaryWidgetView"
        ))
        let makeEntrySource = try #require(sourceBlock(
            in: widgetSource,
            from: "private func makeEntry",
            to: "    private static func nextRefreshDate"
        ))
        let weeklyScheduleWidgetSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct WeeklyScheduleWidgetView",
            to: "private struct WeeklyScheduleCalendarDayColumn"
        ))
        let weeklyScheduleColumnSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct WeeklyScheduleCalendarDayColumn",
            to: "private struct SummaryWidgetView"
        ))
        let refreshButtonSource = try sourceWindow(
            in: weeklyScheduleWidgetSource,
            from: "Button(intent: RefreshWidgetTimelineIntent())",
            length: 700
        )
        let eventPillSource = try sourceWindow(
            in: weeklyScheduleColumnSource,
            from: "private func eventPill",
            length: 850
        )

        #expect(coreIntentSource.contains("public enum WidgetScheduleDisplayRule: String, AppEnum"))
        #expect(coreIntentSource.contains("case nextSevenDays"))
        #expect(coreIntentSource.contains("case calendarWeek"))
        #expect(coreIntentSource.contains("DisplayRepresentation(title: \"未来七天\")"))
        #expect(coreIntentSource.contains("DisplayRepresentation(title: \"自然周\")"))
        #expect(coreIntentSource.contains("public struct MeowPlannerWidgetConfigurationIntent: WidgetConfigurationIntent"))
        #expect(coreIntentSource.contains("@Parameter(title: \"显示规则\", default: WidgetScheduleDisplayRule.nextSevenDays)"))
        #expect(coreIntentSource.contains("public struct ChangeWidgetWeekIntent: AppIntent"))
        #expect(coreIntentSource.contains("WidgetWeekSelectionStore.adjustWeekOffset(by: weekDelta)"))
        #expect(coreIntentSource.contains("public enum WidgetWeekSelectionStore"))
        #expect(widgetConstantsSource.contains("public static let newScheduleURL = URL(string: \"meowplanner://schedule/new\")!"))
        #expect(widgetConstantsSource.contains("public static let widgetWeekOffsetKey = \"widgetWeekOffset\""))
        #expect(widgetSource.contains("public let scheduleDisplayRule: WidgetScheduleDisplayRule"))
        #expect(widgetSource.contains("public let weeklyScheduleDays: [WidgetWeeklyScheduleDay]"))
        #expect(widgetSource.contains("AppIntentTimelineProvider"))
        #expect(widgetBodySource.contains("AppIntentConfiguration(kind: kind, intent: MeowPlannerWidgetConfigurationIntent.self, provider: MeowPlannerTodayProvider())"))
        #expect(makeEntrySource.contains("displayRule: configuration.scheduleDisplayRule"))
        #expect(makeEntrySource.contains("weekOffset: includeSamplePlans ? 0 : WidgetWeekSelectionStore.currentWeekOffset"))
        #expect(makeEntrySource.contains("WidgetWeeklySchedulePlanner.days("))
        #expect(widgetViewSource.contains("case .systemMedium:"))
        #expect(widgetViewSource.contains("#if os(iOS)\n                WeeklyScheduleWidgetView(entry: entry)"))
        #expect(widgetSource.contains("private struct WeeklyScheduleWidgetView"))
        #expect(widgetSource.contains("weekNavigationButton(delta: -1, systemImage: \"chevron.left\")"))
        #expect(widgetSource.contains("weekNavigationButton(delta: 1, systemImage: \"chevron.right\")"))
        #expect(widgetSource.contains("Link(destination: WidgetConstants.newScheduleURL)"))
        #expect(widgetSource.contains("Button(intent: RefreshWidgetTimelineIntent())"))
        #expect(weeklyScheduleWidgetSource.contains(".frame(height: 28)"))
        #expect(weeklyScheduleWidgetSource.contains("Image(systemName: \"arrow.clockwise\")"))
        #expect(!weeklyScheduleWidgetSource.contains("Image(systemName: \"gearshape\")"))
        #expect(refreshButtonSource.contains(".font(.system(size: 14, weight: .medium))"))
        #expect(refreshButtonSource.contains(".contentShape(Circle())"))
        #expect(!refreshButtonSource.contains(".background("))
        #expect(!refreshButtonSource.contains(".overlay {"))
        #expect(weeklyScheduleWidgetSource.contains(".accessibilityLabel(\"刷新小组件\")"))
        #expect(widgetSource.contains("private struct WeeklyScheduleCalendarDayColumn"))
        #expect(widgetSource.contains("Text(\"今\")"))
        #expect(!weeklyScheduleColumnSource.contains("todayColumnFill"))
        #expect(!weeklyScheduleColumnSource.contains(".background(isToday ?"))
        #expect(weeklyScheduleColumnSource.contains("GeometryReader { proxy in"))
        #expect(weeklyScheduleColumnSource.contains("visibleEventRows(for: proxy.size.height)"))
        #expect(weeklyScheduleColumnSource.contains("private let eventTextSize: CGFloat = 8"))
        #expect(weeklyScheduleColumnSource.contains("private func visibleEventRows(for columnHeight: CGFloat) -> Int"))
        #expect(weeklyScheduleColumnSource.contains("let overflowCount = day.events.count - visibleEvents.count"))
        #expect(!weeklyScheduleColumnSource.contains("day.events.prefix(2)"))
        #expect(eventPillSource.contains(".font(.system(size: eventTextSize, weight: .medium))"))
        #expect(!eventPillSource.contains(".minimumScaleFactor"))
        #expect(weeklyScheduleColumnSource.contains(".font(.system(size: eventTextSize, weight: .bold))"))
        #expect(widgetSource.contains("private var weekdayStrip"))
        #expect(widgetSource.contains("private var calendarColumns"))
        #expect(widgetSource.contains("ForEach(entry.weeklyScheduleDays)"))
        #expect(widgetSource.contains("Text(\"No schedules this week\")"))
        #expect(widgetSource.contains("entry.completedSchedulesUseStrikethrough"))
        #expect(appSource.contains(".onOpenURL { url in"))
        #expect(appSource.contains("NotificationCenter.default.post(name: .meowPlannerExternalOpenURL, object: url)"))
        #expect(rootViewSource.contains("handleExternalURL"))
        #expect(rootViewSource.contains("WidgetConstants.newScheduleURL.host"))
        #expect(rootViewSource.contains("calendarAddScheduleRequestToken = UUID()"))
        #expect(calendarHomeSource.contains("newScheduleRequestToken: UUID?"))
        #expect(calendarHomeSource.contains("openRequestedNewScheduleIfNeeded()"))
    }

    @Test("medium iPhone widget uses light and dark image backgrounds")
    func mediumIPhoneWidgetUsesLightAndDarkImageBackgrounds() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let packageFile = root.appendingPathComponent("Package.swift")
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let lightBackgroundFile = root.appendingPathComponent("Resources/WidgetBackgroundLight.png")
        let darkBackgroundFile = root.appendingPathComponent("Resources/WidgetBackgroundDark.png")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let packageSource = try String(contentsOf: packageFile, encoding: .utf8)
        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let projectSource = try String(contentsOf: projectFile, encoding: .utf8)
        let weeklyScheduleWidgetSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct WeeklyScheduleWidgetView",
            to: "private struct WeeklyScheduleCalendarDayColumn"
        ))
        let macOSWidgetResourcesPhase = try #require(sourceBlock(
            in: projectSource,
            from: "1939428BF237C1AFB440C3B2 = {",
            to: "\n\t};"
        ))

        #expect(FileManager.default.fileExists(atPath: lightBackgroundFile.path))
        #expect(FileManager.default.fileExists(atPath: darkBackgroundFile.path))
        #expect(packageSource.contains(".copy(\"../../Resources/WidgetBackgroundLight.png\")"))
        #expect(packageSource.contains(".copy(\"../../Resources/WidgetBackgroundDark.png\")"))
        #expect(generatorSource.contains("WIDGET_BACKGROUND_RESOURCE_FILES"))
        #expect(generatorSource.contains("\"Resources/WidgetBackgroundLight.png\""))
        #expect(generatorSource.contains("\"Resources/WidgetBackgroundDark.png\""))
        #expect(generatorSource.contains("WIDGET_RESOURCE_FOLDERS"))
        #expect(generatorSource.contains("resources_phase(\"MeowPlannerWidgetExtension\", [build_file(\"MeowPlannerWidgetExtension\", path, folder=path in WIDGET_RESOURCE_FOLDERS) for path in WIDGET_BACKGROUND_RESOURCE_FILES + WIDGET_RESOURCE_FOLDERS])"))
        #expect(generatorSource.contains("resources_phase(\"MeowPlannerWidgetExtension-iOS\", [build_file(\"MeowPlannerWidgetExtension-iOS\", path) for path in WIDGET_BACKGROUND_RESOURCE_FILES])"))
        #expect(projectSource.contains("Resources/WidgetBackgroundLight.png"))
        #expect(projectSource.contains("Resources/WidgetBackgroundDark.png"))
        #expect(projectSource.contains("Resources/FuFu"))
        #expect(macOSWidgetResourcesPhase.contains("22C1DF4C09ECAF7DDA3D2736"))
        #expect(macOSWidgetResourcesPhase.contains("1ABF2C0AD136C89DBA5FBA41"))
        #expect(macOSWidgetResourcesPhase.contains("6C98680694770A7E7E373EBF"))
        #expect(weeklyScheduleWidgetSource.contains("WidgetScheduleBackgroundView()"))
        #expect(weeklyScheduleWidgetSource.contains("weeklyScheduleCardFill"))
        #expect(widgetSource.contains("WidgetBackgroundImageLoader.image(\n                    style: WidgetPlannerPreferenceStore.widgetBackgroundStyle"))
        #expect(widgetSource.contains("WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)"))
        #expect(widgetSource.contains("isDark: isDarkBackground"))
        #expect(widgetSource.contains("case .transparent:"))
        #expect(widgetSource.contains("forResource: isDark ? \"WidgetBackgroundDark\" : \"WidgetBackgroundLight\""))
        #expect(!widgetSource.contains("isDark: colorScheme == .dark"))
        #expect(!widgetSource.contains("WidgetPalette.weeklyFallbackBackground(isDark: colorScheme == .dark)"))
    }

    @Test("macOS default widget background uses system material glass")
    func macOSDefaultWidgetBackgroundUsesSystemMaterialGlass() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let containerSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct WidgetContainerBackgroundView",
            to: "private struct WeeklyScheduleWidgetView"
        ))

        #expect(containerSource.contains("case .defaultArtwork:\n                defaultBackground"))
        #expect(containerSource.contains("private var defaultBackground: some View"))
        #expect(containerSource.contains("#if os(macOS)\n        macOSSystemWidgetBackground"))
        #expect(containerSource.contains("private var macOSSystemWidgetBackground: some View"))
        #expect(containerSource.contains("Rectangle()\n                .fill(.regularMaterial)"))
        #expect(containerSource.contains("Color(red: 0.47, green: 0.55, blue: 0.57).opacity(colorScheme == .dark ? 0.46 : 0.34)"))
        #expect(containerSource.contains("Color.white.opacity(colorScheme == .dark ? 0.10 : 0.28)"))
        #expect(containerSource.contains("Color(red: 0.31, green: 0.38, blue: 0.40).opacity(colorScheme == .dark ? 0.24 : 0.10)"))
        #expect(containerSource.contains("private var defaultGradient: some View"))
        #expect(!containerSource.contains("case .defaultArtwork:\n                defaultGradient"))
        #expect(!containerSource.contains("#if os(iOS)\n        macOSSystemWidgetBackground"))
    }

    @Test("desktop widget uses snapshots and scheduled timeline entries")
    func desktopWidgetUsesSnapshotsAndScheduledTimelineEntries() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")
        let rootSyncFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/WidgetTimelineSyncService.swift")
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let coreFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WeekStartPreference.swift")
        let coreIntentFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/WidgetAppIntents.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let rootSyncSource = try String(contentsOf: rootSyncFile, encoding: .utf8)
        let appSource = try String(contentsOf: appFile, encoding: .utf8)
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
        #expect(coreSource.contains("FileManager.default.removeItem(at: fileURL)"))
        #expect(coreSource.contains("data.write(to: fileURL, options: .atomic)"))
        #expect(widgetSource.contains("WidgetPlannerSnapshotStore.loadFromFiles()"))
        #expect(!widgetSource.contains("makeSnapshotFromPersistentStore()"))
        #expect(!widgetSource.contains("WidgetPlannerPreferenceStore.showChineseCalendar"))
        #expect(widgetSource.contains("let entry = makeEntry(date: Date(), snapshot: snapshot, configuration: configuration)"))
        #expect(widgetSource.contains("Timeline(entries: [entry], policy: .after(Self.nextRefreshDate(after: entry.date)))"))
        #expect(widgetSource.contains("private static func nextRefreshDate"))
        #expect(widgetSource.contains("min(shortRefreshDate, nextMidnightRefreshDate)"))
        #expect(coreIntentSource.contains("WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()"))
        #expect(!widgetSource.contains("WidgetPlannerSnapshotStore.save(liveSnapshot)"))
        #expect(!widgetSource.contains("let events = includeSamplePlans ? sampleEvents(anchor: visibleMonthDate) : []"))
        #expect(rootSyncSource.contains("WidgetPlannerSnapshotStore.save"))
        #expect(!rootSyncSource.contains("WidgetPlannerSnapshotBuilder.makeSnapshotFromPersistentStore()"))
        #expect(!rootSyncSource.contains("refreshSnapshotFromPersistentStore()"))
        #expect(!coreSource.contains("makeSnapshotFromPersistentStore()"))
        #expect(rootSyncSource.contains("WidgetCenter.shared.reloadTimelines"))
        #expect(appSource.contains("AppLaunchWidgetSnapshotRefresher.schedule"))
        #expect(appSource.contains("AccountScopedModelContainerStore.shared"))
        #expect(appSource.contains("WidgetTimelineSyncService.publishSnapshotAndReload(using: context)"))
    }

    @Test("desktop widget event pills keep planner colors in non full color rendering")
    func desktopWidgetEventPillsKeepPlannerColorsInNonFullColorRendering() throws {
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
        #expect(widgetSource.contains("widgetAccentedRenderingMode(.fullColor)"))
        #expect(!widgetSource.contains(".widgetAccentable(!usesFullColorRendering)"))
        #expect(!widgetSource.contains("AnyShapeStyle(Color.primary)"))
        #expect(!widgetSource.contains("Color.primary.opacity(0.14)"))
        #expect(widgetSource.contains("widgetColor(\n                hex: item.colorHex"))
    }

    @Test("macOS month widget keeps readable glass text and paw watermark")
    func macOSMonthWidgetKeepsReadableGlassTextAndPawWatermark() throws {
        let root = try packageRoot()
        let widgetFile = root
            .appendingPathComponent("Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift")

        let widgetSource = try String(contentsOf: widgetFile, encoding: .utf8)
        let monthSource = try #require(sourceBlock(
            in: widgetSource,
            from: "private struct MonthWidgetView",
            to: "private enum WidgetFuFuImageLoader"
        ))

        #expect(monthSource.contains("if showsWidgetContainerBackground && WidgetPlannerPreferenceStore.widgetBackgroundStyle == .defaultArtwork"))
        #expect(monthSource.contains("private var usesMacOSGlassBackground: Bool"))
        #expect(monthSource.contains("#if os(macOS)\n        showsWidgetContainerBackground && WidgetPlannerPreferenceStore.widgetBackgroundStyle == .defaultArtwork"))
        #expect(monthSource.contains("private var monthPrimaryTextColor: Color"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.94) : WidgetPalette.cocoa"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.76) : WidgetPalette.caramel"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.52) : Color.secondary"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.90) : WidgetPalette.blush"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.24) : WidgetPalette.caramel.opacity(0.12)"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.38) : WidgetPalette.caramel.opacity(0.18)"))
        #expect(monthSource.contains(".foregroundStyle(monthPrimaryTextColor)"))
        #expect(monthSource.contains(".foregroundStyle(day.isInSelectedMonth ? monthPrimaryTextColor : monthMutedTextColor)"))
        #expect(monthSource.contains("day.chineseCalendarInfo.isFestival ? monthFestivalTextColor : monthSecondaryTextColor"))
        #expect(monthSource.contains("RoundedRectangle(cornerRadius: 7)\n                .stroke(monthGridBorderColor, lineWidth: 1)"))
        #expect(monthSource.contains("private func eventPillTitleColor"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? AnyShapeStyle(Color.white.opacity(0.94)) : AnyShapeStyle(WidgetPalette.cocoa)"))
        #expect(monthSource.contains("widgetColor(\n                hex: item.colorHex"))
        #expect(monthSource.contains("private var fufuPawPrimaryWatermarkColor: Color"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.09) : WidgetPalette.caramel.opacity(0.10)"))
        #expect(monthSource.contains("usesMacOSGlassBackground ? Color.white.opacity(0.07) : WidgetPalette.blue.opacity(0.10)"))
        #expect(!monthSource.contains(".foregroundStyle(day.isInSelectedMonth ? WidgetPalette.cocoa : .secondary)"))
        #expect(!monthSource.contains("day.chineseCalendarInfo.isFestival ? WidgetPalette.blush : WidgetPalette.caramel"))
        #expect(!monthSource.contains("Rectangle()\n                .fill(WidgetPalette.caramel.opacity(0.12))"))
        #expect(!monthSource.contains("AnyShapeStyle(Color.black.opacity(0.24))"))
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
        #expect(rootSource.contains("CalendarHomeView("))
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

    @Test("iOS focus timer uses compact content above bottom navigation")
    func iOSFocusTimerUsesCompactContentAboveBottomNavigation() throws {
        let root = try packageRoot()
        let focusFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")

        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)
        let recentSessionsSource = try sourceWindow(
            in: focusSource,
            from: "private var recentSessions",
            length: 1_200
        )
        let focusMaskHeightSource = try sourceWindow(
            in: focusSource,
            from: "private let focusBottomNavigationVisibleExtension",
            length: 500
        )

        #expect(focusSource.contains("private var focusPageBottomPadding: CGFloat"))
        #expect(focusSource.contains("IOSAppNavigationMetrics.bottomNavigationRaisedPadding"))
        #expect(focusSource.contains("IOSAppNavigationMetrics.bottomNavigationContentHeight"))
        #expect(focusSource.contains("+ IOSAppNavigationMetrics.bottomNavigationTopPadding"))
        #expect(focusSource.contains(".padding(.bottom, focusPageBottomPadding)"))
        #expect(focusSource.contains("private var focusPageTopPadding: CGFloat"))
        #expect(focusSource.contains("return 24"))
        #expect(focusSource.contains("private var focusHeaderAvatarSize: CGFloat"))
        #expect(focusSource.contains("return 58"))
        #expect(focusSource.contains("private var focusHeaderTitleFont: Font"))
        #expect(focusSource.contains("return .title3.bold()"))
        #expect(focusSource.contains("FuFuAssetImage(size: focusHeaderAvatarSize)"))
        #expect(focusSource.contains(".font(focusHeaderTitleFont)"))
        #expect(focusSource.contains(".font(focusHeaderSubtitleFont)"))
        #expect(focusSource.contains("private var focusTimerCircleSize: CGFloat"))
        #expect(focusSource.contains("return 212"))
        #expect(focusSource.contains(".frame(width: focusTimerCircleSize, height: focusTimerCircleSize)"))
        #expect(focusSource.contains("private var focusTimerDisplayFontSize: CGFloat"))
        #expect(focusSource.contains("return 46"))
        #expect(focusSource.contains(".font(.system(size: focusTimerDisplayFontSize"))
        #expect(focusSource.contains("private var focusControlButtonSize: CGFloat"))
        #expect(focusSource.contains("return 64"))
        #expect(focusSource.contains(".frame(width: focusControlButtonSize, height: focusControlButtonSize)"))
        #expect(focusSource.contains("private func focusBottomNavigationContentMaskHeight(safeAreaInsets: EdgeInsets) -> CGFloat"))
        #expect(focusMaskHeightSource.contains("private let focusBottomNavigationVisibleExtension: CGFloat = 44"))
        #expect(focusMaskHeightSource.contains("- focusBottomNavigationVisibleExtension"))
        #expect(focusMaskHeightSource.contains("max(0,"))
        #expect(focusMaskHeightSource.contains("IOSAppNavigationMetrics.bottomNavigationContentHeight"))
        #expect(focusMaskHeightSource.contains("+ IOSAppNavigationMetrics.bottomNavigationTopPadding"))
        #expect(!focusMaskHeightSource.contains("+ IOSAppNavigationMetrics.bottomNavigationBottomPadding(for: safeAreaInsets)"))
        #expect(focusSource.contains(".focusBottomNavigationContentMask()"))
        #expect(!focusSource.contains("LinearGradient(\n                        colors: [Color.black, Color.clear]"))
        #expect(focusSource.contains("let bottomMaskHeight = focusBottomNavigationContentMaskHeight("))
        #expect(focusSource.contains(".frame(height: bottomMaskHeight)"))
        #expect(focusSource.contains("private var focusRecentSessionsEmptyState: some View"))
        #expect(recentSessionsSource.contains("focusRecentSessionsEmptyState"))
        #expect(!recentSessionsSource.contains("FuFuEmptyStateView("))
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
        #expect(focusSource.contains(".frame(width: focusDurationEditingMinuteWidth, alignment: .trailing)"))
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
        #expect(appSource.contains("AppAppearancePreference.migrateLegacyValueIfNeeded()"))
        #expect(appSource.contains("@AppStorage(AppAppearancePreference.storageKey)"))
        #expect(appSource.contains(".preferredColorScheme(appAppearance.preferredColorScheme)"))
        #expect(appSource.contains("AppAppearancePreferenceApplicator.apply(appAppearance)"))
        #expect(!appSource.contains("syncWidgetAppearancePreference("))
        #expect(!appSource.contains("WidgetPlannerPreferenceStore.widgetAppearancePreference = preference"))
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
        #expect(!settingsSource.contains("syncWidgetAppearancePreference(AppAppearancePreference(storedValue: newValue))"))
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
        let shellFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")

        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let iosShellCallSource = try sourceWindow(
            in: rootViewSource,
            from: "IOSNavigationShellView(",
            length: 900
        )
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
        let accountSettingsPageSource = try #require(sourceBlock(
            in: settingsSource,
            from: "private var accountSettingsPage",
            to: "    private var personalizationSettingsPage"
        ))
        let personalizationSettingsPageSource = try sourceWindow(
            in: settingsSource,
            from: "private var personalizationSettingsPage",
            length: 900
        )

        #expect(rootViewSource.contains("@State private var settingsNavigationPath: [SettingsDestination] = []"))
        #expect(settingsSectionSource.contains("SettingsView(navigationPath: $settingsNavigationPath)"))
        #expect(selectSectionSource.contains("settingsNavigationPath.removeAll()"))
        #expect(selectSectionSource.contains("case .calendar:\n            #if os(iOS)\n            selection = section"))
        #expect(selectSectionSource.contains("#else\n            refreshCalendarAfterExternalOpen()"))
        #expect(settingsSource.contains("enum SettingsDestination: Hashable"))
        #expect(settingsSource.contains("@Binding private var navigationPath: [SettingsDestination]"))
        #expect(settingsSource.contains("init(navigationPath: Binding<[SettingsDestination]> = .constant([]))"))
        #expect(settingsSource.contains("NavigationStack(path: $navigationPath)"))
        #expect(iosShellCallSource.contains("settingsCanNavigateBack: !settingsNavigationPath.isEmpty"))
        #expect(iosShellCallSource.contains("onSettingsBack: navigateBackFromSettingsDestination"))
        #expect(rootViewSource.contains("private func navigateBackFromSettingsDestination()"))
        #expect(rootViewSource.contains("guard !settingsNavigationPath.isEmpty else"))
        #expect(rootViewSource.contains("settingsNavigationPath.removeLast()"))
        #expect(shellSource.contains("var settingsCanNavigateBack: Bool"))
        #expect(shellSource.contains("var onSettingsBack: () -> Void"))
        #expect(shellSource.contains("private var shouldShowSettingsBackButton: Bool"))
        #expect(shellSource.contains("selection == .settings && settingsCanNavigateBack"))
        #expect(shellSource.contains("if shouldShowSettingsBackButton"))
        #expect(shellSource.contains("Image(systemName: \"chevron.left\")"))
        #expect(shellSource.contains("onSettingsBack()"))
        #expect(shellSource.contains(".accessibilityLabel(settingsBackTitle)"))
        #expect(!accountSettingsPageSource.contains("settingsBackButton"))
        #expect(!personalizationSettingsPageSource.contains("settingsBackButton"))
        #expect(!settingsSource.contains("private var settingsBackButton: some View"))
        #expect(!settingsSource.contains("settingsBackButtonTitle"))
        #expect(!settingsSource.contains("@Environment(\\.dismiss) private var dismissSettingsDestination"))
        #expect(!settingsSource.contains("dismissSettingsDestination()"))
        #expect(!settingsSource.contains("Image(systemName: \"chevron.left\")"))
        #expect(!settingsSource.contains(".accessibilityLabel(settingsBackButtonTitle)"))
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
        let desktopCalendarScrollSource = try sourceWindow(
            in: calendarHomeSource,
            from: "private func desktopCalendarScroll",
            length: 1_600
        )
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
        #expect(rootViewSource.contains("window.toolbar?.isVisible = false"))
        #expect(rootViewSource.contains("sidebarCollapseButton"))
        #expect(!rootViewSource.contains("collapsedSidebarControlBar"))
        #expect(!rootViewSource.contains("private var collapsedSidebarExpandButton: some View"))
        #expect(rootViewSource.contains("private var sidebarExpandTitle: String"))
        #expect(rootViewSource.contains("expandSidebar()"))
        #expect(!detailSource.contains("VStack(spacing: 0)"))
        #expect(!detailSource.contains("if sidebarVisibility == .detailOnly"))
        #expect(!detailSource.contains("collapsedSidebarControlBar"))
        #expect(detailSource.contains("sectionView"))
        #expect(!rootViewSource.contains(".padding(.top, 16)"))
        #expect(!rootViewSource.contains(".padding(.trailing, 34)"))
        #expect(detailSource.contains("sectionView"))
        #expect(!detailSource.contains("sidebarRevealRail"))
        #expect(rootViewSource.contains(".overlay(alignment: .topTrailing) { nonCalendarSidebarExpandButtonOverlay }"))
        #expect(rootViewSource.contains("private var nonCalendarSidebarExpandButtonOverlay"))
        #expect(rootViewSource.contains("sidebarVisibility == .detailOnly && selection != .calendar"))
        #expect(rootViewSource.contains("MeowPlannerSidebarExpandButton(action: expandSidebar, title: sidebarExpandTitle)"))
        #expect(rootViewSource.contains("CalendarHomeView("))
        #expect(rootViewSource.contains("sidebarExpandAction: sidebarVisibility == .detailOnly"))
        #expect(rootViewSource.contains("sidebarExpandTitle: sidebarExpandTitle"))
        #expect(calendarHomeSource.contains("scheduleDisplayFilterButton"))
        #expect(calendarHomeSource.contains("sidebarExpandAction"))
        #expect(calendarHomeSource.contains("headerTrailingControls"))
        #expect(calendarHomeSource.contains("sidebarExpandTitle"))
        #expect(calendarHomeSource.contains("private let desktopCalendarHeaderContentSpacing: CGFloat = 0"))
        #expect(calendarHomeSource.contains("VStack(alignment: .leading, spacing: desktopCalendarHeaderContentSpacing)"))
        #expect(calendarHomeSource.contains("private let macOSTitlebarContentInset: CGFloat = 18"))
        #expect(!calendarHomeSource.contains("private let macOSTitlebarContentInset: CGFloat = 72"))
        #expect(desktopCalendarScrollSource.contains("ScrollView(.vertical) {\n            VStack(alignment: .leading, spacing: desktopCalendarHeaderContentSpacing) {\n                header"))
        #expect(desktopCalendarScrollSource.contains("header\n                    .padding(.top, macOSTitlebarContentInset)"))
        #expect(desktopCalendarScrollSource.contains("MonthGridView("))
        #expect(desktopCalendarScrollSource.contains("DayAgendaView("))
        #expect(calendarHomeSource.contains("ScrollView(.vertical)"))
        #expect(calendarHomeSource.contains(".clipped()"))
        #expect(!calendarHomeSource.contains(".overlay(alignment: .top) { titlebarContentMask }"))
        #expect(!calendarHomeSource.contains("private var titlebarContentMask"))
        #expect(calendarHomeSource.contains("MeowPlannerSidebarExpandButton(action: sidebarExpandAction, title: sidebarExpandTitle)"))
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
        #expect(appSource.contains("window.styleMask.formUnion([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])"))
        #expect(appSource.contains("window.backgroundColor = NSColor(MeowPlannerTheme.fufuPlannerBackground)"))
        #expect(appSource.contains("window.titlebarSeparatorStyle = .none"))
        #expect(rootViewSource.contains(".toolbarBackground(.hidden, for: .windowToolbar)"))
        #expect(rootViewSource.contains("MainWindowChromeConfigurator.apply(to: window)"))
        #expect(rootViewSource.contains("window.toolbar?.isVisible = false"))
        #expect(!rootViewSource.contains("window.toolbar = nil"))
        #expect(!rootViewSource.contains(".navigationTitle(\"MeowPlanner\")"))
        #expect(!calendarHomeSource.contains(".navigationTitle(\"MeowPlanner\")"))
    }

    @Test("main window preserves resize affordance while using FuFu chrome")
    func mainWindowPreservesResizeAffordanceWhileUsingFuFuChrome() throws {
        let root = try packageRoot()
        let appFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/App/MeowPlannerApp.swift")
        let rootViewFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")

        let appSource = try String(contentsOf: appFile, encoding: .utf8)
        let rootViewSource = try String(contentsOf: rootViewFile, encoding: .utf8)

        #expect(appSource.contains("window.styleMask.formUnion([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])"))
        #expect(rootViewSource.contains("MainWindowResizeAffordanceInstaller()"))
        #expect(rootViewSource.contains("contentView.addSubview(resizeView, positioned: .above, relativeTo: nil)"))
        #expect(rootViewSource.contains("resizeView.frame = contentView.bounds"))
        #expect(rootViewSource.contains("resizeView.autoresizingMask = [.width, .height]"))
        #expect(rootViewSource.contains("private let edgeThickness: CGFloat = 16"))
        #expect(rootViewSource.contains("override func hitTest(_ point: NSPoint) -> NSView?"))
        #expect(rootViewSource.contains("NSCursor.resizeLeftRight"))
        #expect(rootViewSource.contains("window.setFrame(frame, display: true)"))
        #expect(!rootViewSource.contains(".overlay {\n            MainWindowResizeAffordance()"))
        #expect(!rootViewSource.contains("window.toolbar = nil"))
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
        #expect(todoHomeSource.contains("todoEndDropTarget"))
        #expect(todoHomeSource.contains(".padding(.bottom, 6)"))
        #expect(!todoHomeSource.contains(".frame(height: 28)"))
        #expect(!todoHomeSource.contains(".padding(.bottom, 28)"))
        #expect(todoHomeSource.contains("private func moveTodo"))
        #expect(todoHomeSource.contains("TodoListPlanner.reorderedTodos"))
        #expect(todoHomeSource.contains("TodoListPlanner.reorderedTodosAfterCompletionChange"))
        #expect(todoEditorSource.contains("defaultSortOrder"))
        #expect(todoEditorSource.contains("sortOrder: defaultSortOrder"))
        #expect(rootSource.contains("String(todo.sortOrder ?? -1)"))
    }

    @Test("todo header uses theme icon-only actions")
    func todoHeaderUsesThemeIconOnlyActions() throws {
        let root = try packageRoot()
        let todoHomeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift")

        let todoHomeSource = try String(contentsOf: todoHomeFile, encoding: .utf8)
        let headerSource = try sourceWindow(
            in: todoHomeSource,
            from: "private var header",
            length: 3_400
        )
        let addTodoButtonSource = try sourceWindow(
            in: headerSource,
            from: "Image(systemName: \"plus\")",
            length: 520
        )

        #expect(headerSource.contains("Image(systemName: \"pencil\")"))
        #expect(headerSource.contains("Image(systemName: \"folder.badge.plus\")"))
        #expect(headerSource.contains("Image(systemName: \"plus\")"))
        #expect(addTodoButtonSource.contains(".frame(width: 48, height: 48)"))
        #expect(!addTodoButtonSource.contains(".frame(width: 58, height: 58)"))
        #expect(headerSource.contains(".accessibilityLabel(PlannerCopy.text(.editTodoGroup"))
        #expect(headerSource.contains(".accessibilityLabel(PlannerCopy.text(.newTodoGroup"))
        #expect(headerSource.contains(".accessibilityLabel(PlannerCopy.text(.addTodo"))
        #expect(!headerSource.contains("Label(PlannerCopy.text(.editTodoGroup, language: appLanguage), systemImage"))
        #expect(!headerSource.contains("Label(PlannerCopy.text(.newTodoGroup, language: appLanguage), systemImage"))
        #expect(!headerSource.contains("Label(PlannerCopy.text(.addTodo, language: appLanguage), systemImage"))
    }

    @Test("iOS todo group editor uses themed scroll cards with horizontal colors and delete")
    func iosTodoGroupEditorUsesThemedScrollCardsWithHorizontalColorsAndDelete() throws {
        let root = try packageRoot()
        let todoHomeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift")
        let plannerFile = root.appendingPathComponent("Sources/MeowPlannerCore/Services/TodoListPlanner.swift")
        let copyFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let todoHomeSource = try String(contentsOf: todoHomeFile, encoding: .utf8)
        let plannerSource = try String(contentsOf: plannerFile, encoding: .utf8)
        let copySource = try String(contentsOf: copyFile, encoding: .utf8)
        let iosGroupEditorSource = try #require(sourceBlock(
            in: todoHomeSource,
            from: "private var iosGroupEditorBody",
            to: "    #endif"
        ))
        let paletteSource = try sourceWindow(
            in: todoHomeSource,
            from: "private var paletteColorControls",
            length: 2_400
        )

        #expect(todoHomeSource.contains("@State private var showingDeleteTodoGroupConfirmation = false"))
        #expect(todoHomeSource.contains("@Query(sort: \\TodoItem.createdAt) private var todos: [TodoItem]"))
        #expect(todoHomeSource.contains("@State private var groupEditorPresentation: TodoGroupEditorPresentation?"))
        #expect(todoHomeSource.contains(".sheet(item: $groupEditorPresentation)"))
        #expect(todoHomeSource.contains("TodoGroupEditorPresentation.new"))
        #expect(todoHomeSource.contains("TodoGroupEditorPresentation.edit("))
        #expect(todoHomeSource.contains("private var desktopGroupEditorBody"))
        #expect(iosGroupEditorSource.contains("ScrollView"))
        #expect(iosGroupEditorSource.contains("iosGroupEditorCard"))
        #expect(paletteSource.contains("ScrollView(.horizontal, showsIndicators: false)"))
        #expect(iosGroupEditorSource.contains("safeAreaInset(edge: .bottom)"))
        #expect(iosGroupEditorSource.contains("iosGroupBottomSaveBar"))
        #expect(iosGroupEditorSource.contains("iosDeleteGroupButton"))
        #expect(!iosGroupEditorSource.contains("Form {"))
        #expect(todoHomeSource.contains(".confirmationDialog(PlannerCopy.text(.deleteTodoGroup"))
        #expect(todoHomeSource.contains("private func deleteGroup()"))
        #expect(todoHomeSource.contains("TodoListPlanner.moveTodosToDefaultGroup"))
        #expect(todoHomeSource.contains("modelContext.delete(group)"))
        #expect(plannerSource.contains("public static func moveTodosToDefaultGroup"))
        #expect(copySource.contains("case deleteTodoGroup"))
        #expect(copySource.contains(".deleteTodoGroup: \"Delete Group\""))
        #expect(copySource.contains(".deleteTodoGroup: \"删除组\""))
    }

    @Test("iOS todo editor uses themed scroll cards with bottom save and delete")
    func iosTodoEditorUsesThemedScrollCardsWithBottomSaveAndDelete() throws {
        let root = try packageRoot()
        let todoEditorFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoEditorView.swift")
        let copyFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let todoEditorSource = try String(contentsOf: todoEditorFile, encoding: .utf8)
        let copySource = try String(contentsOf: copyFile, encoding: .utf8)
        let iosEditorSource = try sourceWindow(
            in: todoEditorSource,
            from: "private var iosEditorBody",
            length: 4_600
        )

        #expect(todoEditorSource.contains("@State private var showingDeleteTodoConfirmation = false"))
        #expect(todoEditorSource.contains("private var desktopEditorBody"))
        #expect(todoEditorSource.contains("private var iosEditorTitleFont: Font"))
        #expect(todoEditorSource.contains("private var iosEditorRowFont: Font"))
        #expect(todoEditorSource.contains("private var iosEditorActionFont: Font"))
        #expect(iosEditorSource.contains("ScrollView"))
        #expect(iosEditorSource.contains("iosEditorCard"))
        #expect(iosEditorSource.contains("safeAreaInset(edge: .bottom)"))
        #expect(iosEditorSource.contains("iosBottomSaveBar"))
        #expect(iosEditorSource.contains("iosDeleteTodoButton"))
        #expect(!iosEditorSource.contains("Form {"))
        #expect(todoEditorSource.contains(".confirmationDialog(PlannerCopy.text(.deleteTodo"))
        #expect(todoEditorSource.contains("private func deleteTodo()"))
        #expect(todoEditorSource.contains("modelContext.delete(todo)"))
        #expect(copySource.contains("case deleteTodo"))
        #expect(copySource.contains(".deleteTodo: \"Delete Todo\""))
        #expect(copySource.contains(".deleteTodo: \"删除待办\""))
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
        #expect(source.contains("ScrollView(.vertical)"))
        #expect(source.contains(".verticalPageScrollOnly()"))
        #expect(!source.contains(".frame(minWidth: 760, minHeight: 640"))
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

    @Test("iOS course timetable uses compact top navigation and responsive grid metrics")
    func iOSCourseTimetableUsesCompactTopNavigationAndResponsiveGridMetrics() throws {
        let root = try packageRoot()
        let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let shellFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let timetableCaseSource = try sourceWindow(
            in: rootSource,
            from: "case .timetable:",
            length: 260
        )
        let gridSource = try sourceWindow(
            in: timetableSource,
            from: "private struct CourseTimetableGridView",
            length: 26_000
        )

        #expect(rootSource.contains("@StateObject private var iosTimetableNavigationState = IOSTimetableNavigationState()"))
        #expect(timetableCaseSource.contains("CourseTimetableView(iosNavigationState: iosTimetableNavigationState)"))
        #expect(shellSource.contains("final class IOSTimetableNavigationState"))
        #expect(shellSource.contains("timetableNavigationBarCenter"))
        #expect(shellSource.contains("selection == .timetable"))
        #expect(gridSource.contains("@ObservedObject var iosNavigationState: IOSTimetableNavigationState"))
        #expect(gridSource.contains("syncIOSTimetableNavigationState()"))
        #expect(gridSource.contains("private var usesCompactLayout: Bool"))
        #expect(gridSource.contains("private func dayColumnWidth"))
        #expect(gridSource.contains("let dayWidth = dayColumnWidth"))
        #expect(!gridSource.contains("max(60,"))
    }

    @Test("iOS course timetable picker separates timetable switching from week selection")
    func iOSCourseTimetablePickerSeparatesTimetableSwitchingFromWeekSelection() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let gridSource = try sourceWindow(
            in: timetableSource,
            from: "private struct CourseTimetableGridView",
            length: 22_000
        )

        #expect(gridSource.contains("@State private var showingTimetableSwitcher = false"))
        #expect(gridSource.contains("weekPickerTimetableSwitchButton"))
        #expect(gridSource.contains("showingTimetableSwitcher = true"))
        #expect(gridSource.contains("timetableSwitcherSheet"))
        #expect(gridSource.contains("selectedTimetableID = option.id"))
        #expect(gridSource.contains("selectedWeek = 1"))
        #expect(gridSource.contains("onCreateTimetable()"))
    }

    @Test("iOS course timetable week picker keeps week labels on one line")
    func iOSCourseTimetableWeekPickerKeepsWeekLabelsOnOneLine() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let weekPickerSource = try sourceWindow(
            in: timetableSource,
            from: "private var weekPickerSheet",
            length: 5_500
        )

        #expect(weekPickerSource.contains("weekPickerTitleFont"))
        #expect(weekPickerSource.contains("weekPickerDateFont"))
        #expect(weekPickerSource.contains("Text(weekTitle(for: week))"))
        #expect(weekPickerSource.contains(".lineLimit(1)"))
        #expect(weekPickerSource.contains(".minimumScaleFactor(0.62)"))
        #expect(weekPickerSource.contains("GridItem(.flexible(minimum: 42), spacing: 10)"))
    }

    @Test("iOS horizontal swipe detector switches weeks with a real drag gesture")
    func iOSHorizontalSwipeDetectorSwitchesWeeksWithARealDragGesture() throws {
        let root = try packageRoot()
        let themeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")

        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)
        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let iOSDetectorSource = try sourceWindow(
            in: themeSource,
            from: "#else\nstruct HorizontalSwipeScrollDetector: View",
            length: 1_600
        )

        #expect(iOSDetectorSource.contains("DragGesture(minimumDistance: threshold"))
        #expect(iOSDetectorSource.contains("let horizontal = value.translation.width"))
        #expect(iOSDetectorSource.contains("guard abs(horizontal) > abs(vertical)"))
        #expect(iOSDetectorSource.contains("onSwipe(horizontal)"))
        #expect(timetableSource.contains("HorizontalSwipeScrollDetector { horizontal in"))
        #expect(timetableSource.contains("switchWeek(by: horizontal < 0 ? 1 : -1)"))
    }

    @Test("iOS course editor uses themed responsive sheet layout")
    func iOSCourseEditorUsesThemedResponsiveSheetLayout() throws {
        let root = try packageRoot()
        let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let courseEditorSource = try sourceWindow(
            in: timetableSource,
            from: "private struct CourseEditorView",
            length: 10_000
        )
        let iosEditorSource = try sourceWindow(
            in: courseEditorSource,
            from: "private var iosEditorBody",
            length: 8_000
        )

        #expect(courseEditorSource.contains("@ViewBuilder"))
        #expect(courseEditorSource.contains("private var platformEditorBody"))
        #expect(courseEditorSource.contains("private var iosEditorTitleFont: Font"))
        #expect(iosEditorSource.contains("NavigationStack"))
        #expect(iosEditorSource.contains("ScrollView"))
        #expect(iosEditorSource.contains("iosEditorCard"))
        #expect(iosEditorSource.contains("safeAreaInset(edge: .bottom)"))
        #expect(iosEditorSource.contains("iosBottomSaveBar"))
        #expect(iosEditorSource.contains(".presentationDetents([.large])"))
        #expect(iosEditorSource.contains("LazyVGrid(columns: iosColorColumns"))
        #expect(iosEditorSource.contains("LazyVGrid(columns: iosWeekdayColumns"))
        #expect(!iosEditorSource.contains(".frame(minWidth: 560"))
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

    @Test("iOS schedule agenda keeps compact fixed controls above a scrollable timeline")
    func iosScheduleAgendaKeepsCompactFixedControlsAboveScrollableTimeline() throws {
        let root = try packageRoot()
        let rootSource = try String(
            contentsOf: root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift"),
            encoding: .utf8
        )
        let scheduleBodySource = try sourceWindow(
            in: rootSource,
            from: "private var schedulePageContent",
            length: 2_700
        )
        let scheduleIOSHeaderSource = try #require(sourceBlock(
            in: rootSource,
            from: "    private var scheduleHeader: some View {\n        #if os(iOS)",
            to: "        #else"
        ))
        let dateButtonSource = try sourceWindow(
            in: rootSource,
            from: "private var scheduleDatePickerButton",
            length: 1_500
        )
        let timeGridSource = try sourceWindow(
            in: rootSource,
            from: "private struct ScheduleTimeGridView",
            length: 6_000
        )
        let earlyMorningSource = try sourceWindow(
            in: rootSource,
            from: "private var earlyMorningToggle",
            length: 900
        )

        #expect(scheduleBodySource.contains("#if os(iOS)"))
        #expect(!scheduleBodySource.contains("ScrollView(.vertical, showsIndicators: false)"))
        #expect(scheduleBodySource.contains("schedulePageContent"))
        #expect(scheduleBodySource.contains("scheduleTimelineContent"))
        #expect(!scheduleBodySource.contains(".padding(.bottom, 10)"))
        #expect(scheduleBodySource.contains(".padding()\n            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)"))
        #expect(scheduleBodySource.contains("#else"))
        #expect(scheduleBodySource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)"))
        #expect(scheduleIOSHeaderSource.contains("scheduleModePicker"))
        #expect(!scheduleIOSHeaderSource.contains("FuFuAssetImage(size: 44)"))
        #expect(!scheduleIOSHeaderSource.contains("scheduleDatePickerButton"))
        #expect(dateButtonSource.contains(".lineLimit(1)"))
        #expect(dateButtonSource.contains(".font(scheduleIOSDateTitleFont)"))
        #expect(dateButtonSource.contains(".font(scheduleIOSDateSubtitleFont)"))
        #expect(dateButtonSource.contains(".layoutPriority(1)"))
        #expect(timeGridSource.contains("private var fixedTimelineHeader"))
        #expect(timeGridSource.contains("private var scrollableTimelineRows"))
        #expect(timeGridSource.contains("var usesOuterVerticalScroll: Bool = false"))
        #expect(timeGridSource.contains("if usesOuterVerticalScroll"))
        #expect(timeGridSource.contains("ScrollView(.vertical)"))
        #expect(timeGridSource.contains("timelineDayWidth"))
        #expect(timeGridSource.contains("mode == .weekly"))
        #expect(!timeGridSource.contains("max(80,"))
        #expect(earlyMorningSource.contains("frame(minWidth: 96, alignment: .leading)"))
        #expect(earlyMorningSource.contains(".lineLimit(1)"))
        #expect(!earlyMorningSource.contains(".frame(width: timeColumnWidth, alignment: .leading)"))
    }

    @Test("iOS schedule reuses calendar-style top date navigation with a day wheel picker")
    func iOSScheduleReusesCalendarStyleTopDateNavigationWithDayWheelPicker() throws {
        let root = try packageRoot()
        let rootViewFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let shellFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")
        let calendarHomeFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let rootSource = try String(contentsOf: rootViewFile, encoding: .utf8)
        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let scheduleCaseSource = try sourceWindow(
            in: rootSource,
            from: "case .schedule:",
            length: 420
        )
        let scheduleSource = try sourceWindow(
            in: rootSource,
            from: "private struct ScheduleAgendaView",
            length: 13_500
        )
        let scheduleIOSHeaderSource = try #require(sourceBlock(
            in: rootSource,
            from: "    private var scheduleHeader: some View {\n        #if os(iOS)",
            to: "        #else"
        ))

        #expect(scheduleCaseSource.contains("ScheduleAgendaView(iosNavigationState: iosCalendarNavigationState)"))
        #expect(scheduleSource.contains("@ObservedObject private var iosNavigationState: IOSCalendarNavigationState"))
        #expect(scheduleSource.contains("syncIOSScheduleNavigationState()"))
        #expect(scheduleSource.contains("displayedMonthTitle: scheduleIOSNavigationTitle"))
        #expect(scheduleSource.contains("resetToToday: { resetScheduleDateToToday() }"))
        #expect(scheduleSource.contains("presentMonthPicker: { presentIOSScheduleDatePicker() }"))
        #expect(scheduleSource.contains("IOSScheduleWheelDatePickerSheet("))
        #expect(scheduleSource.contains(".presentationDetents([.height(320)])"))
        #expect(scheduleSource.contains("private var scheduleIOSNavigationTitle"))
        #expect(rootSource.contains("String(format: \"%04d.%02d.%02d\""))
        #expect(rootSource.contains("Picker(\"Day\", selection: $selectedDay)"))
        #expect(rootSource.contains("@State private var selectedDay: Int"))
        #expect(rootSource.contains("private var daysInSelectedMonth"))
        #expect(rootSource.contains("private func dayText(for day: Int)"))
        #expect(!scheduleSource.contains("iosNavigationState.clear()"))
        #expect(!calendarHomeSource.contains("iosNavigationState.clear()"))
        #expect(scheduleIOSHeaderSource.contains("scheduleModePicker"))
        #expect(!scheduleIOSHeaderSource.contains("FuFuAssetImage(size: 44)"))
        #expect(!scheduleIOSHeaderSource.contains("scheduleDatePickerButton"))
        #expect(shellSource.contains("if selection == .calendar || selection == .schedule"))
        #expect(shellSource.contains("if selection == .calendar {\n                calendarScheduleDisplayMenu"))
        #expect(calendarHomeSource.contains("IOSCalendarWheelDatePickerSheet("))
        #expect(!calendarHomeSource.contains("Picker(\"Day\", selection: $selectedDay)"))
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
        #expect(monthGridSource.contains("chineseCalendarBadge(displayChineseCalendarInfo(for: day))"))
        #expect(monthGridSource.contains("private func displayChineseCalendarInfo(for day: MonthPlannerDay) -> ChineseCalendarDayInfo"))
        #expect(monthGridSource.contains("#if os(iOS)\n        return day.chineseCalendarInfo"))
        #expect(monthGridSource.contains("ChineseCalendarInfoProvider.displayInfo("))
        #expect(monthGridSource.contains("includesFloatingGregorianObservances: true"))
        #expect(monthGridSource.contains("info.isFestival"))
        #expect(dayAgendaSource.contains("ChineseCalendarInfoProvider.info(for: selectedDate"))
        #expect(dayAgendaSource.contains("ChineseCalendarInfoProvider.displayInfo("))
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
        #expect(homeSource.contains("Image(systemName: \"tag.circle\")"))
        #expect(!homeSource.contains("Image(systemName: \"line.3.horizontal.decrease.circle\")"))
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
        #expect(homeSource.contains("PlannerImageBackground(gradientOpacity: 0.86)"))
        #expect(!homeSource.contains("PlannerPawStarBackground(gradientOpacity: 0.86)"))
        #expect(!monthGridSource.contains("calendarWatermark"))
        #expect(monthGridSource.contains("HorizontalSwipeScrollDetector"))
        #expect(monthGridSource.contains("MeowPlannerTheme.color(hex: item.colorHex)"))
        #expect(!monthGridSource.contains("Text(item.tagName)"))
        #expect(!monthGridSource.contains("if !item.tagName.isEmpty"))
        #expect(dayAgendaSource.contains("DayAgendaView"))
        #expect(!dayAgendaSource.contains(".background(.regularMaterial"))
    }

    @Test("calendar floating add button scales with window and clamps above bottom navigation")
    func calendarFloatingAddButtonScalesWithWindowAndClampsAboveBottomNavigation() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)

        #expect(homeSource.contains("let buttonSize = floatingAddButtonSize(for: proxy.size)"))
        #expect(homeSource.contains("let inset = calendarFloatingAddButtonEdgeInset(for: buttonSize)"))
        #expect(homeSource.contains("let bottomInset = calendarFloatingAddButtonBottomInset(for: buttonSize)"))
        #expect(homeSource.contains("floatingAddScheduleButton(size: buttonSize)"))
        #expect(homeSource.contains("private func floatingAddButtonSize(for availableSize: CGSize) -> CGFloat"))
        #expect(homeSource.contains("private func calendarFloatingAddButtonEdgeInset(for buttonSize: CGFloat) -> CGFloat"))
        #expect(homeSource.contains("private func calendarFloatingAddButtonBottomInset(for buttonSize: CGFloat) -> CGFloat"))
        #expect(!homeSource.contains("calendarFloatingAddButtonEdgeInset(for: buttonSize)\n            + IOSAppNavigationMetrics.bottomNavigationRaisedPadding"))
        #expect(homeSource.contains("private func calendarFloatingAddButtonBottomInset(for buttonSize: CGFloat) -> CGFloat {\n        calendarFloatingAddButtonEdgeInset(for: buttonSize)\n    }"))
        #expect(!homeSource.contains("calendarFloatingAddButtonEdgeInset(for: buttonSize)\n            + iosCalendarBottomReserve"))
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

    @Test("event editor can delete an existing schedule from the bottom of the form")
    func eventEditorCanDeleteExistingScheduleFromBottomOfForm() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let editorSource = try #require(sourceBlock(
            in: homeSource,
            from: "private struct EventEditorView",
            to: "private struct FuFuDatePickerRow"
        ))
        let formSource = sourceBlock(
            in: editorSource,
            from: "Form {",
            to: ".formStyle(.grouped)"
        ) ?? editorSource
        let notesRange = try #require(formSource.range(of: "TextField(PlannerCopy.text(.notes"))
        let deleteButtonRange = try #require(formSource.range(of: "deleteEventButton"))

        #expect(notesRange.lowerBound < deleteButtonRange.lowerBound)
        #expect(editorSource.contains("@State private var showingDeleteEventConfirmation = false"))
        #expect(editorSource.contains("if event != nil {"))
        #expect(editorSource.contains("deleteEventButton"))
        #expect(editorSource.contains("Label(PlannerCopy.text(.deleteSchedule"))
        #expect(editorSource.contains(".confirmationDialog(PlannerCopy.text(.deleteSchedule"))
        #expect(editorSource.contains("Button(PlannerCopy.text(.deleteSchedule, language: appLanguage), role: .destructive)"))
        #expect(editorSource.contains("private func deleteEvent()"))
        #expect(editorSource.contains("modelContext.delete(event)"))
        #expect(editorSource.contains("WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)"))
        #expect(languageSource.contains("case deleteSchedule"))
        #expect(languageSource.contains(".deleteSchedule: \"Delete Schedule\""))
        #expect(languageSource.contains(".deleteSchedule: \"删除日程\""))
    }

    @Test("iOS event editor uses themed scroll cards with bottom save and delete")
    func iosEventEditorUsesThemedScrollCardsWithBottomSaveAndDelete() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let iosEditorSource = try sourceWindow(
            in: homeSource,
            from: "private var iosEditorBody",
            length: 3_600
        )

        #expect(iosEditorSource.contains("ScrollView"))
        #expect(iosEditorSource.contains("iosEditorCard"))
        #expect(iosEditorSource.contains("safeAreaInset(edge: .bottom)"))
        #expect(iosEditorSource.contains("iosBottomSaveBar"))
        #expect(iosEditorSource.contains("iosDeleteEventButton"))
        #expect(!iosEditorSource.contains("Form {"))
        #expect(iosEditorSource.contains("MeowPlannerTheme.plannerGradient"))
        #expect(homeSource.contains("private var iosTitleMetadataScroll"))
        #expect(homeSource.contains("private var iosRepeatChip"))
        #expect(homeSource.contains("Menu {"))
    }

    @Test("iOS event editor uses compact font scale")
    func iosEventEditorUsesCompactFontScale() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let titleCardSource = try sourceWindow(
            in: homeSource,
            from: "private var iosTitleCard",
            length: 1_000
        )
        let toggleRowSource = try sourceWindow(
            in: homeSource,
            from: "private func iosToggleRow",
            length: 700
        )
        let saveBarSource = try sourceWindow(
            in: homeSource,
            from: "private var iosBottomSaveBar",
            length: 700
        )

        #expect(homeSource.contains("private var iosEditorTitleFont: Font"))
        #expect(homeSource.contains("private var iosEditorRowFont: Font"))
        #expect(homeSource.contains("private var iosEditorActionFont: Font"))
        #expect(titleCardSource.contains(".font(iosEditorTitleFont)"))
        #expect(toggleRowSource.contains(".font(iosEditorRowFont)"))
        #expect(saveBarSource.contains(".font(iosEditorActionFont)"))
    }

    @Test("iOS event editor header color chip opens the built-in palette")
    func iosEventEditorHeaderColorChipOpensBuiltInPalette() throws {
        let root = try packageRoot()
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let colorChipSource = try sourceWindow(
            in: homeSource,
            from: "private var iosColorChip",
            length: 800
        )
        let defaultPaletteSource = try sourceWindow(
            in: homeSource,
            from: "private struct IOSDefaultColorPaletteSheet",
            length: 2_600
        )

        #expect(homeSource.contains("@State private var showingIOSColorPaletteSelector = false"))
        #expect(homeSource.contains(".sheet(isPresented: $showingIOSColorPaletteSelector)"))
        #expect(homeSource.contains("IOSDefaultColorPaletteSheet("))
        #expect(homeSource.contains("showingIOSColorPaletteSelector = false"))
        #expect(colorChipSource.contains("Button"))
        #expect(colorChipSource.contains("showingIOSColorPaletteSelector = true"))
        #expect(!colorChipSource.contains("openPaletteColorEditor(colorHex)"))
        #expect(colorChipSource.contains(".buttonStyle(.plain)"))
        #expect(colorChipSource.contains(".accessibilityLabel(PlannerCopy.text(.color"))
        #expect(defaultPaletteSource.contains("ForEach(colorHexes, id: \\.self)"))
        #expect(defaultPaletteSource.contains("onSelect(option)"))
        #expect(defaultPaletteSource.contains("dismiss()"))
        #expect(defaultPaletteSource.contains(".frame(width: 44, height: 44)"))
        #expect(defaultPaletteSource.contains(".contentShape(Circle())"))
        #expect(!defaultPaletteSource.contains("ColorPicker"))
        #expect(!defaultPaletteSource.contains("colorHexInput"))
    }

    @Test("primary app surfaces use the unified FuFu warm background")
    func primaryAppSurfacesUseUnifiedFuFuWarmBackground() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let todoFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift")
        let timetableFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
        let focusFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Focus/FocusView.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let todoSource = try String(contentsOf: todoFile, encoding: .utf8)
        let timetableSource = try String(contentsOf: timetableFile, encoding: .utf8)
        let focusSource = try String(contentsOf: focusFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)

        #expect(rootSource.contains("private var schedulePageBackground"))
        #expect(rootSource.contains("#if os(iOS)\n        Color.clear"))
        #expect(rootSource.contains("schedulePageBackground"))
        #expect(rootSource.contains(".scrollContentBackground(.hidden)"))
        #expect(rootSource.contains(".ignoresSafeArea()"))
        #expect(rootSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
        #expect(homeSource.contains("PlannerImageBackground(gradientOpacity: 0.86)"))
        #expect(homeSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
        #expect(!homeSource.contains("mainBackgroundMotifs"))
        #expect(!homeSource.contains("fufuBackgroundWatermark("))
        #expect(todoSource.contains("private var todoPageBackground"))
        #expect(todoSource.contains("#if os(iOS)\n        Color.clear"))
        #expect(todoSource.contains("todoPageBackground"))
        #expect(timetableSource.contains("private var timetablePageBackground"))
        #expect(timetableSource.contains("#if os(iOS)\n        Color.clear"))
        #expect(timetableSource.contains("timetablePageBackground"))
        #expect(focusSource.contains("private var focusPageBackground"))
        #expect(focusSource.contains("#if os(iOS)\n            Color.clear"))
        #expect(focusSource.contains("focusTimerPanelBackgroundOpacity"))
        #expect(focusSource.contains("return 0.18"))
        #expect(!focusSource.contains(".background(MeowPlannerTheme.plannerGradient)"))
        #expect(focusSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity"))
        #expect(settingsSource.contains("#if os(iOS)\n        PlannerIOSImageBackground(gradientOpacity: 0.86)"))
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
        #expect(monthGridSource.contains("desktopDayContentSpacing: CGFloat = 2"))
        #expect(monthGridSource.contains("iosDayContentSpacing: CGFloat = 1"))
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

    @Test("iOS calendar uses fullscreen month grid and swipeable agenda cards")
    func iOSCalendarUsesFullscreenMonthGridAndSwipeableAgendaCards() throws {
        let root = try packageRoot()
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let iosFullScreenCalendarSource = try sourceWindow(
            in: calendarHomeSource,
            from: "private func iosFullScreenMonthCalendar",
            length: 1_200
        )

        #expect(calendarHomeSource.contains("@State private var agendaCardDate: Date?"))
        #expect(calendarHomeSource.contains("@State private var displayedMonth = Date()"))
        #expect(calendarHomeSource.contains("@State private var monthTransitionDirection = 1"))
        #expect(calendarHomeSource.contains("@State private var showingIOSDatePicker = false"))
        #expect(calendarHomeSource.contains("@ObservedObject private var iosNavigationState: IOSCalendarNavigationState"))
        #expect(calendarHomeSource.contains("init(iosNavigationState: IOSCalendarNavigationState, newScheduleRequestToken: UUID? = nil)"))
        #expect(calendarHomeSource.contains("syncIOSCalendarNavigationState()"))
        #expect(calendarHomeSource.contains("iosNavigationState.configure("))
        #expect(calendarHomeSource.contains("displayedMonthTitle: iosDisplayedMonthTitle"))
        #expect(calendarHomeSource.contains("selectedTagName: selectedEventTagName"))
        #expect(calendarHomeSource.contains("tagNames: eventFilterTagOptions"))
        #expect(calendarHomeSource.contains("#if os(iOS)"))
        #expect(calendarHomeSource.contains("private func iosFullScreenMonthCalendar(proxy: GeometryProxy)"))
        #expect(!calendarHomeSource.contains("iosCompactCalendarToolbar"))
        #expect(!calendarHomeSource.contains("iosDateToolbarTitle"))
        #expect(!calendarHomeSource.contains("ScheduleDisplayTagFilterMenu(\n                selectedTagName"))
        #expect(calendarHomeSource.contains("IOSCalendarWheelDatePickerSheet("))
        #expect(calendarHomeSource.contains("private let iosDatePickerYearRange = 1901...2099"))
        #expect(calendarHomeSource.contains(".presentationDetents([.height(320)])"))
        #expect(calendarHomeSource.contains("Picker(\"Year\", selection: $selectedYear)"))
        #expect(calendarHomeSource.contains("Picker(\"Month\", selection: $selectedMonth)"))
        #expect(!calendarHomeSource.contains("Picker(\"Day\", selection: $selectedDay)"))
        #expect(!calendarHomeSource.contains("@State private var selectedDay"))
        #expect(!calendarHomeSource.contains("private func dayText(for day: Int)"))
        #expect(!calendarHomeSource.contains("Text(iosDisplayedMonthTitle)"))
        #expect(calendarHomeSource.contains("monthTransitionDirection: $monthTransitionDirection"))
        #expect(calendarHomeSource.contains("monthTransitionDirection = targetMonth < displayedMonth ? -1 : 1"))
        #expect(!calendarHomeSource.contains("Picker(\"Year\", selection: iosDisplayedYearBinding)"))
        #expect(!calendarHomeSource.contains("Picker(\"Month\", selection: iosDisplayedMonthBinding)"))
        #expect(calendarHomeSource.contains("iosMonthGridHeight(for: proxy.size)"))
        #expect(calendarHomeSource.contains("let availableGridHeight = availableSize.height - reservedHeight"))
        #expect(calendarHomeSource.contains("return max(1, availableGridHeight)"))
        #expect(calendarHomeSource.contains("private let iosCalendarHorizontalPadding: CGFloat = 0"))
        #expect(calendarHomeSource.contains("private let iosCalendarBottomReserve: CGFloat = IOSAppNavigationMetrics.bottomNavigationRaisedPadding"))
        #expect(!calendarHomeSource.contains("-IOSAppNavigationMetrics.bottomNavigationRaisedPadding"))
        #expect(calendarHomeSource.contains(".padding(.horizontal, iosCalendarHorizontalPadding)"))
        #expect(!iosFullScreenCalendarSource.contains(".padding(.horizontal, 12)"))
        #expect(calendarHomeSource.contains("let bottomInset = calendarFloatingAddButtonBottomInset(for: buttonSize)"))
        #expect(!calendarHomeSource.contains("safeAreaInsets.bottom - 12"))
        #expect(!calendarHomeSource.contains("+ iosCalendarToolbarHeight"))
        #expect(calendarHomeSource.contains(".frame(height: iosMonthGridHeight"))
        #expect(calendarHomeSource.contains(".overlay(alignment: .center)"))
        #expect(calendarHomeSource.contains("iosAgendaCardOverlay"))
        #expect(calendarHomeSource.contains("Color.black.opacity"))
        #expect(calendarHomeSource.contains("dismissAgendaCard()"))
        #expect(calendarHomeSource.contains("@State private var agendaCardScrollAnchorDate = Date()"))
        #expect(calendarHomeSource.contains("ScrollView(.horizontal, showsIndicators: false)"))
        #expect(calendarHomeSource.contains("LazyHStack(spacing: agendaCardSpacing)"))
        #expect(calendarHomeSource.contains("agendaCardWidth(for: proxy.size.width)"))
        #expect(calendarHomeSource.contains(".scrollTargetLayout()"))
        #expect(calendarHomeSource.contains(".scrollTargetBehavior(.viewAligned)"))
        #expect(calendarHomeSource.contains(".scrollPosition(id: $agendaCardDate)"))
        #expect(calendarHomeSource.contains(".scrollTransition(.interactive, axis: .horizontal)"))
        #expect(!calendarHomeSource.contains("TabView(selection: agendaCardSelection)"))
        #expect(!calendarHomeSource.contains(".tabViewStyle(.page"))
        #expect(calendarHomeSource.contains("agendaCardDates(centeredOn:"))
        #expect(calendarHomeSource.contains("private func iosAgendaCard(for date: Date)"))
        #expect(calendarHomeSource.contains("let addButtonSize = floatingAddButtonSize(for: UIScreen.main.bounds.size)"))
        #expect(!calendarHomeSource.contains(".frame(width: 78, height: 78)"))
        #expect(calendarHomeSource.contains("presentAgendaCard(for date: Date)"))
        #expect(calendarHomeSource.contains("onDayTap: { presentAgendaCard(for: $0) }"))
        #expect(!calendarHomeSource.contains("list.bullet.rectangle"))
        #expect(!calendarHomeSource.contains(".sheet(item: $agendaSheetDate)"))
        #expect(!calendarHomeSource.contains("presentAgendaSheet"))
        #expect(monthGridSource.contains("var onDayTap: (Date) -> Void = { _ in }"))
        #expect(monthGridSource.contains("@Binding var displayedMonth: Date"))
        #expect(monthGridSource.contains("@Binding var monthTransitionDirection: Int"))
        #expect(!monthGridSource.contains("@State private var monthTransitionDirection = 1"))
        #expect(monthGridSource.contains("@GestureState private var monthDragTranslation: CGFloat = 0"))
        #expect(monthGridSource.contains("var showsMonthHeader: Bool = true"))
        #expect(monthGridSource.contains("if showsMonthHeader {"))
        #expect(monthGridSource.contains("let fixedHeaderHeight = showsMonthHeader ? monthGridHeaderHeight + monthGridContentSpacing : 0"))
        #expect(monthGridSource.contains("iosContinuousMonthPager(proxy: proxy)"))
        #expect(monthGridSource.contains("private func iosContinuousMonthPager(proxy: GeometryProxy)"))
        #expect(monthGridSource.contains(".modifier(IOSMonthPagerScrollTargetBehavior())"))
        #expect(monthGridSource.contains("private func updateDisplayedMonthFromIOSScrollPosition(_ month: Date)"))
        #expect(!monthGridSource.contains("private let iosAdjacentMonthPeek"))
        #expect(monthGridSource.contains("let pageWidth = max(1, proxy.size.width)"))
        #expect(!monthGridSource.contains(".contentMargins(.horizontal"))
        #expect(monthGridSource.contains(".id(displayedMonth)"))
        #expect(monthGridSource.contains(".offset(x: monthDragTranslation)"))
        #expect(monthGridSource.contains("private var monthGridTransition: AnyTransition"))
        #expect(monthGridSource.contains("onDayTap(date)"))
        #expect(monthGridSource.contains(".frame(height: layoutMetrics.gridHeight, alignment: .top)"))
        #expect(monthGridSource.contains("private var dayCellHorizontalInset: CGFloat"))
        #expect(monthGridSource.contains(".padding(.horizontal, dayCellHorizontalInset)"))
        #expect(monthGridSource.contains(".layoutPriority(2)"))
        #expect(monthGridSource.contains(".fixedSize(horizontal: true, vertical: false)"))
        #expect(monthGridSource.contains("private let iosMonthGridContentPadding: CGFloat = 0"))
        #expect(monthGridSource.contains("private let iosWeekdayHeaderHeight: CGFloat = 26"))
        #expect(monthGridSource.contains("private let iosPlannerItemRowHeight: CGFloat = 18"))
        #expect(monthGridSource.contains("private let iosMultiDaySegmentHeight: CGFloat = 18"))
        #expect(monthGridSource.contains("weekdayHeaderCell(symbol, height: layoutMetrics.weekdayHeaderHeight, isLastColumn: index == weekdaySymbols.count - 1)"))
        #expect(monthGridSource.contains("ForEach(Array(visiblePlannerDays.enumerated()), id: \\.element.id)"))
        #expect(monthGridSource.contains("isLastColumn: index % 7 == 6"))
        #expect(monthGridSource.contains("private func gridVerticalDivider(isLastColumn: Bool, isWeekdayHeader: Bool)"))
        #expect(monthGridSource.contains("if !isWeekdayHeader && !isLastColumn"))
        #expect(monthGridSource.contains("private var plannerItemShowsTitle: Bool"))
        #expect(monthGridSource.contains("#if os(iOS)\n        return true"))
        #expect(!monthGridSource.contains("private var plannerItemShowsIcon: Bool"))
        #expect(!monthGridSource.contains("plannerItemIconFont"))
        #expect(!monthGridSource.contains("Image(systemName: \"calendar\")"))
        #expect(monthGridSource.contains("private var plannerItemTextFont: Font"))
        #expect(monthGridSource.contains("return .system(size: 8.6, weight: .semibold)"))
        #expect(monthGridSource.contains("private var plannerItemMinimumScaleFactor: CGFloat"))
        #expect(monthGridSource.contains(".minimumScaleFactor(plannerItemMinimumScaleFactor)"))
        #expect(monthGridSource.contains(".allowsTightening(true)"))
        #expect(monthGridSource.contains("private var chineseCalendarFont"))
        #expect(monthGridSource.contains("private func shouldShowDayContent(_ day: MonthPlannerDay) -> Bool"))
        #expect(monthGridSource.contains("#if os(iOS)\n        return day.isInSelectedMonth"))
        #expect(monthGridSource.contains("let shouldShowContent = shouldShowDayContent(day)"))
        #expect(monthGridSource.contains("guard shouldShowContent else {\n                return\n            }\n            selectDate(day.date)"))
        #expect(monthGridSource.contains("if shouldShowContent {\n                        dayNumberLabel"))
        #expect(monthGridSource.contains("if showChineseCalendar {"))
        #expect(monthGridSource.contains("if shouldShowContent {\n                    plannerItemList(day, height: plannerItemListHeight, visibleDays: visibleDays)\n                }"))
        #expect(monthGridSource.contains(".accessibilityHidden(!shouldShowContent)"))
        #expect(monthGridSource.contains(".zIndex(shouldShowContent && dayStartsMultiDaySpan(day) ? 2 : 0)"))
        #expect(!monthGridSource.contains(".frame(minHeight: 58, alignment: .top)"))

        let agendaRowSource = try sourceWindow(
            in: calendarHomeSource,
            from: "private func iosAgendaEventRow",
            length: 1_600
        )
        #expect(agendaRowSource.contains("Button {"))
        #expect(agendaRowSource.contains("editEvent(event)"))
        #expect(!agendaRowSource.contains("Image(systemName: \"pencil\")"))
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
        let dockIconSectionSource = try #require(sourceBlock(
            in: settingsSource,
            from: "#if os(macOS)\n    private var dockIconSection",
            to: "    private var focusSection"
        ))

        #expect(dockIconSectionSource.contains("Section(PlannerCopy.text(.dockIcon"))
        #expect(dockIconSectionSource.contains("Toggle(PlannerCopy.text(.showDockIcon"))
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

    @Test("main calendar background uses bundled image with paw fallback available")
    func mainCalendarBackgroundUsesBundledImageWithPawFallbackAvailable() throws {
        let root = try packageRoot()
        let packageFile = root
            .appendingPathComponent("Package.swift")
        let generatorFile = root
            .appendingPathComponent("script/generate_xcode_project.py")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let iosBackgroundFile = root
            .appendingPathComponent("Resources/iOSBackground.png")
        let iosDarkBackgroundFile = root
            .appendingPathComponent("Resources/iOSBackgroundDark.png")
        let darkBackgroundFile = root
            .appendingPathComponent("Resources/BackgroundDark.png")
        let homeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let settingsFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Settings/SettingsView.swift")
        let shellFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Navigation/IOSNavigationShellView.swift")
        let themeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift")

        let packageSource = try String(contentsOf: packageFile, encoding: .utf8)
        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)
        let homeSource = try String(contentsOf: homeFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let settingsSource = try String(contentsOf: settingsFile, encoding: .utf8)
        let shellSource = try String(contentsOf: shellFile, encoding: .utf8)
        let themeSource = try String(contentsOf: themeFile, encoding: .utf8)
        let floatingAddButtonStart = try #require(homeSource.range(of: "private func floatingAddScheduleButton"))
        let floatingAddButtonEnd = try #require(
            homeSource[floatingAddButtonStart.lowerBound...].range(of: "private var header")
        )
        let floatingAddButtonSource = String(homeSource[floatingAddButtonStart.lowerBound..<floatingAddButtonEnd.lowerBound])
        let calendarBackgroundSource = try sourceWindow(
            in: homeSource,
            from: ".background {",
            length: 240
        )
        let backgroundMotifSource = try #require(sourceBlock(
            in: themeSource,
            from: "private var motifs",
            to: "private func pawMotif"
        ))
        let iosImageBackgroundSource = try #require(sourceBlock(
            in: themeSource,
            from: "struct PlannerIOSImageBackground",
            to: "struct PlannerImageBackground"
        ))

        #expect(FileManager.default.fileExists(atPath: iosBackgroundFile.path))
        #expect(FileManager.default.fileExists(atPath: iosDarkBackgroundFile.path))
        #expect(FileManager.default.fileExists(atPath: darkBackgroundFile.path))
        #expect(packageSource.contains(".copy(\"../../Resources/iOSBackground.png\")"))
        #expect(packageSource.contains(".copy(\"../../Resources/iOSBackgroundDark.png\")"))
        #expect(packageSource.contains(".copy(\"../../Resources/BackgroundDark.png\")"))
        #expect(generatorSource.contains("IOS_BACKGROUND_RESOURCE_FILES = ["))
        #expect(generatorSource.contains("\"Resources/iOSBackground.png\""))
        #expect(generatorSource.contains("\"Resources/iOSBackgroundDark.png\""))
        #expect(generatorSource.contains("\"Resources/BackgroundDark.png\""))
        #expect(project.contains("Resources/iOSBackground.png"))
        #expect(project.contains("Resources/iOSBackgroundDark.png"))
        #expect(project.contains("Resources/BackgroundDark.png"))
        #expect(shellSource.contains("PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(calendarBackgroundSource.contains("#if os(iOS)\n            Color.clear"))
        #expect(calendarBackgroundSource.contains("#else\n            PlannerImageBackground(gradientOpacity: 0.86)"))
        #expect(!homeSource.contains("#if os(iOS)\n            PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(!homeSource.contains("PlannerPawStarBackground(gradientOpacity: 0.86)"))
        #expect(themeSource.contains("struct PlannerIOSImageBackground"))
        #expect(iosImageBackgroundSource.contains("@Environment(\\.colorScheme)"))
        #expect(iosImageBackgroundSource.contains("colorScheme == .dark ? \"iOSBackgroundDark\" : \"iOSBackground\""))
        #expect(iosImageBackgroundSource.contains("forResource: backgroundResourceName"))
        #expect(themeSource.contains("colorScheme == .dark ? \"BackgroundDark\" : \"Background\""))
        #expect(themeSource.contains("forResource: backgroundResourceName"))
        #expect(themeSource.contains("PlannerPawStarBackground(gradientOpacity: gradientOpacity)"))
        #expect(settingsSource.contains("#if os(iOS)\n        PlannerIOSImageBackground(gradientOpacity: 0.86)"))
        #expect(!settingsSource.contains("PlannerPawStarBackground(gradientOpacity: 0.82)"))
        #expect(homeSource.contains("floatingAddScheduleButton"))
        #expect(themeSource.contains("struct PlannerPawStarBackground"))
        #expect(themeSource.contains("pawprint.fill"))
        #expect(themeSource.contains("pawMotif"))
        #expect(themeSource.contains("starMotif"))
        #expect(themeSource.contains("systemImage: String = \"sparkle\""))
        #expect(backgroundMotifSource.contains("systemImage: \"star.fill\""))
        #expect(backgroundMotifSource.contains("size: 212"))
        #expect(backgroundMotifSource.contains("size: 190"))
        #expect(backgroundMotifSource.contains("size: 152"))
        #expect(backgroundMotifSource.contains("size: 54"))
        #expect(backgroundMotifSource.contains("size: 44"))
        #expect(backgroundMotifSource.contains("x: -0.08"))
        #expect(backgroundMotifSource.contains("x: 1.06"))
        #expect(backgroundMotifSource.contains("x: 0.48"))
        #expect(backgroundMotifSource.contains("y: 0.43"))
        #expect(backgroundMotifSource.contains("y: 0.76"))
        #expect(backgroundMotifSource.contains("opacity(0.075)"))
        #expect(backgroundMotifSource.contains("opacity(0.045)"))
        #expect(monthGridSource.contains("monthGridOuterChrome"))
        #expect(monthGridSource.contains("#if os(iOS)\n        content\n        #else"))
        #expect(!monthGridSource.contains(".background(\n            LinearGradient"))
        #expect(!backgroundMotifSource.contains("centerPawWatermark"))
        #expect(!backgroundMotifSource.contains("cornerPawWatermark"))
        #expect(!backgroundMotifSource.contains("x: 0.055"))
        #expect(!backgroundMotifSource.contains("x: 0.945"))
        #expect(!backgroundMotifSource.contains("y: 0.92"))
        #expect(!backgroundMotifSource.contains("size: 320"))
        #expect(!backgroundMotifSource.contains("size: 330"))
        #expect(!backgroundMotifSource.contains("opacity(0.12)"))
        #expect(!backgroundMotifSource.contains("opacity(0.10)"))
        #expect(!backgroundMotifSource.contains("x: 0.50"))
        #expect(!backgroundMotifSource.contains("y: 0.38"))
        #expect(!themeSource.contains("fufuBackgroundWatermark"))
        #expect(!homeSource.contains("pawTrail"))
        #expect(!homeSource.contains("PawStep"))
        #expect(!homeSource.contains("fufuPawTint.opacity(0.12)"))
        #expect(!floatingAddButtonSource.contains("Image(systemName: \"plus\")"))
        #expect(!monthGridSource.contains("FuFuAssetImage"))
        #expect(themeSource.contains("fufuPlannerBackground"))
        #expect(themeSource.contains("fufuCalendarBackground"))
        #expect(!homeSource.contains("CatEarsMotif"))
        #expect(!monthGridSource.contains("CatEarsMotif"))
        #expect(!themeSource.contains("struct CatEarsMotif"))
    }

    @Test("macOS month grid keeps light grid and stronger selected day tint")
    func macOSMonthGridKeepsLightGridAndStrongerSelectedDayTint() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let outerChromeSource = try sourceWindow(
            in: monthGridSource,
            from: "private struct MonthGridOuterChrome",
            length: 700
        )
        let weekdayHeaderSource = try sourceWindow(
            in: monthGridSource,
            from: "private func weekdayHeaderCell",
            length: 900
        )
        let dayBackgroundSource = try sourceWindow(
            in: monthGridSource,
            from: "private func dayBackground",
            length: 850
        )
        let dayCellBackgroundSource = try sourceWindow(
            in: monthGridSource,
            from: "private func dayCellGridBackground",
            length: 900
        )

        #expect(monthGridSource.contains(".overlay { monthGridBorder }"))
        #expect(monthGridSource.contains("private var monthGridBorder"))
        #expect(monthGridSource.contains("private var monthGridBorderOpacity"))
        #expect(monthGridSource.contains("private var gridDividerOpacity"))
        #expect(outerChromeSource.contains("#else\n        content\n        #endif"))
        #expect(!outerChromeSource.contains("LinearGradient"))
        #expect(weekdayHeaderSource.contains("weekdayHeaderBackground"))
        #expect(weekdayHeaderSource.contains("gridHorizontalDivider"))
        #expect(weekdayHeaderSource.contains("gridVerticalDivider"))
        #expect(monthGridSource.contains("MeowPlannerTheme.monthGridDivider.opacity(monthGridBorderOpacity)"))
        #expect(monthGridSource.contains("MeowPlannerTheme.monthGridDivider.opacity(gridDividerOpacity)"))
        #expect(monthGridSource.contains("return 0.24"))
        #expect(monthGridSource.contains("return 0.20"))
        #expect(!monthGridSource.contains("#if os(macOS)\n                calendarWatermark"))
        #expect(dayBackgroundSource.contains("#else"))
        #expect(dayBackgroundSource.contains("MeowPlannerTheme.monthGridSelectedDayBackground.opacity(0.34)"))
        #expect(dayBackgroundSource.contains("Color.clear"))
        #expect(dayCellBackgroundSource.contains("gridHorizontalDivider"))
        #expect(dayCellBackgroundSource.contains("gridVerticalDivider"))
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

        #expect(monthGridSource.contains("monthGridSelectedDayBackground.opacity(0.34)"))
        #expect(monthGridSource.contains("monthGridDivider"))
        #expect(monthGridSource.contains("weekdayHeaderBackground"))
        #expect(monthGridSource.contains("Color.clear"))
        #expect(!monthGridSource.contains("monthGridCurrentMonthCellBackground"))
        #expect(!monthGridSource.contains("monthGridOutsideMonthCellBackground"))
        #expect(!monthGridSource.contains("monthGridHeaderBackground"))
        #expect(themeSource.contains("static let monthGridSelectedDayBackground = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridCurrentMonthCellBackground = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridOutsideMonthCellBackground = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridDivider = adaptiveColor"))
        #expect(themeSource.contains("static let monthGridHeaderBackground = adaptiveColor"))
        #expect(!monthGridSource.contains("Color.white.opacity(0.30)"))
        #expect(!monthGridSource.contains("Color.primary.opacity(0.025)"))
    }

    @Test("month calendar highlights today by wrapping the date number in a brown circle")
    func monthCalendarHighlightsTodayByWrappingTheDateNumberInABrownCircle() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(monthGridSource.contains("let isToday = calendar.isDateInToday(day.date)"))
        #expect(monthGridSource.contains("dayNumberLabel(day.date, isToday: isToday, isSelected: isSelected, isInSelectedMonth: day.isInSelectedMonth)"))
        #expect(monthGridSource.contains("private func dayNumberLabel("))
        #expect(monthGridSource.contains(".background(MeowPlannerTheme.pawButtonBrown, in: Circle())"))
        #expect(monthGridSource.contains(".foregroundStyle(isToday ? .white"))
        #expect(monthGridSource.contains("todayBadgeSize"))
        #expect(monthGridSource.contains("dayCellGridBackground(isSelected: isSelected, isToday: isToday, isInSelectedMonth: day.isInSelectedMonth, isLastColumn: isLastColumn)"))
        #expect(monthGridSource.contains("dayBackground(isSelected: isSelected, isToday: isToday"))
        #expect(monthGridSource.contains("if isSelected {"))
        #expect(!monthGridSource.contains("if isSelected && !isToday"))
        #expect(!monthGridSource.contains("todayDotSize"))
        #expect(!monthGridSource.contains(".fill(MeowPlannerTheme.blush)\n                            .frame(width: todayDotSize"))
    }

    @Test("month calendar schedule pills show title text without leading icons")
    func monthCalendarSchedulePillsShowTitleTextWithoutLeadingIcons() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)

        #expect(!monthGridSource.contains("Image(systemName: \"calendar\")"))
        #expect(!monthGridSource.contains("Image(systemName: item.kind == .event ? \"calendar\" : \"checkmark.circle\")"))
        #expect(!monthGridSource.contains("plannerItemIconFont"))
        #expect(monthGridSource.contains("private let desktopPlannerItemRowHeight: CGFloat = 20"))
        #expect(monthGridSource.contains("private let desktopMultiDaySegmentHeight: CGFloat = 20"))
        #expect(monthGridSource.contains("return .caption.weight(.semibold)"))
        #expect(monthGridSource.contains("Text(item.title)"))
    }

    @Test("month calendar schedule pills use larger adaptive iOS text")
    func monthCalendarSchedulePillsUseLargerAdaptiveIOSText() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let plannerFontSource = try sourceWindow(
            in: monthGridSource,
            from: "private var plannerItemTextFont",
            length: 280
        )
        let scaleSource = try sourceWindow(
            in: monthGridSource,
            from: "private var plannerItemMinimumScaleFactor",
            length: 220
        )
        let multiDayTitleSource = try sourceWindow(
            in: monthGridSource,
            from: "private func multiDayEventSegmentContent",
            length: 900
        )
        let singleDayTitleSource = try sourceWindow(
            in: monthGridSource,
            from: "private func plannerItemRow",
            length: 900
        )

        #expect(plannerFontSource.contains("return .caption.weight(.semibold)"))
        #expect(plannerFontSource.contains("return .system(size: 8.6, weight: .semibold)"))
        #expect(scaleSource.contains("return 0.84"))
        #expect(!scaleSource.contains("return 0.58"))
        #expect(monthGridSource.contains("private let iosDayCellHorizontalPadding: CGFloat = 2"))
        #expect(monthGridSource.contains("private let iosPlannerItemRowHeight: CGFloat = 18"))
        #expect(monthGridSource.contains("private let iosMultiDaySegmentHeight: CGFloat = 18"))
        #expect(monthGridSource.contains("#if os(iOS)\n        return 2\n        #else\n        return 6"))
        #expect(multiDayTitleSource.contains(".font(plannerItemTextFont)"))
        #expect(singleDayTitleSource.contains(".font(plannerItemTextFont)"))
        #expect(multiDayTitleSource.contains(".truncationMode(.tail)"))
        #expect(singleDayTitleSource.contains(".truncationMode(.tail)"))
        #expect(multiDayTitleSource.contains(".minimumScaleFactor(plannerItemMinimumScaleFactor)"))
        #expect(singleDayTitleSource.contains(".minimumScaleFactor(plannerItemMinimumScaleFactor)"))
        #expect(multiDayTitleSource.contains(".allowsTightening(true)"))
        #expect(singleDayTitleSource.contains(".allowsTightening(true)"))
    }

    @Test("month calendar opens on today and only click selection changes the highlighted day")
    func monthCalendarOpensOnTodayAndOnlyClickSelectionChangesTheHighlightedDay() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let selectSectionSource = try sourceWindow(
            in: rootSource,
            from: "private func selectSidebarSection(_ section: AppSection)",
            length: 420
        )
        let externalRefreshSource = try sourceWindow(
            in: rootSource,
            from: "private func refreshCalendarAfterExternalOpen()",
            length: 240
        )
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
        let setCalendarSelectionSource = try sourceWindow(
            in: calendarHomeSource,
            from: "private func setCalendarSelection(to date: Date)",
            length: 620
        )

        #expect(rootSource.contains("selectSidebarSection(section)"))
        #expect(rootSource.contains("private func selectSidebarSection(_ section: AppSection)"))
        #expect(selectSectionSource.contains("case .calendar:\n            #if os(iOS)\n            selection = section"))
        #expect(selectSectionSource.contains("#else\n            refreshCalendarAfterExternalOpen()"))
        #expect(externalRefreshSource.contains("calendarRenderToken = UUID()"))
        #expect(rootSource.contains("CalendarHomeView("))
        #expect(rootSource.contains(".id(calendarRenderToken)"))
        #expect(monthGridSource.contains("@Binding var displayedMonth: Date"))
        #expect(monthGridSource.contains("@Binding var monthTransitionDirection: Int"))
        #expect(!monthGridSource.contains("@State private var displayedMonth = Date()"))
        #expect(!monthGridSource.contains("@State private var monthTransitionDirection = 1"))
        #expect(monthGridBodySource.contains("resetToToday()"))
        #expect(monthGridBodySource.contains("Label(PlannerCopy.text(.today"))
        #expect(monthGridSource.contains("private func plannerDays(maxVisibleItems: Int) -> [MonthPlannerDay]"))
        #expect(monthGridSource.contains("plannerDays(for: displayedMonth, maxVisibleItems: maxVisibleItems)"))
        #expect(monthGridSource.contains("MonthPlannerGridBuilder.days(\n            for: month"))
        #expect(monthGridSource.contains("calendar.isDate(day.date, inSameDayAs: selectedDate)"))
        #expect(monthGridSource.contains("private func selectDate(_ date: Date)"))
        #expect(monthGridSource.contains("selectedDate = date"))
        #expect(monthGridSource.contains("let targetMonth = monthStart(for: date)"))
        #expect(monthGridSource.contains("displayedMonth = targetMonth"))
        #expect(monthGridSource.contains("private func resetToToday()"))
        #expect(monthGridSource.contains("let today = Date()"))
        #expect(monthGridSource.contains("selectedDate = today"))
        #expect(monthGridSource.contains("let targetMonth = monthStart(for: today)"))
        #expect(monthGridSource.contains("private var displayedMonthAnimation: Animation?"))
        #expect(monthGridSource.contains("#if os(iOS)\n        return nil"))
        #expect(monthGridSource.contains(".animation(displayedMonthAnimation, value: displayedMonth)"))
        #expect(!monthGridSource.contains(".animation(.snappy(duration: 0.22), value: displayedMonth)"))
        #expect(monthGridSource.contains("private func updateDisplayedMonth(_ targetMonth: Date, animated: Bool)"))
        #expect(moveMonthSource.contains("updateDisplayedMonth(targetMonth, animated: true)"))
        #expect(moveMonthSource.contains("withAnimation(.snappy(duration: 0.26))"))
        #expect(setCalendarSelectionSource.contains("withTransaction(calendarSelectionTransaction)"))
        #expect(calendarHomeSource.contains("private var calendarSelectionTransaction: Transaction"))
        #expect(calendarHomeSource.contains("#if os(iOS)\n        transaction.disablesAnimations = true"))
        #expect(!moveMonthSource.contains("selectedDate = calendar.date(byAdding: .month"))
    }

    @Test("macOS month calendar fufu avatar triggers cloud refresh without a visible badge")
    func macOSMonthCalendarFufuAvatarTriggersCloudRefreshWithoutVisibleBadge() throws {
        let root = try packageRoot()
        let rootFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
        let calendarHomeFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift")
        let syncServiceFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Support/FirestoreAppDataSyncService.swift")
        let languageFile = root
            .appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

        let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
        let calendarHomeSource = try String(contentsOf: calendarHomeFile, encoding: .utf8)
        let syncServiceSource = try String(contentsOf: syncServiceFile, encoding: .utf8)
        let languageSource = try String(contentsOf: languageFile, encoding: .utf8)
        let macOSCalendarSource = try sourceWindow(
            in: rootSource,
            from: "#else\n                CalendarHomeView(",
            length: 360
        )
        let iosCalendarSource = try sourceWindow(
            in: rootSource,
            from: "#if os(iOS)\n                CalendarHomeView(",
            length: 260
        )
        let headerSource = try #require(sourceBlock(
            in: calendarHomeSource,
            from: "    private var header: some View {",
            to: "\n    }\n\n    @ViewBuilder"
        ))

        #expect(syncServiceSource.contains("func syncImmediately(for userID: String?"))
        #expect(rootSource.contains("private func refreshCalendarFromCloud()"))
        #expect(rootSource.contains("syncImmediately(for: accountStore.currentProfile?.remoteUserID"))
        #expect(macOSCalendarSource.contains("onCloudRefresh: refreshCalendarFromCloud"))
        #expect(!iosCalendarSource.contains("onCloudRefresh"))
        #expect(calendarHomeSource.contains("private let onCloudRefresh: (() -> Void)?"))
        #expect(headerSource.contains("Button(action: refreshFromCloud)"))
        #expect(headerSource.contains("FuFuAssetImage(size: 58)"))
        #expect(!headerSource.contains("arrow.clockwise.circle.fill"))
        #expect(headerSource.contains(".help(PlannerCopy.text(.refreshCalendarFromCloud"))
        #expect(headerSource.contains(".accessibilityLabel(PlannerCopy.text(.refreshCalendarFromCloud"))
        #expect(languageSource.contains("case refreshCalendarFromCloud"))
        #expect(languageSource.contains(".refreshCalendarFromCloud: \"Sync latest cloud content\""))
        #expect(languageSource.contains(".refreshCalendarFromCloud: \"同步最新云端内容\""))
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

    @Test("month grid schedule titles use adaptive single-line text")
    func monthGridPlannerItemsUseAdaptiveSingleLineText() throws {
        let root = try packageRoot()
        let monthGridFile = root
            .appendingPathComponent("Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift")

        let monthGridSource = try String(contentsOf: monthGridFile, encoding: .utf8)
        let plannerFontSource = try sourceWindow(
            in: monthGridSource,
            from: "private var plannerItemTextFont",
            length: 220
        )
        let multiDayTitleSource = try sourceWindow(
            in: monthGridSource,
            from: "private func multiDayEventSegmentContent",
            length: 1_200
        )
        let singleDayTitleSource = try sourceWindow(
            in: monthGridSource,
            from: "private func plannerItemRow",
            length: 900
        )

        #expect(plannerFontSource.contains("return .system(size: 8.6, weight: .semibold)"))
        #expect(multiDayTitleSource.contains(".font(plannerItemTextFont)"))
        #expect(singleDayTitleSource.contains(".font(plannerItemTextFont)"))
        #expect(multiDayTitleSource.contains(".truncationMode(.tail)"))
        #expect(singleDayTitleSource.contains(".truncationMode(.tail)"))
        #expect(multiDayTitleSource.contains(".minimumScaleFactor(plannerItemMinimumScaleFactor)"))
        #expect(singleDayTitleSource.contains(".minimumScaleFactor(plannerItemMinimumScaleFactor)"))
        #expect(multiDayTitleSource.contains(".allowsTightening(true)"))
        #expect(singleDayTitleSource.contains(".allowsTightening(true)"))
        #expect(!multiDayTitleSource.contains(".opacity(item.isCompleted"))
        #expect(!singleDayTitleSource.contains(".opacity(item.isCompleted"))
        #expect(monthGridSource.contains("private func itemBackgroundOpacity"))
    }

    @Test("iOS app target uses the MeowPlanner AppIcon asset catalog")
    func iosAppTargetUsesMeowPlannerAppIconAssetCatalog() throws {
        let root = try packageRoot()
        let generatorFile = root.appendingPathComponent("script/generate_xcode_project.py")
        let projectFile = root
            .appendingPathComponent("MeowPlanner.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let appIconContentsFile = root
            .appendingPathComponent("Resources/iOSAssets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
            .appendingPathComponent("Contents.json")

        let generatorSource = try String(contentsOf: generatorFile, encoding: .utf8)
        let project = try String(contentsOf: projectFile, encoding: .utf8)
        let appIconContents = sourceIfPresent(appIconContentsFile)

        #expect(FileManager.default.fileExists(atPath: appIconContentsFile.path))
        #expect(appIconContents.contains("\"idiom\" : \"iphone\""))
        #expect(appIconContents.contains("\"idiom\" : \"ipad\""))
        #expect(appIconContents.contains("\"idiom\" : \"ios-marketing\""))
        #expect(appIconContents.contains("\"filename\" : \"AppIcon-1024.png\""))
        #expect(generatorSource.contains("\"Resources/iOSAssets.xcassets\""))
        #expect(generatorSource.contains("\"ASSETCATALOG_COMPILER_APPICON_NAME\": \"AppIcon\""))
        #expect(project.contains("Resources/iOSAssets.xcassets"))
        #expect(project.contains("lastKnownFileType = folder.assetcatalog"))
        #expect(project.contains("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon"))
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

    private func pngDimensions(at url: URL) throws -> CGSizePixels {
        let data = try Data(contentsOf: url)
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        guard data.count >= 24, data.prefix(8) == pngSignature else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let width = Int(data[16]) << 24
            | Int(data[17]) << 16
            | Int(data[18]) << 8
            | Int(data[19])
        let height = Int(data[20]) << 24
            | Int(data[21]) << 16
            | Int(data[22]) << 8
            | Int(data[23])

        return CGSizePixels(width: width, height: height)
    }
}

private struct CGSizePixels: Equatable {
    var width: Int
    var height: Int
}
