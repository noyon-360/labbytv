import SwiftUI

/// Profile → Parental Lock. Without a PIN it only offers "Set PIN"; with one,
/// actions sit on the left and the category list on the right, each a
/// focus section so swiping left/right moves between them.
struct ParentalLockView: View {
    @State private var viewModel: ParentalLockViewModel
    @State private var confirmingTurnOff = false

    init(viewModel: ParentalLockViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.hasPin {
                settings
            } else {
                intro
            }
        }
        .foregroundStyle(AppColors.textPrimary)
        .confirmationDialog("Turn off parental lock?", isPresented: $confirmingTurnOff, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) { viewModel.turnOff() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Locked categories will open without a PIN. Your choices are kept if you set a PIN again.")
        }
    }

    // MARK: No PIN yet

    private var intro: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "lock.shield")
                .font(.system(size: 100))
                .foregroundStyle(AppColors.accent)
            Text("Parental Lock").font(AppFonts.title)
            Text("Set a PIN to lock categories you don't want children to watch.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Set PIN") { Task { await viewModel.setOrChangePin() } }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 520)
                .prefersDefaultFocus(true, in: namespace)
        }
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusScope(namespace)
    }

    @Namespace private var namespace

    // MARK: PIN set

    private var settings: some View {
        HStack(alignment: .top, spacing: Spacing.xxl) {
            actions
                .frame(width: 560, alignment: .topLeading)
            categoryPanel
        }
        .padding(.top, Spacing.l)
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Parental Lock").font(AppFonts.title)
            Text("Locked categories need the PIN to open and are hidden from \"All\", Home and Search.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Button("Change PIN") { Task { await viewModel.setOrChangePin() } }
                .buttonStyle(PrimaryButtonStyle())
            Button("Turn Off Parental Lock") { confirmingTurnOff = true }
                .buttonStyle(SecondaryButtonStyle())
        }
        .focusSection()
    }

    private var categoryPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                ForEach([ContentType.channels, .movies, .series], id: \.self) { section in
                    Button(section.title) { Task { await viewModel.select(section) } }
                        .buttonStyle(ChipButtonStyle(isSelected: section == viewModel.section))
                }
            }
            .focusSection()

            TextField("Search categories (e.g. adult, xxx, horror)", text: $viewModel.query)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            categoryList
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var categoryList: some View {
        if viewModel.isLoading && !viewModel.hasLoadedSection {
            LoadingView()
        } else if let message = viewModel.errorMessage {
            ErrorView(message: message, retry: { Task { await viewModel.loadIfNeeded() } })
        } else if viewModel.visibleCategories.isEmpty {
            EmptyStateView(
                symbol: "magnifyingglass",
                title: viewModel.query.isEmpty ? "No categories" : "No matches",
                message: viewModel.query.isEmpty ? "No categories found for this playlist." : "No categories match \"\(viewModel.query)\"."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.s) {
                    ForEach(viewModel.visibleCategories) { category in
                        categoryRow(category)
                    }
                }
                .padding(.vertical, Spacing.s)
            }
            .scrollClipDisabled()
            .focusSection()
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        let locked = viewModel.isLocked(category)
        return Button {
            viewModel.toggle(category)
        } label: {
            HStack(spacing: Spacing.m) {
                Text(category.name.isEmpty ? "Untitled" : category.name)
                    .font(AppFonts.body)
                    .lineLimit(1)
                Spacer()
                Image(systemName: locked ? "lock.fill" : "lock.open")
                    .font(.system(size: 32))
                    .foregroundStyle(locked ? AppColors.error : AppColors.textSecondary)
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, Spacing.l)
            .frame(height: 84)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityValue(locked ? "Locked" : "Unlocked")
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    NavigationStack {
        ParentalLockView(viewModel: ParentalLockViewModel(lock: environment.parentalLock, catalog: MockCatalogRepository()))
    }
    .pinPrompt(environment.parentalLock)
}
#endif
