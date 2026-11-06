import SwiftUI

struct EpisodeRow: View {
    let episode: Episode
    let fallbackImage: URL?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                RemoteImage(url: episode.imageURL ?? fallbackImage, placeholderSymbol: "play.rectangle")
                    .frame(width: 320, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Episode \(episode.episodeNum)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(episode.title.isEmpty ? "Episode \(episode.episodeNum)" : episode.title)
                        .font(AppFonts.bodyBold)
                        .lineLimit(2)
                    let duration = episode.durationSecs > 0 ? DateFormatting.duration(seconds: episode.durationSecs) : episode.duration
                    if !duration.isEmpty {
                        Text(duration)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.accent)
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(Spacing.s)
            .background(AppColors.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        }
        .buttonStyle(CardButtonStyle())
    }
}

#if DEBUG
#Preview {
    EpisodeRow(episode: MockData.seriesInfo.episodes[1]![0], fallbackImage: nil, action: {})
        .padding(Spacing.xl)
        .background(AppColors.background)
}
#endif
