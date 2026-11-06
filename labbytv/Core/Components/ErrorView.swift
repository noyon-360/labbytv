import SwiftUI

/// Message + focusable Retry, so no screen is a dead end.
struct ErrorView: View {
    let message: String
    let retry: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.accent)
            Text(message)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1000)
            HStack(spacing: Spacing.l) {
                Button("Retry", action: retry)
                    .buttonStyle(SecondaryButtonStyle())
                    .prefersDefaultFocus(true, in: namespace)
                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .focusScope(namespace)
        .focusSection()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @Namespace private var namespace
}

#Preview {
    ErrorView(message: "No internet connection.", retry: {})
        .background(AppColors.background)
}
