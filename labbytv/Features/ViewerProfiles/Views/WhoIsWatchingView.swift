import SwiftUI

/// "Who's Watching": pick a profile, add one, or manage them. Shown at app
/// start when the account has several profiles, and from Profile → Switch
/// Profile.
struct WhoIsWatchingView: View {
    @State private var viewModel: WhoIsWatchingViewModel
    @State private var editing: EditTarget?
    @FocusState private var focused: Tile?
    @State private var pendingFocus: Tile?
    @State private var didSetInitialFocus = false

    private enum Tile: Hashable {
        case profile(String)
        case add
        case manage
    }

    /// The Add tile pushes a new profile, a tile in manage mode edits it.
    private struct EditTarget: Hashable, Identifiable {
        let profile: ViewerProfile?
        var id: String { profile?.id ?? "new" }
    }

    init(viewModel: WhoIsWatchingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            Text(viewModel.title)
                .font(AppFonts.largeTitle)
                .foregroundStyle(AppColors.textPrimary)

            // Both rows span the full width as focus sections, so Up/Down
            // moves between them from any tile (the engine otherwise only
            // looks straight up or down).
            tiles
                .frame(maxWidth: .infinity)
                .focusSection()

            Button(viewModel.isManaging ? "Done" : "Manage Profiles") {
                viewModel.isManaging.toggle()
            }
            .buttonStyle(SecondaryButtonStyle())
            .focused($focused, equals: .manage)
            .frame(maxWidth: .infinity)
            .focusSection()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .defaultFocus($focused, viewModel.initialFocusID.map(Tile.profile) ?? .add)
        .onExitCommand(perform: viewModel.backAction)
        .navigationDestination(item: $editing) { target in
            EditViewerProfileView(viewModel: EditViewerProfileViewModel(profile: target.profile, store: viewModel.store))
        }
        .onChange(of: editing) { old, new in
            // Back from Add / Edit: land on the tile that was changed, or on
            // the new profile (it's added at the end).
            guard old != nil, new == nil else { return }
            if let id = old?.profile?.id, viewModel.profiles.contains(where: { $0.id == id }) {
                pendingFocus = .profile(id)
            } else {
                pendingFocus = viewModel.profiles.last.map { .profile($0.id) }
            }
        }
        .onAppear {
            if let target = pendingFocus {
                pendingFocus = nil
                // tvOS puts focus back on the tile that opened the pushed
                // screen once the pop finishes; move it after that.
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    focused = target
                }
            } else if !didSetInitialFocus, let id = viewModel.initialFocusID {
                // `.defaultFocus` alone loses to the first tile when the
                // screen replaces the whole window (app start), so set the
                // last-used profile explicitly once.
                didSetInitialFocus = true
                Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    focused = .profile(id)
                }
            }
        }
    }

    private var tiles: some View {
        HStack(alignment: .top, spacing: Spacing.xl) {
            ForEach(viewModel.profiles) { profile in
                Button {
                    if viewModel.isManaging {
                        editing = EditTarget(profile: profile)
                    } else {
                        viewModel.choose(profile)
                    }
                } label: {
                    ProfileTileLabel(content: .profile(profile, editing: viewModel.isManaging))
                }
                .buttonStyle(ProfileTileButtonStyle())
                .focused($focused, equals: .profile(profile.id))
                .accessibilityLabel(viewModel.isManaging ? "Edit \(profile.name)" : profile.name)
            }
            if viewModel.canAddProfile {
                Button {
                    editing = EditTarget(profile: nil)
                } label: {
                    ProfileTileLabel(content: .add)
                }
                .buttonStyle(ProfileTileButtonStyle())
                .focused($focused, equals: .add)
            }
        }
        .padding(.vertical, Spacing.l)
    }
}

#if DEBUG
#Preview {
    let store = ViewerProfileStore(
        repository: MockViewerProfileRepository(profiles: MockData.severalViewerProfiles),
        store: InMemorySecureStore()
    )
    NavigationStack {
        WhoIsWatchingView(viewModel: WhoIsWatchingViewModel(store: store))
    }
    .task { await store.load() }
}
#endif
