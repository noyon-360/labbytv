import SwiftUI

/// `AsyncImage` with a neutral placeholder. Responses are cached by the
/// shared `URLCache`, which `LabbyTVApp` enlarges at launch.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var placeholderSymbol = "photo"

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            default:
                ZStack {
                    AppColors.surface
                    Image(systemName: placeholderSymbol)
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.surfaceRaised)
                }
            }
        }
    }
}
