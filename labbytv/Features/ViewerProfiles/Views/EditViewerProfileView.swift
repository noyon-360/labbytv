import SwiftUI

/// Add Profile / Edit Profile: name, one of the 12 avatars, Save, and
/// Delete for every profile except the main one.
struct EditViewerProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditViewerProfileViewModel
    @State private var confirmingDelete = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name
        case avatar(String)
        case save
    }

    private let columns = Array(repeating: GridItem(.fixed(150), spacing: Spacing.l), count: 6)

    init(viewModel: EditViewerProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xxl) {
            VStack(spacing: Spacing.m) {
                ProfileAvatarView(avatar: viewModel.avatar, size: 300)
                Text(viewModel.trimmedName.isEmpty ? " " : viewModel.trimmedName)
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 400)
            .padding(.top, Spacing.xl)

            VStack(alignment: .leading, spacing: Spacing.l) {
                Text(viewModel.title)
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                TextField("Profile name", text: $viewModel.name)
                    .font(AppFonts.body)
                    .focused($focus, equals: .name)
                    .submitLabel(.done)
                    .onChange(of: viewModel.name) { _, new in
                        if new.count > EditViewerProfileViewModel.maxNameLength {
                            viewModel.name = String(new.prefix(EditViewerProfileViewModel.maxNameLength))
                        }
                    }

                Text("Choose an avatar")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textSecondary)

                LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.l) {
                    ForEach(AvatarPreset.all, id: \.key) { preset in
                        Button {
                            viewModel.avatar = preset.key
                        } label: {
                            AvatarChoiceLabel(avatar: preset.key, isSelected: viewModel.avatar == preset.key)
                        }
                        .buttonStyle(CardButtonStyle())
                        .focused($focus, equals: .avatar(preset.key))
                        .accessibilityLabel("Avatar \(preset.key.suffix(2))")
                        .accessibilityAddTraits(viewModel.avatar == preset.key ? .isSelected : [])
                    }
                }
                .focusSection()

                if let error = viewModel.error {
                    Text(error)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.error)
                }

                HStack(spacing: Spacing.l) {
                    Button {
                        Task {
                            if await viewModel.save() { dismiss() }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 360)
                    .focused($focus, equals: .save)
                    .disabled(viewModel.isSaving)

                    if viewModel.canDelete {
                        Button("Delete Profile", role: .destructive) {
                            confirmingDelete = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isSaving)
                    }
                }
                // Full width, so Down from any avatar column reaches Save
                // (the focus engine only looks straight down otherwise).
                .frame(maxWidth: .infinity, alignment: .leading)
                .focusSection()

                if viewModel.isMainProfile {
                    Text("This is the account's main profile, so it can't be deleted.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
        // New profile: start on the name. Editing: start on the current avatar.
        .defaultFocus($focus, viewModel.isNew ? .name : .avatar(viewModel.avatar))
        .confirmationDialog(
            "Delete \(viewModel.profile?.name ?? "profile")?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.delete() { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This profile's history, favourites and My List will be deleted. This can't be undone.")
        }
    }
}

private struct AvatarChoiceLabel: View {
    let avatar: String
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        ProfileAvatarView(avatar: avatar, size: 150)
            .overlay {
                RoundedRectangle(cornerRadius: 150 * 0.18, style: .continuous)
                    .strokeBorder(isFocused ? .white : AppColors.accent, lineWidth: isFocused || isSelected ? 7 : 0)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.accent, .black)
                        .offset(x: 12, y: -12)
                }
            }
    }
}

#if DEBUG
#Preview("Add") {
    let store = ViewerProfileStore(repository: MockViewerProfileRepository(), store: InMemorySecureStore())
    NavigationStack {
        EditViewerProfileView(viewModel: EditViewerProfileViewModel(profile: nil, store: store))
    }
}

#Preview("Edit main") {
    let store = ViewerProfileStore(repository: MockViewerProfileRepository(), store: InMemorySecureStore())
    NavigationStack {
        EditViewerProfileView(viewModel: EditViewerProfileViewModel(profile: MockData.viewerProfiles[0], store: store))
    }
}
#endif
