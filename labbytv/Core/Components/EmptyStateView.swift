import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    var message: String?

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(symbol: "tv", title: "No channels", message: "This category is empty.")
        .background(AppColors.background)
}
