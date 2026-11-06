import SwiftUI
import UIKit

/// Layout matches the Flutter Android TV login page: welcome text on top,
/// QR sign-in left (initial focus), "OR", email form right.
struct LoginView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    @FocusState private var newCodeFocused: Bool

    private enum Field: Hashable {
        case email, password, login
    }

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: Spacing.l) {
            LoginWelcomeIntro()

            HStack(spacing: Spacing.l) {
                TVLoginQRView(
                    viewModel: TVLoginQRViewModel(
                        repository: environment.authRepository,
                        session: environment.session,
                        deviceName: UIDevice.current.name,
                        onSignedIn: { await environment.didSignIn() }
                    ),
                    newCodeFocus: $newCodeFocused
                )
                .frame(maxWidth: .infinity)
                .focusSection()

                divider

                form
                    .frame(maxWidth: .infinity)
                    .focusSection()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .defaultFocus($newCodeFocused, true)
    }

    private var divider: some View {
        VStack(spacing: Spacing.m) {
            Rectangle().fill(AppColors.surfaceRaised).frame(width: 2)
            Text("OR")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            Rectangle().fill(AppColors.surfaceRaised).frame(width: 2)
        }
        .padding(.vertical, Spacing.l)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Sign in with email")
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.error)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }

            // .username / .password let tvOS offer iPhone keyboard entry and
            // saved-password autofill, which beats typing with the remote.
            TextField("Email", text: $viewModel.email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
                .disabled(viewModel.isLoading)
                .onSubmit { focusedField = .password }

            SecureField("Enter your Password", text: $viewModel.password)
                .textContentType(.password)
                .submitLabel(.go)
                .focused($focusedField, equals: .password)
                .disabled(viewModel.isLoading)
                .onSubmit { submit() }

            HStack {
                Spacer()
                NavigationLink("Forget Password") {
                    ForgotPasswordView(viewModel: ForgotPasswordViewModel(
                        repository: environment.authRepository,
                        initialEmail: viewModel.email
                    ))
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Button(action: submit) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .focused($focusedField, equals: .login)

            HStack(spacing: Spacing.s) {
                Text("Don’t have an account?")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                NavigationLink("Sign Up") {
                    RegisterView(viewModel: RegisterViewModel(
                        repository: environment.authRepository,
                        session: environment.session,
                        onSignedIn: { await environment.didSignIn() }
                    ))
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
        .font(AppFonts.body)
        .onChange(of: viewModel.email) { viewModel.clearError() }
        .onChange(of: viewModel.password) { viewModel.clearError() }
    }

    private func submit() {
        // The fields are disabled while loading, and tvOS can't focus a
        // disabled control. Parking focus on the (still enabled) button stops
        // it jumping somewhere unexpected. The view model ignores double taps.
        focusedField = .login
        Task { await viewModel.login() }
    }
}

#if DEBUG
#Preview("Login") {
    let environment = AppEnvironment.preview(loggedIn: false, playlist: false)
    NavigationStack {
        LoginView(viewModel: LoginViewModel(repository: MockAuthRepository(), session: environment.session))
    }
    .environment(environment)
}
#endif
