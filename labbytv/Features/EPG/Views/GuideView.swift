import SwiftUI

/// The TV guide. Premium only (`LABBY TV Pro`), as in the brief.
struct GuideView: View {
    @Environment(PremiumService.self) private var premium
    @Environment(PlayerPresenter.self) private var player
    let viewModel: GuideViewModel
    @FocusState private var focus: GuideFocus?

    var body: some View {
        if premium.isPremium {
            guide
        } else {
            upsell
        }
    }

    private var upsell: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.accent)
            Text("The TV Guide is part of LABBY TV Pro")
                .font(AppFonts.title)
                .multilineTextAlignment(.center)
            Text("See what's on now and next across all your channels.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            NavigationLink("Get LABBY TV Pro", value: AppRoute.paywall)
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 520)
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            details
                .frame(height: 170, alignment: .topLeading)

            HStack(spacing: Spacing.m) {
                CategoryChips(
                    categories: viewModel.channels.categories,
                    selected: viewModel.channels.selectedCategory,
                    onSelect: { category in Task { await viewModel.channels.select(category) } }
                )
                timeControls
            }

            ruler

            rows
        }
        .task { await viewModel.channels.loadIfNeeded() }
        .task { await viewModel.tickClock() }
    }

    @ViewBuilder
    private var details: some View {
        switch focus {
        case .program(let channelID, let programID):
            if let program = viewModel.program(channelID: channelID, programID: programID) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(program.title).font(AppFonts.headline).lineLimit(1)
                    Text(DateFormatting.timeRange(program.start, program.end) + (program.isAiring(at: viewModel.now) ? "  ·  On now — press to watch" : ""))
                        .font(AppFonts.caption)
                        .foregroundStyle(program.isAiring(at: viewModel.now) ? AppColors.accent : AppColors.textSecondary)
                    if !program.description.isEmpty {
                        Text(program.description).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary).lineLimit(2)
                    }
                }
            }
        case .channel(let channelID):
            if let channel = viewModel.channels.items.first(where: { $0.id == channelID }) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(channel.name).font(AppFonts.headline)
                    Text("Press to watch").font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                }
            }
        case nil:
            Text("TV Guide").font(AppFonts.title)
        }
    }

    private var timeControls: some View {
        HStack(spacing: Spacing.s) {
            Button { viewModel.shiftWindow(forward: false) } label: { Image(systemName: "chevron.left") }
                .disabled(!viewModel.canGoEarlier)
            Button("Now") { viewModel.jumpToNow() }
            Button { viewModel.shiftWindow(forward: true) } label: { Image(systemName: "chevron.right") }
                .disabled(!viewModel.canGoLater)
        }
        .buttonStyle(ChipButtonStyle(isSelected: false))
        .focusSection()
    }

    private var ruler: some View {
        HStack(spacing: Spacing.xs) {
            Text(viewModel.windowStart.formatted(.dateTime.weekday(.wide)))
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: GuideRowView.channelColumnWidth, alignment: .leading)
            ZStack(alignment: .leading) {
                ForEach(0..<6, id: \.self) { index in
                    let time = viewModel.windowStart.addingTimeInterval(Double(index) * 1800)
                    Text(DateFormatting.time(time))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .offset(x: CGFloat(index * 30) * GuideRowView.pointsPerMinute)
                }
            }
            .frame(width: CGFloat(GuideViewModel.windowLength / 60) * GuideRowView.pointsPerMinute, alignment: .leading)
        }
    }

    @ViewBuilder
    private var rows: some View {
        let channels = viewModel.channels
        if channels.isLoading && channels.items.isEmpty {
            LoadingView()
        } else if let message = channels.errorMessage, channels.items.isEmpty {
            ErrorView(message: message, retry: { Task { await channels.retry() } })
        } else if channels.items.isEmpty {
            EmptyStateView(symbol: "tv", title: "No channels", message: "Try another category.")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(channels.items) { channel in
                        GuideRowView(
                            channel: channel,
                            programs: viewModel.programs[channel.id].map { _ in viewModel.visiblePrograms(for: channel.id) },
                            hasFailed: viewModel.failedChannels.contains(channel.id),
                            windowStart: viewModel.windowStart,
                            windowEnd: viewModel.windowEnd,
                            now: viewModel.now,
                            focus: $focus,
                            onPlay: { player.play(.live(channel, lineup: channels.items)) },
                            onRetry: { Task { await viewModel.retryPrograms(for: channel) } }
                        )
                        .task(id: channel.id) { await viewModel.loadPrograms(for: channel) }
                        .onAppear { Task { await channels.loadMoreIfNeeded(after: channel) } }
                    }
                }
                .padding(.vertical, Spacing.s)
            }
            .scrollClipDisabled()
            .focusSection()
        }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    GuideView(viewModel: GuideViewModel(
        channels: CatalogViewModel(type: .channels, repository: MockCatalogRepository()),
        cache: environment.epgCache
    ))
    .environment(environment.premium)
    .environment(environment.playerPresenter)
}
#endif
