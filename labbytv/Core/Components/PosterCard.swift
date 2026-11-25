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
        VStack(alignment: .leading, spacing: Spacing.xs) {
            RemoteImage(url: imageURL, placeholderSymbol: "film")
                .frame(width: width, height: width * 1.5)
                .overlay(alignment: .bottom) {
                    if let progress, progress > 0 {
                        ProgressBar(value: progress)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
                .focusedArtwork()
            CardCaption(title: title, subtitle: subtitle, width: width)
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
