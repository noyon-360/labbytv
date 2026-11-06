import SwiftUI

/// One channel: logo cell, then its programmes positioned on the time axis.
struct GuideRowView: View {
    static let channelColumnWidth: CGFloat = 260
    static let rowHeight: CGFloat = 110
    /// Points per minute: 3 h × 8 = 1440 pt, which with the channel column
    /// fits the 1760-pt TV safe area without horizontal scrolling.
    static let pointsPerMinute: CGFloat = 8

    let channel: Channel
    let programs: [EPGProgram]?
    let hasFailed: Bool
    let windowStart: Date
    let windowEnd: Date
    let now: Date
    var focus: FocusState<GuideFocus?>.Binding
    let onPlay: () -> Void
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Button(action: onPlay) {
                HStack(spacing: Spacing.s) {
                    RemoteImage(url: channel.imageURL, contentMode: .fit, placeholderSymbol: "tv")
                        .frame(width: 80, height: 60)
                    Text(channel.name)
                        .font(AppFonts.caption)
                        .lineLimit(2)
                }
                .frame(width: Self.channelColumnWidth - Spacing.s * 2, height: Self.rowHeight - Spacing.s, alignment: .leading)
                .padding(.horizontal, Spacing.s)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(GuideCellStyle(isAiring: false))
            .focused(focus, equals: .channel(channel.id))

            timeline
                .frame(width: timelineWidth, height: Self.rowHeight - Spacing.s, alignment: .leading)
                .overlay(alignment: .leading) {
                    if now >= windowStart && now < windowEnd {
                        NowLineView()
                            .offset(x: x(for: now))
                            .allowsHitTesting(false)
                    }
                }
        }
        .frame(height: Self.rowHeight)
        .focusSection()
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
