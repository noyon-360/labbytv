import SwiftUI

struct MoviesView: View {
    let viewModel: CatalogViewModel<Movie>

    var body: some View {
        CatalogGridView(viewModel: viewModel, columns: 6, emptySymbol: "film") { movie in
            NavigationLink(value: AppRoute.movie(movie)) {
                PosterCard(title: movie.title, imageURL: movie.imageURL, subtitle: movie.rating5Based > 0 ? "★ \(String(format: "%.1f", movie.rating5Based))" : nil)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MoviesView(viewModel: CatalogViewModel(type: .movies, repository: MockCatalogRepository()))
            .appRouteDestinations()
    }
    .environment(AppEnvironment.preview())
}
#endif
