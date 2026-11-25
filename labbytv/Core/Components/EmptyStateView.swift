import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    var message: String?
    /// A focusable way out. Screens pushed onto a stack need one: with
    /// nothing focusable, tvOS sends Back to the system and the app closes.
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: symbol)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.textSecondary)
            Text(title)
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
            if let message {
                Text(message)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 1000)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, Spacing.m)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(symbol: "tv", title: "No channels", message: "This category is empty.")
        .background(AppColors.background)
}
