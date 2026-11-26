import SwiftUI

/// One of the 12 preset avatars: a coloured rounded square with a symbol.
struct ProfileAvatarView: View {
    let avatar: String
    var size: CGFloat = 96

    var body: some View {
        let preset = AvatarPreset.preset(for: avatar)
        RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
            .fill(preset.color)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: preset.symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(140)), count: 6), spacing: Spacing.l) {
        ForEach(AvatarPreset.all, id: \.key) { preset in
            ProfileAvatarView(avatar: preset.key, size: 120)
        }
    }
    .padding()
    .background(AppColors.background)
}
