import SwiftUI

struct SeriesView: View {
    let viewModel: CatalogViewModel<Series>

    var body: some View {
        CatalogGridView(viewModel: viewModel, columns: 6, emptySymbol: "tv.and.mediabox") { series in
            NavigationLink(value: AppRoute.series(series)) {
                PosterCard(title: series.title, imageURL: series.imageURL, subtitle: series.releaseDate.prefix(4).isEmpty ? nil : String(series.releaseDate.prefix(4)))
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
