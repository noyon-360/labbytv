import SwiftUI

/// Intro copy at the top of the login page. Client-approved wording, and it
/// tells App Review that LABBY supplies no content (users bring their own
/// provider's playlist), so keep it word for word with Flutter
/// `LoginWelcomeIntro`.
struct LoginWelcomeIntro: View {
    static let title = "Welcome to LABBY TV"
    static let body = "To get started, create a free LABBY TV account. Once registered, you can sign in and add your IPTV provider’s playlist to start watching your content."
    static let signInHint = "Already have an account? Simply sign in to continue."

    var body: some View {
        VStack(spacing: Spacing.s) {
            Text(Self.title)
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text(Self.body)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Text(Self.signInHint)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 1100)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LoginWelcomeIntro()
        .padding()
        .background(AppColors.background)
}
