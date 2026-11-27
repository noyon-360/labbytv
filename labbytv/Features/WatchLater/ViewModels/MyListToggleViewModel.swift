import Foundation
import Observation

/// The "My List" button on a movie or series page.
@MainActor
@Observable
final class MyListToggleViewModel {
    private(set) var isSaved = false
    private(set) var isBusy = false
    /// Hidden until the status is known, so it never shows the wrong state.
    private(set) var isKnown = false

    @ObservationIgnored private let myList: MyList
    @ObservationIgnored private let videoType: String
    @ObservationIgnored private let videoID: String
    @ObservationIgnored private var savedID: String?

    init(myList: MyList, videoType: String, videoID: String) {
        self.myList = myList
        self.videoType = videoType
        self.videoID = videoID
    }

    func load() async {
        guard let status = await myList.status(videoType: videoType, videoID: videoID) else { return }
        isSaved = status.isSaved
        savedID = status.id
        isKnown = true
    }

    /// Flips at once and flips back if the call fails.
    func toggle(title: String, thumbnail: String) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let wasSaved = isSaved
        isSaved = !wasSaved
        if wasSaved {
            guard let savedID else { isSaved = wasSaved; return }
            if await myList.remove(id: savedID) {
                self.savedID = nil
            } else {
                isSaved = wasSaved
            }
        } else if let id = await myList.add(videoType: videoType, videoID: videoID, title: title, thumbnail: thumbnail.isEmpty ? nil : thumbnail) {
            savedID = id
        } else {
            isSaved = wasSaved
        }
    }
}
