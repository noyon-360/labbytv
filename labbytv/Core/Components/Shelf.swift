import SwiftUI

/// Horizontal row with a title, like the Apple TV app's shelves.
struct Shelf<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: Spacing.gridSpacing) {
                    content()
                }
                .padding(.vertical, Spacing.m)
            }
            .scrollClipDisabled()
        }
        .focusSection()
    }
}

#if DEBUG
#Preview {
    Shelf(title: "Popular Movies") {
        ForEach(MockData.movies) { movie in
            Button {} label: { PosterCard(title: movie.title, imageURL: nil) }
                .buttonStyle(CardButtonStyle())
        }
    }
    .padding(Spacing.xl)
    .background(AppColors.background)
}
#endif
