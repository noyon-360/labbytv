import SwiftUI

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, email, password, confirm, terms, submit
    }

    init(viewModel: RegisterViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Create your account")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text(viewModel.errorMessage ?? " ")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.error)

                TextField("Name", text: $viewModel.name)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .email }

                TextField("Email", text: $viewModel.email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .onSubmit { focusedField = .confirm }

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirm)
                    .onSubmit { focusedField = .terms }

                HStack(spacing: Spacing.m) {
                    Toggle("I agree to the Terms & Conditions", isOn: $viewModel.agreedToTerms)
                        .focused($focusedField, equals: .terms)
                    NavigationLink("Read Terms") { LegalTextView(document: .terms) }
                        .buttonStyle(SecondaryButtonStyle())
                }

                Button {
                    focusedField = .submit
                    Task { await viewModel.register() }
                } label: {
                    if viewModel.isLoading { ProgressView() } else { Text("Sign Up") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .focused($focusedField, equals: .submit)
            }
            .font(AppFonts.body)
            .frame(width: 900)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
        .background(AppColors.background)
        .defaultFocus($focusedField, .name)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RegisterView(viewModel: RegisterViewModel(repository: MockAuthRepository(), session: SessionStore(store: InMemorySecureStore())))
    }
}
#endif
