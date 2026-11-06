import SwiftUI

/// 16:9 tile with the channel logo and name.
struct ChannelCard: View {
    let channel: Channel
    var subtitle: String?
    var width: CGFloat = Spacing.channelTileWidth
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ZStack {
                    AppColors.surface
                    RemoteImage(url: channel.imageURL, contentMode: .fit, placeholderSymbol: "tv")
                        .padding(Spacing.m)
                }
                .frame(width: width, height: width * 9 / 16)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityLabel(channel.name)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: Spacing.gridSpacing) {
        ForEach(MockData.channels.prefix(3)) { channel in
            ChannelCard(channel: channel, action: {})
        }
    }
    .padding(Spacing.xl)
    .background(AppColors.background)
}
#endif
