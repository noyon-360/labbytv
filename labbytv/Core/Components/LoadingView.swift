import SwiftUI

struct LoadingView: View {
    var message: String?

    var body: some View {
        VStack(spacing: Spacing.m) {
            ProgressView()
                .scaleEffect(1.5)
            if let message {
                Text(message)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView(message: "Loading channels…")
        .background(AppColors.background)
}
