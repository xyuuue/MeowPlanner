#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT_DIR = ROOT / "MeowPlanner.xcodeproj"


def oid(key: str) -> str:
    return hashlib.sha1(key.encode("utf-8")).hexdigest().upper()[:24]


def q(value: str) -> str:
    if value == "":
        return '""'
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    if "$" not in value and all(ch.isalnum() or ch in "._/-" for ch in value):
        return value
    return f'"{escaped}"'


def list_block(values: list[str], indent: int = 4) -> str:
    prefix = "\t" * indent
    lines = ["("]
    lines.extend(f"{prefix}{value}," for value in values)
    lines.append("\t" * (indent - 1) + ")")
    return "\n".join(lines)


def add_object(objects: dict[str, str], object_id: str, body: str) -> None:
    objects[object_id] = body


def file_type(path: str) -> str:
    if path.endswith(".swift"):
        return "sourcecode.swift"
    if path.endswith(".plist") or path.endswith(".entitlements"):
        return "text.plist.xml"
    if path.endswith(".icns"):
        return "image.icns"
    return "file"


def file_ref(path: str, *, name: str | None = None, explicit: str | None = None, folder: bool = False) -> str:
    return oid(f"file:{path}:{name or ''}:{explicit or ''}:{folder}")


def build_file(target: str, path: str, suffix: str = "") -> str:
    return oid(f"build:{target}:{path}:{suffix}")


def group_id(name: str) -> str:
    return oid(f"group:{name}")


def phase_id(target: str, phase: str) -> str:
    return oid(f"phase:{target}:{phase}")


def config_id(target: str, name: str) -> str:
    return oid(f"config:{target}:{name}")


def config_list_id(target: str) -> str:
    return oid(f"config-list:{target}")


CORE_SOURCES = [
    "Sources/MeowPlannerCore/MeowPlannerCore.swift",
    "Sources/MeowPlannerCore/Models/CourseTimetable.swift",
    "Sources/MeowPlannerCore/Models/FocusSession.swift",
    "Sources/MeowPlannerCore/Models/Habit.swift",
    "Sources/MeowPlannerCore/Models/HabitCheckIn.swift",
    "Sources/MeowPlannerCore/Models/PlannerEvent.swift",
    "Sources/MeowPlannerCore/Models/PlannerPreference.swift",
    "Sources/MeowPlannerCore/Models/TodoGroup.swift",
    "Sources/MeowPlannerCore/Models/TodoItem.swift",
    "Sources/MeowPlannerCore/Services/AccountAuthentication.swift",
    "Sources/MeowPlannerCore/Services/CloudAppDataSync.swift",
    "Sources/MeowPlannerCore/Services/CloudTodoSync.swift",
    "Sources/MeowPlannerCore/Services/ChineseCalendarInfoProvider.swift",
    "Sources/MeowPlannerCore/Services/CourseTimetablePlanner.swift",
    "Sources/MeowPlannerCore/Services/FocusTimerState.swift",
    "Sources/MeowPlannerCore/Services/HabitStreakCalculator.swift",
    "Sources/MeowPlannerCore/Services/NotificationScheduler.swift",
    "Sources/MeowPlannerCore/Services/ReminderPlanner.swift",
    "Sources/MeowPlannerCore/Services/RepeatRule.swift",
    "Sources/MeowPlannerCore/Services/TodoListPlanner.swift",
    "Sources/MeowPlannerCore/Stores/ModelContainerFactory.swift",
    "Sources/MeowPlannerCore/Support/AppLanguage.swift",
    "Sources/MeowPlannerCore/Support/MonthPlannerGridBuilder.swift",
    "Sources/MeowPlannerCore/Support/WeekStartPreference.swift",
    "Sources/MeowPlannerCore/Support/WidgetAppIntents.swift",
    "Sources/MeowPlannerCore/Support/WidgetConstants.swift",
]

APP_SOURCES = [
    "Sources/MeowPlannerApp/App/MeowPlannerApp.swift",
    "Sources/MeowPlannerApp/Support/AccountScopedModelContainerStore.swift",
    "Sources/MeowPlannerApp/Support/AccountSessionStore.swift",
    "Sources/MeowPlannerApp/Support/AppDockIconController.swift",
    "Sources/MeowPlannerApp/Support/AppIconInstaller.swift",
    "Sources/MeowPlannerApp/Support/AppLanguageEnvironment.swift",
    "Sources/MeowPlannerApp/Support/FirebaseAccountAuthenticationClient.swift",
    "Sources/MeowPlannerApp/Support/FirestoreAppDataSyncService.swift",
    "Sources/MeowPlannerApp/Support/AppNavigation.swift",
    "Sources/MeowPlannerApp/Support/MeowPlannerAppIntentsPackage.swift",
    "Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift",
    "Sources/MeowPlannerApp/Support/WidgetConstants.swift",
    "Sources/MeowPlannerApp/Support/WidgetTimelineSyncService.swift",
    "Sources/MeowPlannerApp/Views/Account/AccountAuthenticationModalView.swift",
    "Sources/MeowPlannerApp/Views/Account/AccountGatedRootView.swift",
    "Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift",
    "Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift",
    "Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift",
    "Sources/MeowPlannerApp/Views/Components/FuFuEmptyStateView.swift",
    "Sources/MeowPlannerApp/Views/Focus/FocusView.swift",
    "Sources/MeowPlannerApp/Views/Habits/HabitsView.swift",
    "Sources/MeowPlannerApp/Views/MenuBar/MeowPlannerMenuBarView.swift",
    "Sources/MeowPlannerApp/Views/RootView.swift",
    "Sources/MeowPlannerApp/Views/Settings/AccountSettingsSection.swift",
    "Sources/MeowPlannerApp/Views/Settings/SettingsView.swift",
    "Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift",
    "Sources/MeowPlannerApp/Views/Todos/TodoEditorView.swift",
    "Sources/MeowPlannerApp/Views/Todos/TodoHomeView.swift",
]

WIDGET_SOURCES = [
    "Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift",
    "Sources/MeowPlannerWidget/MeowPlannerWidgetBundle.swift",
    "Sources/MeowPlannerWidget/MeowPlannerWidgetIntentsPackage.swift",
    "Sources/MeowPlannerWidget/MeowPlannerWidgetModule.swift",
    "Sources/MeowPlannerWidget/WidgetConstants.swift",
]

CONFIG_FILES = [
    "Config/GoogleService-Info.plist",
    "Config/MeowPlanner-Info.plist",
    "Config/MeowPlanner.entitlements",
    "Config/MeowPlannerWidget-Info.plist",
    "Config/MeowPlannerWidget.entitlements",
]

RESOURCE_FILES = [
    "Resources/AppIcon/AppIcon.icns",
]

APP_RESOURCE_FILES = RESOURCE_FILES + [
    "Config/GoogleService-Info.plist",
]

RESOURCE_FOLDERS = [
    "Resources/AppIcon",
    "Resources/FuFu",
]


def build_settings(settings: dict[str, str | list[str]]) -> str:
    lines: list[str] = ["\t\t\tbuildSettings = {"]
    for key in sorted(settings):
        value = settings[key]
        if isinstance(value, list):
            lines.append(f"\t\t\t\t{key} = {list_block([q(v) for v in value], indent=5)};")
        else:
            lines.append(f"\t\t\t\t{key} = {q(value)};")
    lines.append("\t\t\t};")
    return "\n".join(lines)


def main() -> None:
    objects: dict[str, str] = {}

    project = oid("project")
    main_group = group_id("main")
    products_group = group_id("products")
    sources_group = group_id("sources")
    core_group = group_id("core")
    app_group = group_id("app")
    widget_group = group_id("widget")
    config_group = group_id("config")
    resources_group = group_id("resources")

    app_target = oid("target:MeowPlanner")
    core_target = oid("target:MeowPlannerCore")
    widget_target = oid("target:MeowPlannerWidgetExtension")

    app_product = oid("product:MeowPlanner.app")
    core_product = oid("product:MeowPlannerCore.framework")
    widget_product = oid("product:MeowPlannerWidgetExtension.appex")

    all_source_files = CORE_SOURCES + APP_SOURCES + WIDGET_SOURCES
    for path in all_source_files + CONFIG_FILES + RESOURCE_FILES:
        add_object(
            objects,
            file_ref(path),
            f"\t\tisa = PBXFileReference;\n"
            f"\t\tlastKnownFileType = {file_type(path)};\n"
            f"\t\tpath = {q(path)};\n"
            f"\t\tsourceTree = \"<group>\";",
        )

    for path in RESOURCE_FOLDERS:
        add_object(
            objects,
            file_ref(path, folder=True),
            f"\t\tisa = PBXFileReference;\n"
            f"\t\tlastKnownFileType = folder;\n"
            f"\t\tpath = {q(path)};\n"
            f"\t\tsourceTree = \"<group>\";",
        )

    add_object(
        objects,
        app_product,
        "\t\tisa = PBXFileReference;\n"
        "\t\texplicitFileType = wrapper.application;\n"
        "\t\tincludeInIndex = 0;\n"
        "\t\tpath = MeowPlanner.app;\n"
        "\t\tsourceTree = BUILT_PRODUCTS_DIR;",
    )
    add_object(
        objects,
        core_product,
        "\t\tisa = PBXFileReference;\n"
        "\t\texplicitFileType = wrapper.framework;\n"
        "\t\tincludeInIndex = 0;\n"
        "\t\tpath = MeowPlannerCore.framework;\n"
        "\t\tsourceTree = BUILT_PRODUCTS_DIR;",
    )
    add_object(
        objects,
        widget_product,
        "\t\tisa = PBXFileReference;\n"
        "\t\texplicitFileType = wrapper.app-extension;\n"
        "\t\tincludeInIndex = 0;\n"
        "\t\tpath = MeowPlannerWidgetExtension.appex;\n"
        "\t\tsourceTree = BUILT_PRODUCTS_DIR;",
    )

    for target, sources in [
        ("MeowPlannerCore", CORE_SOURCES),
        ("MeowPlanner", APP_SOURCES),
        ("MeowPlannerWidgetExtension", WIDGET_SOURCES),
    ]:
        for path in sources:
            add_object(
                objects,
                build_file(target, path),
                f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {file_ref(path)};",
            )

    for path in APP_RESOURCE_FILES + RESOURCE_FOLDERS:
        add_object(
            objects,
            build_file("MeowPlanner", path),
            f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {file_ref(path, folder=path in RESOURCE_FOLDERS)};",
        )

    core_app_framework = build_file("MeowPlanner", "MeowPlannerCore.framework", "framework")
    core_app_embed = build_file("MeowPlanner", "MeowPlannerCore.framework", "embed")
    core_widget_framework = build_file("MeowPlannerWidgetExtension", "MeowPlannerCore.framework", "framework")
    core_widget_embed = build_file("MeowPlannerWidgetExtension", "MeowPlannerCore.framework", "embed")
    widget_embed = build_file("MeowPlanner", "MeowPlannerWidgetExtension.appex", "embed")
    firebase_package = oid("package:firebase-ios-sdk")
    firebase_core_product = oid("product:FirebaseCore")
    firebase_auth_product = oid("product:FirebaseAuth")
    firebase_firestore_product = oid("product:FirebaseFirestore")
    firebase_core_build = build_file("MeowPlanner", "FirebaseCore", "package")
    firebase_auth_build = build_file("MeowPlanner", "FirebaseAuth", "package")
    firebase_firestore_build = build_file("MeowPlanner", "FirebaseFirestore", "package")

    add_object(objects, core_app_framework, f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {core_product};")
    add_object(
        objects,
        core_app_embed,
        f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {core_product};\n\t\tsettings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }};",
    )
    add_object(objects, core_widget_framework, f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {core_product};")
    add_object(
        objects,
        core_widget_embed,
        f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {core_product};\n\t\tsettings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }};",
    )
    add_object(
        objects,
        widget_embed,
        f"\t\tisa = PBXBuildFile;\n\t\tfileRef = {widget_product};\n\t\tsettings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }};",
    )
    add_object(
        objects,
        firebase_core_build,
        f"\t\tisa = PBXBuildFile;\n\t\tproductRef = {firebase_core_product};",
    )
    add_object(
        objects,
        firebase_auth_build,
        f"\t\tisa = PBXBuildFile;\n\t\tproductRef = {firebase_auth_product};",
    )
    add_object(
        objects,
        firebase_firestore_build,
        f"\t\tisa = PBXBuildFile;\n\t\tproductRef = {firebase_firestore_product};",
    )

    def sources_phase(target: str, sources: list[str]) -> None:
        add_object(
            objects,
            phase_id(target, "Sources"),
            "\t\tisa = PBXSourcesBuildPhase;\n"
            "\t\tbuildActionMask = 2147483647;\n"
            f"\t\tfiles = {list_block([build_file(target, path) for path in sources], indent=3)};\n"
            "\t\trunOnlyForDeploymentPostprocessing = 0;",
        )

    def frameworks_phase(target: str, files: list[str]) -> None:
        add_object(
            objects,
            phase_id(target, "Frameworks"),
            "\t\tisa = PBXFrameworksBuildPhase;\n"
            "\t\tbuildActionMask = 2147483647;\n"
            f"\t\tfiles = {list_block(files, indent=3)};\n"
            "\t\trunOnlyForDeploymentPostprocessing = 0;",
        )

    def resources_phase(target: str, files: list[str]) -> None:
        add_object(
            objects,
            phase_id(target, "Resources"),
            "\t\tisa = PBXResourcesBuildPhase;\n"
            "\t\tbuildActionMask = 2147483647;\n"
            f"\t\tfiles = {list_block(files, indent=3)};\n"
            "\t\trunOnlyForDeploymentPostprocessing = 0;",
        )

    def copy_phase(target: str, name: str, dst: str, files: list[str]) -> str:
        phase = phase_id(target, name)
        add_object(
            objects,
            phase,
            "\t\tisa = PBXCopyFilesBuildPhase;\n"
            "\t\tbuildActionMask = 2147483647;\n"
            f"\t\tdstSubfolderSpec = {dst};\n"
            f"\t\tfiles = {list_block(files, indent=3)};\n"
            f"\t\tname = {q(name)};\n"
            "\t\trunOnlyForDeploymentPostprocessing = 0;",
        )
        return phase

    sources_phase("MeowPlannerCore", CORE_SOURCES)
    frameworks_phase("MeowPlannerCore", [])
    resources_phase("MeowPlannerCore", [])

    sources_phase("MeowPlanner", APP_SOURCES)
    frameworks_phase("MeowPlanner", [core_app_framework, firebase_core_build, firebase_auth_build, firebase_firestore_build])
    resources_phase("MeowPlanner", [build_file("MeowPlanner", path) for path in APP_RESOURCE_FILES + RESOURCE_FOLDERS])
    app_embed_frameworks = copy_phase("MeowPlanner", "Embed Frameworks", "10", [core_app_embed])
    app_embed_extensions = copy_phase("MeowPlanner", "Embed App Extensions", "13", [widget_embed])

    sources_phase("MeowPlannerWidgetExtension", WIDGET_SOURCES)
    frameworks_phase("MeowPlannerWidgetExtension", [core_widget_framework])
    resources_phase("MeowPlannerWidgetExtension", [])
    widget_embed_frameworks = copy_phase("MeowPlannerWidgetExtension", "Embed Frameworks", "10", [core_widget_embed])

    core_proxy_for_app = oid("proxy:app-core")
    widget_proxy_for_app = oid("proxy:app-widget")
    core_proxy_for_widget = oid("proxy:widget-core")
    app_core_dependency = oid("dependency:app-core")
    app_widget_dependency = oid("dependency:app-widget")
    widget_core_dependency = oid("dependency:widget-core")

    for proxy, remote, remote_info in [
        (core_proxy_for_app, core_target, "MeowPlannerCore"),
        (widget_proxy_for_app, widget_target, "MeowPlannerWidgetExtension"),
        (core_proxy_for_widget, core_target, "MeowPlannerCore"),
    ]:
        add_object(
            objects,
            proxy,
            "\t\tisa = PBXContainerItemProxy;\n"
            f"\t\tcontainerPortal = {project};\n"
            "\t\tproxyType = 1;\n"
            f"\t\tremoteGlobalIDString = {remote};\n"
            f"\t\tremoteInfo = {remote_info};",
        )

    for dependency, target, proxy in [
        (app_core_dependency, core_target, core_proxy_for_app),
        (app_widget_dependency, widget_target, widget_proxy_for_app),
        (widget_core_dependency, core_target, core_proxy_for_widget),
    ]:
        add_object(
            objects,
            dependency,
            "\t\tisa = PBXTargetDependency;\n"
            f"\t\ttarget = {target};\n"
            f"\t\ttargetProxy = {proxy};",
        )

    target_data = [
        (
            core_target,
            "MeowPlannerCore",
            core_product,
            "com.apple.product-type.framework",
            [phase_id("MeowPlannerCore", "Sources"), phase_id("MeowPlannerCore", "Frameworks"), phase_id("MeowPlannerCore", "Resources")],
            [],
        ),
        (
            widget_target,
            "MeowPlannerWidgetExtension",
            widget_product,
            "com.apple.product-type.app-extension",
            [
                phase_id("MeowPlannerWidgetExtension", "Sources"),
                phase_id("MeowPlannerWidgetExtension", "Frameworks"),
                phase_id("MeowPlannerWidgetExtension", "Resources"),
                widget_embed_frameworks,
            ],
            [widget_core_dependency],
        ),
        (
            app_target,
            "MeowPlanner",
            app_product,
            "com.apple.product-type.application",
            [
                phase_id("MeowPlanner", "Sources"),
                phase_id("MeowPlanner", "Frameworks"),
                phase_id("MeowPlanner", "Resources"),
                app_embed_frameworks,
                app_embed_extensions,
            ],
            [app_core_dependency, app_widget_dependency],
        ),
    ]

    for target_id, name, product, product_type, phases, dependencies in target_data:
        package_product_dependencies = [firebase_core_product, firebase_auth_product, firebase_firestore_product] if name == "MeowPlanner" else []
        add_object(
            objects,
            target_id,
            "\t\tisa = PBXNativeTarget;\n"
            f"\t\tbuildConfigurationList = {config_list_id(name)};\n"
            f"\t\tbuildPhases = {list_block(phases, indent=3)};\n"
            "\t\tbuildRules = (\n\t\t);\n"
            f"\t\tdependencies = {list_block(dependencies, indent=3)};\n"
            f"\t\tname = {name};\n"
            f"\t\tpackageProductDependencies = {list_block(package_product_dependencies, indent=3)};\n"
            f"\t\tproductName = {name};\n"
            f"\t\tproductReference = {product};\n"
            f"\t\tproductType = \"{product_type}\";",
        )

    add_object(
        objects,
        core_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([file_ref(path) for path in CORE_SOURCES], indent=3)};\n"
        "\t\tname = MeowPlannerCore;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        app_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([file_ref(path) for path in APP_SOURCES], indent=3)};\n"
        "\t\tname = MeowPlannerApp;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        widget_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([file_ref(path) for path in WIDGET_SOURCES], indent=3)};\n"
        "\t\tname = MeowPlannerWidget;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        sources_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([core_group, app_group, widget_group], indent=3)};\n"
        "\t\tname = Sources;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        config_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([file_ref(path) for path in CONFIG_FILES], indent=3)};\n"
        "\t\tname = Config;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        resources_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([file_ref(path) for path in RESOURCE_FILES] + [file_ref(path, folder=True) for path in RESOURCE_FOLDERS], indent=3)};\n"
        "\t\tname = Resources;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        products_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([app_product, core_product, widget_product], indent=3)};\n"
        "\t\tname = Products;\n"
        "\t\tsourceTree = \"<group>\";",
    )
    add_object(
        objects,
        main_group,
        "\t\tisa = PBXGroup;\n"
        f"\t\tchildren = {list_block([sources_group, resources_group, config_group, products_group], indent=3)};\n"
        "\t\tsourceTree = \"<group>\";",
    )

    common_project_debug = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_TESTABILITY": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": "DEBUG=1 $(inherited)",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "MACOSX_DEPLOYMENT_TARGET": "14.0",
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "MTL_FAST_MATH": "YES",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "macosx",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "6.0",
    }
    common_project_release = dict(common_project_debug)
    common_project_release.update(
        {
            "COPY_PHASE_STRIP": "NO",
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
            "ENABLE_NS_ASSERTIONS": "NO",
            "ENABLE_TESTABILITY": "NO",
            "GCC_OPTIMIZATION_LEVEL": "s",
            "MTL_ENABLE_DEBUG_INFO": "NO",
            "ONLY_ACTIVE_ARCH": "NO",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited)",
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        }
    )

    base_target = {
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_ASSET_PATHS": "",
        "DEVELOPMENT_TEAM": "",
        "ENABLE_PREVIEWS": "YES",
        "MACOSX_DEPLOYMENT_TARGET": "14.0",
        "SDKROOT": "macosx",
        "SUPPORTED_PLATFORMS": "macosx",
        "SWIFT_VERSION": "6.0",
    }
    core_settings = dict(base_target)
    core_settings.update(
        {
            "GENERATE_INFOPLIST_FILE": "YES",
            "LD_DYLIB_INSTALL_NAME": "@rpath/$(EXECUTABLE_PATH)",
            "MACH_O_TYPE": "mh_dylib",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.yuelingqiu.MeowPlannerCore",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SKIP_INSTALL": "YES",
        }
    )
    app_settings = dict(base_target)
    app_settings.update(
        {
            "CODE_SIGN_ENTITLEMENTS": "Config/MeowPlanner.entitlements",
            "COMBINE_HIDPI_IMAGES": "YES",
            "ENABLE_HARDENED_RUNTIME": "YES",
            "INFOPLIST_FILE": "Config/MeowPlanner-Info.plist",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"],
            "PRODUCT_BUNDLE_IDENTIFIER": "com.yuelingqiu.MeowPlanner",
            "PRODUCT_NAME": "$(TARGET_NAME)",
        }
    )
    widget_settings = dict(base_target)
    widget_settings.update(
        {
            "APPLICATION_EXTENSION_API_ONLY": "YES",
            "CODE_SIGN_ENTITLEMENTS": "Config/MeowPlannerWidget.entitlements",
            "COMBINE_HIDPI_IMAGES": "YES",
            "INFOPLIST_FILE": "Config/MeowPlannerWidget-Info.plist",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks", "@executable_path/../../../../Frameworks"],
            "PRODUCT_BUNDLE_IDENTIFIER": "com.yuelingqiu.MeowPlanner.MeowPlannerWidget",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SKIP_INSTALL": "YES",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) MEOWPLANNER_WIDGET_EXTENSION",
        }
    )

    config_sets = {
        "Project": (common_project_debug, common_project_release),
        "MeowPlannerCore": (core_settings, core_settings),
        "MeowPlannerWidgetExtension": (widget_settings, widget_settings),
        "MeowPlanner": (app_settings, app_settings),
    }

    for target_name, (debug_settings, release_settings) in config_sets.items():
        for config_name, settings in [("Debug", debug_settings), ("Release", release_settings)]:
            add_object(
                objects,
                config_id(target_name, config_name),
                "\t\tisa = XCBuildConfiguration;\n"
                f"\t\tname = {config_name};\n"
                f"{build_settings(settings)}",
            )
        add_object(
            objects,
            config_list_id(target_name),
            "\t\tisa = XCConfigurationList;\n"
            f"\t\tbuildConfigurations = {list_block([config_id(target_name, 'Debug'), config_id(target_name, 'Release')], indent=3)};\n"
            "\t\tdefaultConfigurationIsVisible = 0;\n"
            "\t\tdefaultConfigurationName = Release;",
        )

    add_object(
        objects,
        firebase_package,
        "\t\tisa = XCRemoteSwiftPackageReference;\n"
        "\t\trepositoryURL = https://github.com/firebase/firebase-ios-sdk.git;\n"
        "\t\trequirement = {\n"
        "\t\t\tkind = upToNextMajorVersion;\n"
        "\t\t\tminimumVersion = 12.14.0;\n"
        "\t\t};",
    )
    for product_id, product_name in [
        (firebase_core_product, "FirebaseCore"),
        (firebase_auth_product, "FirebaseAuth"),
        (firebase_firestore_product, "FirebaseFirestore"),
    ]:
        add_object(
            objects,
            product_id,
            "\t\tisa = XCSwiftPackageProductDependency;\n"
            f"\t\tpackage = {firebase_package};\n"
            f"\t\tproductName = {product_name};",
        )

    add_object(
        objects,
        project,
        "\t\tisa = PBXProject;\n"
        "\t\tattributes = {\n"
        "\t\t\tBuildIndependentTargetsInParallel = 1;\n"
        "\t\t\tLastSwiftUpdateCheck = 2600;\n"
        "\t\t\tLastUpgradeCheck = 2600;\n"
        "\t\t\tORGANIZATIONNAME = yuelingqiu;\n"
        "\t\t\tTargetAttributes = {\n"
        f"\t\t\t\t{app_target} = {{CreatedOnToolsVersion = 26.5; ProvisioningStyle = Automatic; }};\n"
        f"\t\t\t\t{core_target} = {{CreatedOnToolsVersion = 26.5; }};\n"
        f"\t\t\t\t{widget_target} = {{CreatedOnToolsVersion = 26.5; ProvisioningStyle = Automatic; }};\n"
        "\t\t\t};\n"
        "\t\t};\n"
        f"\t\tbuildConfigurationList = {config_list_id('Project')};\n"
        "\t\tcompatibilityVersion = \"Xcode 14.0\";\n"
        "\t\tdevelopmentRegion = en;\n"
        "\t\thasScannedForEncodings = 0;\n"
        "\t\tknownRegions = (\n\t\t\ten,\n\t\t\tBase,\n\t\t);\n"
        f"\t\tmainGroup = {main_group};\n"
        f"\t\tpackageReferences = {list_block([firebase_package], indent=3)};\n"
        f"\t\tproductRefGroup = {products_group};\n"
        "\t\tprojectDirPath = \"\";\n"
        "\t\tprojectRoot = \"\";\n"
        f"\t\ttargets = {list_block([app_target, core_target, widget_target], indent=3)};",
    )

    pbxproj = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
    ]
    for object_id in sorted(objects):
        pbxproj.append(f"\n\t{object_id} = {{")
        pbxproj.append(objects[object_id])
        pbxproj.append("\t};")
    pbxproj.extend(
        [
            "\t};",
            f"\trootObject = {project};",
            "}",
            "",
        ]
    )

    PROJECT_DIR.mkdir(exist_ok=True)
    (PROJECT_DIR / "project.pbxproj").write_text("\n".join(pbxproj), encoding="utf-8")

    workspace = PROJECT_DIR / "project.xcworkspace"
    workspace.mkdir(exist_ok=True)
    (workspace / "contents.xcworkspacedata").write_text(
        """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
""",
        encoding="utf-8",
    )

    scheme_dir = PROJECT_DIR / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "MeowPlanner.xcscheme").write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target}"
               BuildableName = "MeowPlanner.app"
               BlueprintName = "MeowPlanner"
               ReferencedContainer = "container:MeowPlanner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "MeowPlanner.app"
            BlueprintName = "MeowPlanner"
            ReferencedContainer = "container:MeowPlanner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "MeowPlanner.app"
            BlueprintName = "MeowPlanner"
            ReferencedContainer = "container:MeowPlanner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
""",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
