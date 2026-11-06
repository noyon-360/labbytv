#if canImport(LabbyVLC)
import LabbyVLC
import SwiftUI

/// Playback screen for VLC streams. VLC has no tvOS transport bar, so this
/// gives the Siri Remote the same basics: Play/Pause, click left/right to
/// skip 10 s, click to show controls, Audio and Subtitles menus, and
/// Menu/Back to hide the controls and then close.
struct VLCPlayerView: View {
    let engine: VLCPlaybackEngine
    let title: String
    let onClose: () -> Void

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var showingAudio = false
    @State private var showingSubtitles = false
    @FocusState private var focus: ControlFocus?

    private enum ControlFocus: Hashable {
        case catcher, back, playPause, forward, audio, subtitles
    }

    private static let skip: Double = 10

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCVideoSurface(engine: engine)
                .ignoresSafeArea()

            if engine.status == .opening || engine.status == .buffering {
                ProgressView().scaleEffect(1.5)
            }

            if controlsVisible {
                controls
                    .transition(.opacity)
            } else {
                // Invisible, full-screen focus target so the remote still
                // works while the controls are hidden.
                Button(action: showControls) { Color.clear }
                    .buttonStyle(InvisibleButtonStyle())
                    .focused($focus, equals: .catcher)
                    .onMoveCommand { direction in
                        switch direction {
                        case .left: engine.jump(by: -Self.skip)
                        case .right: engine.jump(by: Self.skip)
                        default: break
                        }
                        showControls()
                    }
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
        .onPlayPauseCommand {
            engine.togglePlayPause()
            showControls()
        }
        .onExitCommand {
            if controlsVisible {
                hideControls()
            } else {
                onClose()
            }
        }
        .onChange(of: focus) { scheduleHide() }
        .onAppear(perform: showControls)
        .onDisappear { hideTask?.cancel() }
        .confirmationDialog("Audio", isPresented: $showingAudio) {
            ForEach(engine.audioTracks) { track in
                Button(label(track.name, selected: track.id == engine.selectedAudioTrack)) {
                    engine.selectAudioTrack(track.id)
                }
            }
        }
        .confirmationDialog("Subtitles", isPresented: $showingSubtitles) {
            ForEach(engine.subtitleTracks) { track in
                Button(label(track.name, selected: track.id == engine.selectedSubtitleTrack)) {
                    engine.selectSubtitleTrack(track.id)
                }
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Spacer()
            Text(title)
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            HStack(spacing: Spacing.m) {
                Text(Self.format(engine.currentTime))
                ProgressBar(value: engine.duration > 0 ? engine.currentTime / engine.duration : 0)
                    .clipShape(Capsule())
                Text(engine.duration > 0 ? "-" + Self.format(max(0, engine.duration - engine.currentTime)) : "--:--")
            }
            .font(AppFonts.caption.monospacedDigit())
            .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: Spacing.m) {
                controlButton("gobackward.10", focus: .back) { engine.jump(by: -Self.skip) }
                controlButton(engine.status == .playing ? "pause.fill" : "play.fill", focus: .playPause) { engine.togglePlayPause() }
                controlButton("goforward.10", focus: .forward) { engine.jump(by: Self.skip) }
                Spacer()
                if engine.audioTracks.count > 1 {
                    Button { showingAudio = true } label: { Label("Audio", systemImage: "speaker.wave.2") }
                        .buttonStyle(SecondaryButtonStyle())
                        .focused($focus, equals: .audio)
                }
                if !engine.subtitleTracks.isEmpty {
                    Button { showingSubtitles = true } label: { Label("Subtitles", systemImage: "captions.bubble") }
                        .buttonStyle(SecondaryButtonStyle())
                        .focused($focus, equals: .subtitles)
                }
            }
            .focusSection()
        }
        .padding(Spacing.xl)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .defaultFocus($focus, .playPause)
    }

    private func controlButton(_ symbol: String, focus value: ControlFocus, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 34, weight: .semibold)).frame(width: 60)
        }
        .buttonStyle(SecondaryButtonStyle())
        .focused($focus, equals: value)
    }

    private func label(_ name: String, selected: Bool) -> String {
        selected ? "✓ \(name)" : name
    }

    private func showControls() {
        controlsVisible = true
        if focus == nil || focus == .catcher { focus = .playPause }
        scheduleHide()
    }

    private func hideControls() {
        hideTask?.cancel()
        controlsVisible = false
        focus = .catcher
    }

    /// Hide after 5 s without input, unless paused (people read the time then).
    private func scheduleHide() {
        hideTask?.cancel()
        guard controlsVisible else { return }
        hideTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, engine.status == .playing, !showingAudio, !showingSubtitles else { return }
            hideControls()
        }
    }

    /// "1:02:03" or "2:03".
    static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
#endif
