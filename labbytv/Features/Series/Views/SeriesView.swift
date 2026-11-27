import SwiftUI

struct SeriesView: View {
    let viewModel: CatalogViewModel<Series>

    var body: some View {
        CatalogGridView(viewModel: viewModel, columns: 6, emptySymbol: "tv.and.mediabox") { series in
            NavigationLink(value: AppRoute.series(series)) {
                PosterCard(
                    title: series.title,
                    imageURL: series.imageURL,
                    subtitle: viewModel.categoryName(for: series.categoryId) ?? "Series",
                    badge: RatingBadge.text(series.rating5Based)
                )
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SeriesView(viewModel: CatalogViewModel(type: .series, repository: MockCatalogRepository()))
            .appRouteDestinations()
    }
    .environment(AppEnvironment.preview())
}
#endif
