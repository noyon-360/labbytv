import SwiftUI

/// 16:9 tile with the channel logo and name.
struct ChannelCard: View {
    let channel: Channel
    var subtitle: String?
    var width: CGFloat = Spacing.channelTileWidth
    var isFavorite = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ZStack {
                    AppColors.surface
                    RemoteImage(url: channel.imageURL, contentMode: .fit, placeholderSymbol: "tv")
                        .padding(Spacing.m)
                }
                .frame(width: width, height: width * 9 / 16)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
                .focusedArtwork()
                .overlay(alignment: .topTrailing) {
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.accent)
                            .padding(Spacing.xs)
                            .background(.black.opacity(0.6), in: Circle())
                            .padding(Spacing.xs)
                            .accessibilityLabel("Favorite")
                    }
                }

                CardCaption(title: channel.name, subtitle: subtitle, titleLines: 1, width: width)
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
