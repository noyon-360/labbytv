import SwiftUI

/// One channel: logo cell, then its programmes positioned on the time axis.
struct GuideRowView: View {
    static let channelColumnWidth: CGFloat = 260
    static let rowHeight: CGFloat = 110
    /// Points per minute: 3 h × 7.5 = 1350 pt, which with the category
    /// rail and channel column fits the 1760-pt TV safe area.
    static let pointsPerMinute: CGFloat = 7.5

    let channel: Channel
    let programs: [EPGProgram]?
    let hasFailed: Bool
    let windowStart: Date
    let windowEnd: Date
    let now: Date
    /// Whether moving right past the last programme can slide the guide on.
    var canSlideForward = true
    /// The channel playing in the mini player.
    var isPreviewing = false
    var isFavorite = false
    var focus: FocusState<GuideFocus?>.Binding
    let onPlay: () -> Void
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Button(action: onPlay) {
                HStack(spacing: Spacing.s) {
                    RemoteImage(url: channel.imageURL, contentMode: .fit, placeholderSymbol: "tv")
                        .frame(width: 80, height: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name)
                            .font(AppFonts.caption)
                            .lineLimit(2)
                        if isPreviewing || isFavorite {
                            HStack(spacing: Spacing.xs) {
                                if isPreviewing { Image(systemName: "speaker.wave.2.fill") }
                                if isFavorite { Image(systemName: "heart.fill") }
                            }
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .frame(width: Self.channelColumnWidth - Spacing.s * 2, height: Self.rowHeight - Spacing.s, alignment: .leading)
                .padding(.horizontal, Spacing.s)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isPreviewing ? AppColors.accent : .clear, lineWidth: 3)
                )
            }
            .buttonStyle(GuideCellStyle(isAiring: false))
            .focused(focus, equals: .channel(channel.id))
            .zIndex(isFocused(.channel(channel.id)) ? 1 : 0)

            timeline
                .frame(width: timelineWidth, height: Self.rowHeight - Spacing.s, alignment: .leading)
                .overlay(alignment: .leading) {
                    if now >= windowStart && now < windowEnd {
                        NowLineView()
                            .offset(x: x(for: now))
                            .allowsHitTesting(false)
                    }
                }

            // Catches "right" past the last programme so the guide can
            // slide on; GuideView moves focus straight to the next programme.
            if canSlideForward, programs?.isEmpty == false {
                Color.clear
                    .frame(width: 2, height: Self.rowHeight - Spacing.s)
                    .focusable()
                    .focused(focus, equals: .later(channelID: channel.id))
                    .accessibilityHidden(true)
            }
        }
        .frame(height: Self.rowHeight)
        .focusSection()
    }

    private func isFocused(_ value: GuideFocus) -> Bool {
        focus.wrappedValue == value
    }

    private var timelineWidth: CGFloat {
        CGFloat(windowEnd.timeIntervalSince(windowStart) / 60) * Self.pointsPerMinute
    }

    private func x(for date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(windowStart) / 60) * Self.pointsPerMinute
    }

    @ViewBuilder
    private var timeline: some View {
        if let programs {
            if programs.isEmpty {
                placeholder("No guide information")
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(segments(programs).enumerated()), id: \.offset) { _, segment in
                        switch segment {
                        case .gap(let width):
                            Color.clear.frame(width: width)
                        case .program(let program, let width):
                            programCell(program, width: width)
                        }
                    }
                }
            }
        } else if hasFailed {
            Button("Guide unavailable · Retry", action: onRetry)
                .buttonStyle(GuideCellStyle(isAiring: false))
                .font(AppFonts.caption)
        } else {
            placeholder("Loading…")
        }
    }

    private func programCell(_ program: EPGProgram, width: CGFloat) -> some View {
        let airing = program.isAiring(at: now)
        return Button {
            if airing { onPlay() }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(program.title)
                    .font(AppFonts.caption)
                    .lineLimit(1)
                Text(DateFormatting.time(program.start))
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.s)
            .frame(width: max(width - 4, 8), height: Self.rowHeight - Spacing.s, alignment: .leading)
            .background(airing ? AppColors.surfaceRaised : AppColors.surface, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(GuideCellStyle(isAiring: airing))
        .focused(focus, equals: .program(channelID: channel.id, programID: program.id))
        .frame(width: width, alignment: .leading)
        // The style's own zIndex only orders views inside the button; this
        // one lifts the focused cell above its neighbours in the row.
        .zIndex(isFocused(.program(channelID: channel.id, programID: program.id)) ? 1 : 0)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, Spacing.m)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(AppColors.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private enum Segment {
        case gap(CGFloat)
        case program(EPGProgram, CGFloat)
    }

    /// Lays programmes on the axis, clipping at the window edges and
    /// leaving gaps where the provider has no data.
    private func segments(_ programs: [EPGProgram]) -> [Segment] {
        var result: [Segment] = []
        var cursor = windowStart
        for program in programs {
            let start = max(program.start, cursor)
            let end = min(program.end, windowEnd)
            guard end > start else { continue }
            if start > cursor {
                result.append(.gap(x(for: start) - x(for: cursor)))
            }
            result.append(.program(program, x(for: end) - x(for: start)))
            cursor = end
        }
        return result
    }
}

/// Guide cells: white outline + lift on focus.
struct GuideCellStyle: ButtonStyle {
    let isAiring: Bool

    func makeBody(configuration: Configuration) -> some View {
        GuideCellBody(configuration: configuration)
    }

    private struct GuideCellBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .foregroundStyle(AppColors.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? AppColors.textPrimary : .clear, lineWidth: 4)
                )
                .scaleEffect(isFocused ? 1.04 : 1)
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 10, y: 6)
                .zIndex(isFocused ? 1 : 0)
                .animation(.easeOut(duration: 0.12), value: isFocused)
        }
    }
}
