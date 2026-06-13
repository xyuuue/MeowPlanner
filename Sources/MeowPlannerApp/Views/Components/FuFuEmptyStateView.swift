import SwiftUI

struct FuFuEmptyStateView: View {
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            FuFuAssetImage(size: 96)

            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .fufuControlTint()
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
    }
}
