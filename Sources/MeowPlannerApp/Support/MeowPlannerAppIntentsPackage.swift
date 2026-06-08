import AppIntents
import MeowPlannerCore

@available(iOS 17.0, macOS 14.0, *)
struct MeowPlannerAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [MeowPlannerCoreAppIntentsPackage.self]
    }
}
