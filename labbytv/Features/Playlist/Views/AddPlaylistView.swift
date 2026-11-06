import SwiftUI

struct AddPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddPlaylistViewModel
    let onSaved: () -> Void

    init(viewModel: AddPlaylistViewModel, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Add Playlist")
                .font(AppFonts.title)
            Text("Enter the Xtream Codes login from your IPTV provider.")
                .foregroundStyle(AppColors.textSecondary)
            Text(viewModel.errorMessage ?? " ")
                .foregroundStyle(AppColors.error)

            TextField("Playlist name", text: $viewModel.name)
            TextField("Server URL (http://host:port)", text: $viewModel.serverURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Username", text: $viewModel.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Password", text: $viewModel.password)

            Button {
                Task { await viewModel.save() }
            } label: {
                if viewModel.isSaving { ProgressView() } else { Text("Save Playlist") }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Spacing.s)
        }
        .font(AppFonts.body)
        .foregroundStyle(AppColors.textPrimary)
        .frame(width: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave {
                onSaved()
                dismiss()
            }
        }
    }
}

#if DEBUG
#Preview {
    AddPlaylistView(viewModel: AddPlaylistViewModel(repository: MockPlaylistRepository()), onSaved: {})
}
#endif
