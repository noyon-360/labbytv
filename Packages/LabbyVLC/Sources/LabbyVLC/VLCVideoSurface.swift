import SwiftUI
import UIKit

/// The video picture for a `VLCPlaybackEngine`. Hosts the engine's own
/// video view (VLC needs it before playback starts). Not focusable: the
/// controls and remote handling live in the app's SwiftUI layer.
public struct VLCVideoSurface: UIViewRepresentable {
    let engine: VLCPlaybackEngine

    public init(engine: VLCPlaybackEngine) {
        self.engine = engine
    }

    public func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        container.isUserInteractionEnabled = false
        let video = engine.videoView
        video.removeFromSuperview()
        video.frame = container.bounds
        video.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(video)
        return container
    }

    public func updateUIView(_ view: UIView, context: Context) {}
}
