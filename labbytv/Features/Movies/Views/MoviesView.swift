import SwiftUI

struct MoviesView: View {
    let viewModel: CatalogViewModel<Movie>

    var body: some View {
        CatalogGridView(viewModel: viewModel, columns: 6, emptySymbol: "film") { movie in
            NavigationLink(value: AppRoute.movie(movie)) {
                PosterCard(
                    title: movie.title,
                    imageURL: movie.imageURL,
                    // Client (Android TV V1): show which category a title is in.
                    subtitle: viewModel.categoryName(for: movie.categoryId) ?? "Movie",
                    badge: RatingBadge.text(movie.rating5Based)
                )
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
