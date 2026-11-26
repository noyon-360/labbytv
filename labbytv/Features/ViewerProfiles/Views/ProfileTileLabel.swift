import SwiftUI

/// Avatar (or the "+" add tile) with the name underneath.
struct ProfileTileLabel: View {
    enum Content {
        case profile(ViewerProfile, editing: Bool)
        case add
    }

    let content: Content
    static let avatarSize: CGFloat = 220
    @Environment(\.profileTileIsFocused) private var isFocused

    var body: some View {
        VStack(spacing: Spacing.m) {
            artwork
                .overlay {
                    RoundedRectangle(cornerRadius: Self.avatarSize * 0.18, style: .continuous)
                        .strokeBorder(.white, lineWidth: isFocused ? 8 : 0)
                }
            Text(title)
                .font(isFocused ? AppFonts.bodyBold : AppFonts.body)
                .lineLimit(1)
                .frame(width: Self.avatarSize + 40)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        switch content {
        case .profile(let profile, let editing):
            ProfileAvatarView(avatar: profile.avatar, size: Self.avatarSize)
                .overlay {
                    if editing {
                        RoundedRectangle(cornerRadius: Self.avatarSize * 0.18, style: .continuous)
                            .fill(.black.opacity(0.45))
                        Image(systemName: "pencil")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
        case .add:
            RoundedRectangle(cornerRadius: Self.avatarSize * 0.18, style: .continuous)
                .fill(AppColors.surface)
                .frame(width: Self.avatarSize, height: Self.avatarSize)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 90, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
        }
    }

    private var title: String {
        switch content {
        case .profile(let profile, _): profile.name
        case .add: "Add Profile"
        }
    }
}
