import SwiftUI

/// Thin watched-progress bar along the bottom of a poster.
struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.6))
                Rectangle().fill(AppColors.accent)
                    .frame(width: proxy.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 8)
    }
}
