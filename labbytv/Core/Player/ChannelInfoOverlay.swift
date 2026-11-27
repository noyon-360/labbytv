import SwiftUI

/// Shown for a few seconds when a live channel starts or changes: logo,
/// channel, what's on now (time, progress, description) and what's next.
struct ChannelInfoOverlay: View {
    let channel: Channel
    let nowNext: NowNext?
    var isFavorite = false
    var resolution: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(alignment: .top, spacing: Spacing.l) {
                RemoteImage(url: channel.imageURL, contentMode: .fit, placeholderSymbol: "tv")
                    .frame(width: 200, height: 112)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.s) {
                        if channel.num > 0 {
                            // verbatim: a plain Text interpolation would print 14762 as "14,762".
                            Text(verbatim: String(channel.num))
                                .font(AppFonts.bodyBold)
                                .foregroundStyle(AppColors.accent)
                        }
                        Text(channel.name)
                            .font(AppFonts.bodyBold)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.accent)
                        }
                        if let resolution {
                            ResolutionBadge(text: resolution)
                        }
                    }

                    if let now = nowNext?.now {
                        Text(now.title)
                            .font(AppFonts.headline)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                        HStack(spacing: Spacing.s) {
                            Text(DateFormatting.timeRange(now.start, now.end))
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            ProgressBar(value: now.progress(at: context.date))
                                .frame(width: 320, height: 8)
                                .clipShape(Capsule())
                        }
                        if !now.description.isEmpty {
                            Text(now.description)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(2)
                        }
                    } else if nowNext == nil {
                        Text("Loading programme info…")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        Text("No programme information")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    if let next = nowNext?.next {
                        Text("Next  \(DateFormatting.time(next.start))  \(next.title)")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.l)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius * 1.5))
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    let now = Date.now
    ChannelInfoOverlay(
        channel: MockData.channels[0],
        nowNext: NowNext(
            now: EPGProgram(id: "1", title: "Evening News", description: "Headlines and weather from around the country.", start: now.addingTimeInterval(-1200), end: now.addingTimeInterval(1800)),
            next: EPGProgram(id: "2", title: "Late Movie", description: "", start: now.addingTimeInterval(1800), end: now.addingTimeInterval(7200))
        ),
        isFavorite: true,
        resolution: "FHD"
    )
    .padding(Spacing.xl)
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(Color.gray)
}
#endif
