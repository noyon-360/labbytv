// swift-tools-version: 6.0
import PackageDescription

// Wraps the official VideoLAN TVVLCKit (LGPLv2.1) so the app can play
// containers AVPlayer can't (MKV, AVI…). The xcframework is git-ignored;
// run `scripts/fetch-vlckit.sh` from the repo root to download it.
let package = Package(
    name: "LabbyVLC",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "LabbyVLC", targets: ["LabbyVLC"]),
    ],
    targets: [
        .binaryTarget(name: "TVVLCKit", path: "Frameworks/TVVLCKit.xcframework"),
        .target(name: "LabbyVLC", dependencies: ["TVVLCKit"]),
    ]
)
