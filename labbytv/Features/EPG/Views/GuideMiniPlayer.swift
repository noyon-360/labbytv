import SwiftUI

/// Top-left of the guide: the channel playing now keeps playing while the
/// user browses (client feedback #1). Select on the playing channel opens
/// it full screen; Back from full screen returns here without a restart.
struct GuideMiniPlayer: View {
    @Environment(LivePreview.self) private var preview

    static let width: CGFloat = 384
    static let height: CGFloat = 216

    var body: some View {
        ZStack {
            AppColors.surface
            if preview.channel != nil {
                PlayerLayerView(player: preview.player)
            }
            overlay
        }
        .frame(width: Self.width, height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                .stroke(AppColors.surfaceRaised, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var overlay: some View {
        switch preview.state {
        case .idle:
            VStack(spacing: Spacing.xs) {
                Image(systemName: "play.tv")
                    .font(.system(size: 44))
                Text("Select a channel to preview it here")
                    .font(AppFonts.caption)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(AppColors.textSecondary)
            .padding(Spacing.m)
        case .loading:
            ProgressView()
        case .failed(let message):
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(Spacing.m)
        case .playing:
            if let channel = preview.channel {
                Text(channel.name)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(Spacing.xs)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
}
