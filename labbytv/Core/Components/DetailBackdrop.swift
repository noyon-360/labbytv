import SwiftUI

/// Dimmed full-bleed artwork behind detail pages. Decorative only; the
/// content on top stays inside the safe area.
struct DetailBackdrop: View {
    let url: URL?

    var body: some View {
        RemoteImage(url: url, placeholderSymbol: "photo")
            .blur(radius: 30)
            .overlay(
                LinearGradient(
                    colors: [AppColors.background.opacity(0.6), AppColors.background.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
