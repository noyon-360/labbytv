import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ForgotPasswordViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email, otp, password, confirm, action
    }

    init(viewModel: ForgotPasswordViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Reset your password")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)

            if let info = viewModel.infoMessage {
                Text(info).font(AppFonts.body).foregroundStyle(AppColors.success)
            }
            Text(viewModel.errorMessage ?? " ")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.error)

            switch viewModel.step {
            case .enterEmail:
                TextField("Email", text: $viewModel.email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .onSubmit(sendCode)
                actionButton("Send Code", action: sendCode)

            case .enterCode:
                TextField("6-digit code", text: $viewModel.otp)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .otp)
                    .onSubmit { focusedField = .password }
                SecureField("New Password", text: $viewModel.password)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .onSubmit { focusedField = .confirm }
                SecureField("Confirm New Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirm)
                    .onSubmit(reset)
                actionButton("Reset Password", action: reset)
                Button("Send the code again", action: sendCode)
                    .buttonStyle(SecondaryButtonStyle())

            case .done:
                actionButton("Back to Sign In") { dismiss() }
            }
        }
        .font(AppFonts.body)
        .frame(width: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .defaultFocus($focusedField, viewModel.email.isEmpty ? .email : .action)
        .onChange(of: viewModel.step) {
            focusedField = viewModel.step == .enterCode ? .otp : .action
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if viewModel.isLoading { ProgressView() } else { Text(title) }
        }
        .buttonStyle(PrimaryButtonStyle())
        .focused($focusedField, equals: .action)
        .padding(.top, Spacing.s)
    }

    private func sendCode() {
        focusedField = .action
        Task { await viewModel.sendCode() }
    }

    private func reset() {
        focusedField = .action
        Task { await viewModel.resetPassword() }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ForgotPasswordView(viewModel: ForgotPasswordViewModel(repository: MockAuthRepository()))
    }
}
#endif
