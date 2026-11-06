import SwiftUI

/// Typing a password with the remote is slow, so the QR sign-in sits next
/// to the form and gets focus first (as on the Flutter Android TV app).
struct TVLoginQRView: View {
    @State private var viewModel: TVLoginQRViewModel
    /// Where the login page puts initial focus. Starting on a text field
    /// would pop the keyboard over the QR code.
    var newCodeFocus: FocusState<Bool>.Binding

    init(viewModel: TVLoginQRViewModel, newCodeFocus: FocusState<Bool>.Binding) {
        _viewModel = State(initialValue: viewModel)
        self.newCodeFocus = newCodeFocus
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            Text("Sign in with your phone")
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("On your phone, open LABBY and go to Profile → Sign in on a TV. Scan this code or type it in.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            if let notice = viewModel.notice {
                Text(notice)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accent)
                    .multilineTextAlignment(.center)
            }

            // Fixed height so the button below doesn't jump when the
            // spinner is swapped for the QR code.
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .showing(let code):
                    qrCode(for: code)
                case .failed(let message):
                    Text(message)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }
            }
            .frame(height: 340)

            Button("Get a new code") { viewModel.requestNewCode() }
                .buttonStyle(SecondaryButtonStyle())
                .focused(newCodeFocus)
        }
        .task(id: viewModel.attempt) { await viewModel.run() }
    }

    private func qrCode(for code: TVLoginCode) -> some View {
        VStack(spacing: Spacing.s) {
            Group {
                if let image = QRCodeGenerator.image(for: code.qrPayload) {
                    Image(decorative: image, scale: 1)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.white
                }
            }
            .frame(width: 240, height: 240)
            .padding(Spacing.s)
            // Always black on white, whatever the theme: scanners need the contrast.
            .background(Color.white, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))

            Text(code.displayCode)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("Code \(code.displayCode)")
        }
    }
}

#if DEBUG
private struct TVLoginQRPreview: View {
    @FocusState private var focused: Bool
    var body: some View {
        TVLoginQRView(
            viewModel: TVLoginQRViewModel(repository: MockAuthRepository(), session: SessionStore(store: InMemorySecureStore()), deviceName: "Apple TV"),
            newCodeFocus: $focused
        )
        .background(AppColors.background)
    }
}

#Preview { TVLoginQRPreview() }
#endif
