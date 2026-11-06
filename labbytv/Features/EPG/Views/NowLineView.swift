import SwiftUI

/// The red "now" marker drawn across a guide row.
struct NowLineView: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.nowLine)
            .frame(width: 4)
            .shadow(color: AppColors.nowLine.opacity(0.6), radius: 6)
            .accessibilityHidden(true)
    }
}

#Preview {
    NowLineView().frame(height: 100).padding().background(AppColors.background)
}
