import SwiftUI

struct PaywallView: View {
    @State private var viewModel: PaywallViewModel

    init(viewModel: PaywallViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// The TV-relevant features from the Flutter subscription screen.
    private let features = [
        "Unlimited EPG navigation",
        "No watermarks",
        "Instant sync across devices",
        "No device limit",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                Text("LABBY TV Pro")
                    .font(AppFonts.title)

                if viewModel.premium.isPremium {
                    Label("You're subscribed", systemImage: "checkmark.seal.fill")
                        .font(AppFonts.headline)
                        .foregroundStyle(AppColors.success)
                }

                HStack(spacing: Spacing.l) {
                    ForEach(features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if let message = viewModel.successMessage {
                    Text(message).foregroundStyle(AppColors.success)
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(AppColors.error).multilineTextAlignment(.center)
                }

                plans

                HStack(spacing: Spacing.l) {
                    Button {
                        Task { await viewModel.restore() }
                    } label: {
                        if viewModel.isRestoring { ProgressView() } else { Text("Restore Purchases") }
                    }
                    .disabled(!viewModel.premium.isPurchasingAvailable)
                    NavigationLink("Terms", value: AppRoute.legal(.terms))
                    NavigationLink("Privacy", value: AppRoute.legal(.privacy))
                }
                .buttonStyle(SecondaryButtonStyle())
                .focusSection()

                Text("Subscriptions renew automatically until cancelled in Settings › Accounts on Apple TV, or on any Apple device signed in with the same Apple ID.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 1300)
            }
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
        }
        .background(AppColors.background)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var plans: some View {
        if !viewModel.premium.isPurchasingAvailable {
            Text("Subscriptions aren't available in this build yet.")
                .foregroundStyle(AppColors.textSecondary)
                .padding(Spacing.l)
        } else if viewModel.isLoading {
            ProgressView().padding(Spacing.l)
        } else if viewModel.premium.packages.isEmpty {
            ErrorView(message: "No plans are available right now.", retry: { Task { await viewModel.load() } })
                .frame(height: 320)
        } else {
            HStack(spacing: Spacing.l) {
                ForEach(viewModel.premium.packages) { package in
                    PlanCard(package: package, isPurchasing: viewModel.purchasingID == package.id) {
                        Task { await viewModel.purchase(package) }
                    }
                }
            }
            .focusSection()
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView(viewModel: PaywallViewModel(premium: PremiumService()))
    }
}
