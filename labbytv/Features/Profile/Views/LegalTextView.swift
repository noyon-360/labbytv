import SwiftUI

/// Scrollable legal text. Each section is focusable so the Siri Remote can
/// scroll through it (plain text can't take focus on tvOS).
struct LegalTextView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text(document.title)
                    .font(AppFonts.title)
                Text(LegalDocument.lastUpdated)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                ForEach(document.sections, id: \.heading) { section in
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(section.heading).font(AppFonts.headline)
                        Text(section.body).font(AppFonts.body).foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: 1400, alignment: .leading)
                    .padding(Spacing.m)
                    .focusable()
                }

                Text(document.closing)
                    .font(AppFonts.body)
                    .padding(Spacing.m)
                    .focusable()
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.vertical, Spacing.xl)
        }
        .background(AppColors.background)
    }
}

#Preview {
    LegalTextView(document: .privacy)
}
