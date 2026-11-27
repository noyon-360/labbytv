import SwiftUI

/// "FHD", "4K"… in an outlined box, like a TV's picture-info badge.
struct ResolutionBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFonts.caption.weight(.bold))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(AppColors.textPrimary.opacity(0.8), lineWidth: 2))
            .accessibilityLabel("Resolution \(text)")
    }
}

#if DEBUG
#Preview {
    HStack { ResolutionBadge(text: "FHD"); ResolutionBadge(text: "4K") }
        .padding(Spacing.xl)
        .background(AppColors.background)
}
#endif
