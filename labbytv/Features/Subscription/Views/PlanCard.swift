import SwiftUI

struct PlanCard: View {
    let package: PremiumPackage
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.m) {
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
                if isPurchasing {
                    ProgressView()
                }
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(width: 420, height: 320)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius * 1.5))
        }
        .buttonStyle(CardButtonStyle())
    }
}

#Preview {
    PlanCard(package: PremiumPackage(id: "m", title: "Monthly", price: "$4.99", period: "per month"), isPurchasing: false, action: {})
        .padding(Spacing.xl)
        .background(AppColors.background)
}
