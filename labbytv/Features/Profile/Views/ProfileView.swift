import SwiftUI

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: ProfileViewModel
    @State private var confirmingSignOut = false
    @State private var showingParentalLock = false
    @State private var parentalUpsell: String?
    @State private var showingPaywall = false

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xxl) {
            account
                .frame(width: 560, alignment: .topLeading)

            ScrollView {
                VStack(spacing: Spacing.m) {
                    if !viewModel.isPremium {
                        row("Get LABBY TV Pro", symbol: "crown.fill", route: .paywall)
                    }
                    row("Switch Playlist", symbol: "list.bullet.rectangle", detail: viewModel.playlistName, route: .playlists)
                    row("Favorites", symbol: "heart.fill", route: .favorites)
                    row("Watch History", symbol: "clock.fill", route: .history)
                    Button {
                        if let message = viewModel.parentalLockBlockMessage {
                            parentalUpsell = message
                            return
                        }
                        // Only the parent may change the locks.
                        Task {
                            if await viewModel.unlockParentalSettings() {
                                showingParentalLock = true
                            }
                        }
                    } label: {
                        ProfileRowLabel(title: "Parental Lock", symbol: "lock.shield.fill", detail: viewModel.parentalLockIsOn ? "On" : "Off", tint: AppColors.accent)
                    }
                    .buttonStyle(CardButtonStyle())
                    if viewModel.isPremium {
                        row("Subscription", symbol: "crown.fill", detail: "Pro", route: .paywall)
                    }
                    row("Privacy Policy", symbol: "hand.raised.fill", route: .legal(.privacy))
                    row("Terms & Conditions", symbol: "doc.text.fill", route: .legal(.terms))
                    row("Open Source Licenses", symbol: "chevron.left.forwardslash.chevron.right", route: .legal(.licenses))

                    Button(role: .destructive) {
                        confirmingSignOut = true
                    } label: {
                        ProfileRowLabel(title: "Sign Out", symbol: "rectangle.portrait.and.arrow.right", detail: nil, tint: AppColors.error)
                    }
                    .buttonStyle(CardButtonStyle())
                }
                .padding(.vertical, Spacing.m)
            }
            .scrollClipDisabled()
            .focusSection()
        }
        .padding(.top, Spacing.l)
        .task { await viewModel.load() }
        .navigationDestination(isPresented: $showingParentalLock) {
            ParentalLockView(viewModel: ParentalLockViewModel(lock: environment.parentalLock, catalog: environment.catalogRepository))
        }
        .navigationDestination(isPresented: $showingPaywall) {
            AppRouteDestination(route: .paywall)
        }
        .alert(
            "Premium feature",
            isPresented: Binding(get: { parentalUpsell != nil }, set: { if !$0 { parentalUpsell = nil } }),
            presenting: parentalUpsell
        ) { _ in
            Button(viewModel.isPremium ? "View Plans" : "See Plans") { showingPaywall = true }
            Button("Not Now", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .confirmationDialog("Sign out of LABBY TV?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { Task { await viewModel.signOut() } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var account: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 140))
                .foregroundStyle(AppColors.surfaceRaised)
            if viewModel.isLoading && viewModel.user == nil {
                ProgressView()
            }
            Text(viewModel.user?.name ?? "")
                .font(AppFonts.title)
                .lineLimit(1)
            Text(viewModel.user?.email ?? "")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Label(viewModel.planLabel, systemImage: viewModel.isPremium ? "crown.fill" : "person")
                .font(AppFonts.bodyBold)
                .foregroundStyle(viewModel.isPremium ? AppColors.accent : AppColors.textSecondary)
            Spacer()
            Text(viewModel.appVersion)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .foregroundStyle(AppColors.textPrimary)
    }

    private func row(_ title: String, symbol: String, detail: String? = nil, route: AppRoute) -> some View {
        NavigationLink(value: route) {
            ProfileRowLabel(title: title, symbol: symbol, detail: detail, tint: AppColors.accent)
        }
        .buttonStyle(CardButtonStyle())
    }
}

private struct ProfileRowLabel: View {
    let title: String
    let symbol: String
    let detail: String?
    let tint: Color

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: symbol)
                .font(.system(size: 36))
                .foregroundStyle(tint)
                .frame(width: 60)
            Text(title).font(AppFonts.bodyBold)
            Spacer()
            if let detail {
                Text(detail).font(AppFonts.body).foregroundStyle(AppColors.textSecondary).lineLimit(1)
            }
            Image(systemName: "chevron.right").foregroundStyle(AppColors.textSecondary)
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, Spacing.l)
        .frame(height: 96)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    NavigationStack {
        ProfileView(viewModel: ProfileViewModel(environment: environment))
            .appRouteDestinations()
    }
    .environment(environment)
    .pinPrompt(environment.parentalLock)
}
#endif
