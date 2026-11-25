import SwiftUI

/// The TV guide. Premium only (`LABBY TV Pro`), as in the brief.
struct GuideView: View {
    @Environment(PremiumService.self) private var premium
    @Environment(PlayerPresenter.self) private var player
    @Environment(LivePreview.self) private var preview
    @Environment(ChannelFavorites.self) private var favorites
    let viewModel: GuideViewModel
    @FocusState private var focus: GuideFocus?
    @FocusState private var focusedCategory: String?
    @State private var scrollTarget: Int?

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
            if let trial = premium.availableFreeTrial {
                Text("Try it free for \(trial.durationText).")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.success)
            }
            NavigationLink(premium.availableFreeTrial?.buttonLabel ?? "Get LABBY TV Pro", value: AppRoute.paywall)
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 620)
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Plans (and trial eligibility) normally load on the paywall; load
        // them here too so the button can offer the trial.
        .task {
            if premium.packages.isEmpty { try? await premium.loadPackages() }
        }
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.l) {
                GuideMiniPlayer()
                details
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                timeControls
            }
            .frame(height: GuideMiniPlayer.height, alignment: .top)

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ruler
                    rows
                }
                .padding(.leading, CategorySidebar.collapsedWidth + Spacing.m)
                .offset(x: focusedCategory != nil ? CategorySidebar.slideOffset : 0)
                .animation(.easeInOut(duration: 0.25), value: focusedCategory != nil)

                CategorySidebar(
                    categories: viewModel.channels.categories,
                    selected: viewModel.channels.selectedCategory,
                    isLocked: viewModel.channels.isLocked,
                    isExpanded: focusedCategory != nil,
                    focusedCategory: $focusedCategory,
                    onSelect: { category in Task { await viewModel.channels.select(category) } }
                )
                .zIndex(1)
            }
        }
        .task { await viewModel.channels.loadIfNeeded() }
        .task { await viewModel.tickClock() }
        .task { await favorites.loadIfNeeded() }
        .onChange(of: viewModel.channels.parentalLockChangeCount) {
            Task { await viewModel.channels.applyParentalLockChanges() }
        }
        .onChange(of: focus) { old, new in
            handleFocusChange(from: old, to: new)
        }
        .onChange(of: focusedCategory) { old, new in
            if let target = CategoryFocusRule.redirect(from: old, to: new, selected: viewModel.channels.selectedCategory.id) {
                focusedCategory = target
            }
        }
        .onAppear { returnToPlayingChannel() }
        .onChange(of: viewModel.channels.items.first?.id) { old, _ in
            if old == nil && focus == nil && focusedCategory == nil { returnToPlayingChannel() }
        }
        .onChange(of: player.current == nil) {
            if player.current == nil { returnToPlayingChannel() }
        }
        // Leaving the guide (another tab) stops the mini player; going full
        // screen keeps it, because the full-screen player is using it.
        .onDisappear {
            if player.current == nil { preview.stop() }
        }
    }

    /// Select on a channel or the programme on now: first press previews it
    /// in the mini player, a second press on the same channel goes full screen.
    private func select(_ channel: Channel) {
        let lineup = viewModel.channels.items
        if preview.isShowing(channel) {
            player.play(.live(channel, lineup: lineup))
        } else {
            Task { await preview.play(channel, lineup: lineup) }
        }
    }

    private func handleFocusChange(from old: GuideFocus?, to new: GuideFocus?) {
        switch new {
        case .later(let channelID):
            // Right past the last programme in view: slide the guide on and
            // land on the next programme.
            if let target = viewModel.slideForward(channelID: channelID) {
                moveFocus(to: .program(channelID: channelID, programID: target.id))
            } else {
                focus = old
            }
        case .channel(let channelID):
            // Left off the first programme while looking ahead: slide back
            // instead of jumping to the channel column.
            if case .program(let oldChannel, let programID) = old, oldChannel == channelID,
               let target = viewModel.slideBack(from: programID, channelID: channelID) {
                moveFocus(to: .program(channelID: channelID, programID: target.id))
            }
        default:
            break
        }
    }

    /// After the window slides, the target cell only exists once SwiftUI has
    /// laid out the new window; give it a moment before moving focus.
    private func moveFocus(to target: GuideFocus) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            focus = target
        }
    }

    /// Back from full screen: show and focus the channel in the mini player.
    /// Otherwise start on the first channel, not the time buttons.
    private func returnToPlayingChannel() {
        let items = viewModel.channels.items
        let target = preview.channel.flatMap { playing in items.first { $0.id == playing.id } } ?? items.first
        guard let target else { return }
        scrollTarget = target.id
        // tvOS restores its own idea of focus after the full-screen cover
        // closes (it picked the category list), so set ours after that and
        // once more if it was overridden.
        Task { @MainActor in
            for delay in [400, 400] {
                try? await Task.sleep(for: .milliseconds(delay))
                if focus == .channel(target.id) { return }
                focus = .channel(target.id)
            }
        }
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
                        Text(program.description).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary).lineLimit(3)
                    }
                }
            }
        case .channel(let channelID):
            if let channel = viewModel.channels.items.first(where: { $0.id == channelID }) {
                let onNow = viewModel.visiblePrograms(for: channelID).first { $0.isAiring(at: viewModel.now) }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(channel.name).font(AppFonts.headline).lineLimit(1)
                    if let onNow {
                        Text(onNow.title).font(AppFonts.bodyBold).lineLimit(1)
                        Text(DateFormatting.timeRange(onNow.start, onNow.end)).font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                    }
                    Text(preview.isShowing(channel) ? "Press to watch full screen" : "Press to preview · press again for full screen")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.accent)
                }
            }
        case .later, nil:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("TV Guide").font(AppFonts.title)
                Text("← Categories   ·   → Later programmes")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
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
            EmptyStateView(symbol: "tv", title: "No channels", message: channels.selectedCategory == .favorites ? "Press and hold a channel in Live TV, or use the heart in the player, to add favourites." : "Try another category.")
        } else {
            ScrollViewReader { proxy in
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
                                canSlideForward: viewModel.canGoLater,
                                isPreviewing: preview.channel?.id == channel.id,
                                isFavorite: favorites.isFavorite(channel.id),
                                focus: $focus,
                                onPlay: { select(channel) },
                                onRetry: { Task { await viewModel.retryPrograms(for: channel) } }
                            )
                            .id(channel.id)
                            // Lifts the focused row so a growing cell isn't
                            // covered by the row below.
                            .zIndex(focus?.channelID == channel.id ? 1 : 0)
                            .task(id: channel.id) { await viewModel.loadPrograms(for: channel) }
                            .onAppear { Task { await channels.loadMoreIfNeeded(after: channel) } }
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }
                .scrollClipDisabled()
                .focusSection()
                // In the grid, Back opens the categories; on the list it
                // keeps its normal job.
                .onExitCommand(perform: focus == nil ? nil : {
                    focusedCategory = channels.selectedCategory.id
                })
                .onChange(of: scrollTarget) {
                    if let scrollTarget {
                        proxy.scrollTo(scrollTarget, anchor: .center)
                        self.scrollTarget = nil
                    }
                }
            }
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
    .environment(environment.livePreview)
    .environment(environment.channelFavorites)
}
#endif
