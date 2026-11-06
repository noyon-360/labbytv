import SwiftUI

struct PlaylistPickerView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlaylistPickerViewModel
    @State private var isAdding = false
    /// True when pushed from Profile: picking a playlist goes back.
    var dismissOnSelect = false

    init(viewModel: PlaylistPickerViewModel, dismissOnSelect: Bool = false) {
        _viewModel = State(initialValue: viewModel)
        self.dismissOnSelect = dismissOnSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("Choose a Playlist")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)

            content
        }
        .padding(.vertical, Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.background)
        .task { await viewModel.load() }
        .sheet(isPresented: $isAdding) {
            AddPlaylistView(viewModel: AddPlaylistViewModel(repository: environment.playlistRepository)) {
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.playlists.isEmpty {
            LoadingView(message: "Loading your playlists…")
        } else if let message = viewModel.errorMessage {
            ErrorView(message: message, retry: { Task { await viewModel.load() } }, secondaryTitle: "Sign Out") {
                Task { await environment.signOut() }
            }
        } else if viewModel.playlists.isEmpty {
            VStack(spacing: Spacing.l) {
                EmptyStateView(symbol: "list.bullet.rectangle", title: "No playlists yet", message: "Add your IPTV provider's Xtream Codes login to start watching.")
                    .frame(maxHeight: 400)
                HStack(spacing: Spacing.l) {
                    Button("Add Playlist") { isAdding = true }
                    Button("Sign Out") { Task { await environment.signOut() } }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    ForEach(viewModel.playlists) { playlist in
                        PlaylistRow(playlist: playlist, isActive: playlist.id == viewModel.activePlaylistID) {
                            viewModel.select(playlist)
                            if dismissOnSelect { dismiss() }
                        }
                    }
                    Button {
                        isAdding = true
                    } label: {
                        Label("Add Playlist", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, Spacing.m)
                }
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.m)
            }
            .scrollClipDisabled()
        }
    }
}

private struct PlaylistRow: View {
    let playlist: Playlist
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: "play.tv")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 80)
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name.isEmpty ? "Untitled playlist" : playlist.name)
                        .font(AppFonts.headline)
                    // Host only: the full URL can carry credentials on some providers.
                    Text(URL(string: playlist.url)?.host() ?? "")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.success)
                }
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(Spacing.m)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        }
        .buttonStyle(CardButtonStyle())
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview(playlist: false)
    PlaylistPickerView(viewModel: PlaylistPickerViewModel(repository: MockPlaylistRepository(), session: environment.session, autoSelectSingle: false))
        .environment(environment)
}
#endif
