import SwiftUI

/// 2:3 poster with the title underneath. Used for movies and series.
/// Wrap it in a `Button` or `NavigationLink(value:)` with `CardButtonStyle`.
struct PosterCard: View {
    let title: String
    let imageURL: URL?
    var subtitle: String?
    var progress: Double?
    var width: CGFloat = Spacing.posterWidth

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            RemoteImage(url: imageURL, placeholderSymbol: "film")
                .frame(width: width, height: width * 1.5)
                .overlay(alignment: .bottom) {
                    if let progress, progress > 0 {
                        ProgressBar(value: progress)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: Spacing.gridSpacing) {
        Button {} label: { PosterCard(title: MockData.movies[0].title, imageURL: nil, subtitle: "2024") }
        Button {} label: { PosterCard(title: MockData.movies[1].title, imageURL: nil, progress: 0.4) }
    }
    .buttonStyle(CardButtonStyle())
    .padding(Spacing.xl)
    .background(AppColors.background)
}
#endif
