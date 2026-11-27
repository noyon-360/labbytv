import SwiftUI

/// "Add to My List" / "On My List" beside Play on a detail page.
struct MyListButton: View {
    let viewModel: MyListToggleViewModel
    let title: String
    let thumbnail: String

    var body: some View {
        if viewModel.isKnown {
            Button {
                Task { await viewModel.toggle(title: title, thumbnail: thumbnail) }
            } label: {
                Label(viewModel.isSaved ? "On My List" : "My List", systemImage: viewModel.isSaved ? "checkmark" : "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel(viewModel.isSaved ? "Remove from My List" : "Add to My List")
        }
    }
}

#if DEBUG
#Preview {
    let model = MyListToggleViewModel(myList: MyList(repository: MockWatchLaterRepository()), videoType: "movie", videoID: "105")
    MyListButton(viewModel: model, title: "Harbor Lights 5", thumbnail: "")
        .task { await model.load() }
        .padding(Spacing.xl)
        .background(AppColors.background)
}
#endif
