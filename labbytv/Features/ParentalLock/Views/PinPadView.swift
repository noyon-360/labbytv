import SwiftUI

/// Full-screen PIN pad. Menu on the keypad cancels (the cover's own
/// dismissal); Menu on the password step goes back to the keypad.
struct PinPadView: View {
    @State private var viewModel: PinPadViewModel
    @FocusState private var focus: Key?

    private enum Key: Hashable {
        case digit(Int)
        case delete
        case forgot
        case cancel
        case password
        case action
    }

    init(viewModel: PinPadViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "lock.fill")
                .font(.system(size: 70))
                .foregroundStyle(AppColors.accent)

            switch viewModel.mode {
            case .pin: keypad
            case .password: passwordForm
            case .removed: removedNotice
            }
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .defaultFocus($focus, .digit(1))
        .onChange(of: viewModel.mode) {
            focus = switch viewModel.mode {
            case .pin: .digit(1)
            case .password: .password
            case .removed: .action
            }
        }
    }

    // MARK: Keypad

    private var keypad: some View {
        VStack(spacing: Spacing.m) {
            Text(viewModel.title).font(AppFonts.title)
            if let subtitle = viewModel.prompt.subtitle {
                Text(subtitle).font(AppFonts.body).foregroundStyle(AppColors.textSecondary)
            }

            HStack(spacing: Spacing.m) {
                ForEach(0..<viewModel.pinLength, id: \.self) { index in
                    Circle()
                        .strokeBorder(AppColors.textPrimary, lineWidth: 3)
                        .background(Circle().fill(index < viewModel.entered.count ? AppColors.textPrimary : .clear))
                        .frame(width: 34, height: 34)
                }
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement()
            .accessibilityLabel("\(viewModel.entered.count) of \(viewModel.pinLength) digits entered")

            Text(viewModel.errorMessage ?? " ")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.error)

            Grid(horizontalSpacing: Spacing.m, verticalSpacing: Spacing.m) {
                ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { digitKey($0) }
                    }
                }
                GridRow {
                    Color.clear.frame(width: 150, height: 96)
                    digitKey(0)
                    Button(action: viewModel.deleteLast) {
                        Image(systemName: "delete.left")
                    }
                    .buttonStyle(PinKeyButtonStyle())
                    .focused($focus, equals: .delete)
                    .accessibilityLabel("Delete")
                }
            }
            .focusSection()

            HStack(spacing: Spacing.m) {
                if viewModel.showsForgot {
                    Button("Forgot PIN?", action: viewModel.showForgot)
                        .focused($focus, equals: .forgot)
                }
                Button("Cancel", action: viewModel.cancel)
                    .focused($focus, equals: .cancel)
            }
            .buttonStyle(SecondaryButtonStyle())
            .frame(width: 760)
            .focusSection()
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        Button("\(digit)") { viewModel.add(digit) }
            .buttonStyle(PinKeyButtonStyle())
            .focused($focus, equals: .digit(digit))
    }

    // MARK: Forgot PIN

    private var passwordForm: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Forgot PIN?").font(AppFonts.title)
            Text("Enter your LABBY account password to remove the PIN. You can set a new one in Profile → Parental Lock.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Text(viewModel.errorMessage ?? " ")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.error)
            SecureField("Account password", text: $viewModel.password)
                .textContentType(.password)
                .focused($focus, equals: .password)
                .onSubmit { Task { await viewModel.resetWithPassword() } }
            Button {
                Task { await viewModel.resetWithPassword() }
            } label: {
                if viewModel.isChecking { ProgressView() } else { Text("Remove PIN") }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.password.isEmpty || viewModel.isChecking)
            .focused($focus, equals: .action)
            Button("Back", action: viewModel.backToPin)
                .buttonStyle(SecondaryButtonStyle())
        }
        .font(AppFonts.body)
        .frame(width: 900)
        .onExitCommand(perform: viewModel.backToPin)
    }

    private var removedNotice: some View {
        VStack(spacing: Spacing.l) {
            Text("PIN removed").font(AppFonts.title)
            Text("Set a new one in Profile → Parental Lock.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Button("Continue", action: viewModel.continueAfterRemoval)
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 520)
                .focused($focus, equals: .action)
        }
    }
}

#if DEBUG
#Preview("Verify") {
    let environment = AppEnvironment.preview()
    PinPadView(viewModel: PinPadViewModel(prompt: PinPrompt(kind: .verify, subtitle: "This category is locked."), lock: environment.parentalLock))
}

#Preview("Create") {
    let environment = AppEnvironment.preview()
    PinPadView(viewModel: PinPadViewModel(prompt: PinPrompt(kind: .create, subtitle: nil), lock: environment.parentalLock))
}
#endif
