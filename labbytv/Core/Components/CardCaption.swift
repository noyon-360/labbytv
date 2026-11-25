import SwiftUI

/// Title (and optional subtitle) under a poster or channel tile. When the
/// card is focused it turns dark on a white panel, like the client's
/// reference app, so the selection is obvious from the sofa.
struct CardCaption: View {
    let title: String
    var subtitle: String?
    var titleLines = 2
    let width: CGFloat
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundStyle(isFocused ? AppColors.background : AppColors.textPrimary)
                .lineLimit(titleLines, reservesSpace: titleLines > 1)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(isFocused ? AppColors.surfaceRaised : AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xs)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isFocused ? AppColors.textPrimary : .clear)
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}
