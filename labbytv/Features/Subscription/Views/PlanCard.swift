import SwiftUI

struct PlanCard: View {
    let package: PremiumPackage
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.m) {
                if let trial = package.trial {
                    Text(trial.label.uppercased())
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.success)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xs)
                        .overlay(Capsule().stroke(AppColors.success, lineWidth: 2))
                }
                Text(package.title)
                    .font(AppFonts.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(package.price)
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.accent)
                Text(package.period)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                if let trial = package.trial {
                    Text("Free for \(trial.durationText), then \(package.price) \(package.period)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.success)
                        .multilineTextAlignment(.center)
                    Text(trial.buttonLabel)
                        .font(AppFonts.button)
                }
                if isPurchasing {
                    ProgressView()
                }
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, Spacing.m)
            .frame(width: 420, height: package.trial == nil ? 320 : 460)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius * 1.5))
        }
        .buttonStyle(CardButtonStyle())
    }
}

#Preview {
    HStack(spacing: Spacing.l) {
        PlanCard(package: PremiumPackage(id: "m", title: "Monthly", price: "$4.99", period: "per month"), isPurchasing: false, action: {})
        PlanCard(
            package: PremiumPackage(id: "t", title: "Monthly", price: "$4.99", period: "per month", trial: FreeTrialOffer(unit: .day, count: 7)),
            isPurchasing: false,
            action: {}
        )
    }
    .padding(Spacing.xl)
    .background(AppColors.background)
}
