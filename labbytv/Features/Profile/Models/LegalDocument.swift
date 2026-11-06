import Foundation

/// Same text as the Flutter app's Privacy Policy and Terms screens.
nonisolated enum LegalDocument: String, Identifiable, Hashable, CaseIterable, Sendable {
    case privacy
    case terms
    case licenses

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: "Privacy Policy"
        case .terms: "Terms & Conditions"
        case .licenses: "Open Source Licenses"
        }
    }

    static let lastUpdated = "Last updated: January 27, 2026"

    var sections: [(heading: String, body: String)] {
        switch self {
        case .privacy:
            [
                ("1. Information Collection", "We collect information that you provide directly to us when you create an account, use our services, or communicate with us."),
                ("2. How We Use Information", "We use the information we collect to provide, maintain, and improve our services, develop new ones, and protect LABBY TV and our users."),
                ("3. Information Sharing", "We do not share your personal information with companies, organizations, or individuals outside of LABBY TV except in the following cases: with your consent, for external processing, or for legal reasons."),
                ("4. Data Security", "We work hard to protect LABBY TV and our users from unauthorized access to or unauthorized alteration, disclosure, or destruction of information we hold."),
                ("5. Your Choices", "You have choices regarding the information we collect and how it is used. You can access and update your information through your account settings."),
            ]
        case .terms:
            [
                ("1. Acceptance of Terms", "By accessing or using LABBY TV, you agree to be bound by these Terms and Conditions and all applicable laws and regulations."),
                ("2. Use License", "Permission is granted to temporarily download one copy of the materials (information or software) on LABBY TV for personal, non-commercial transitory viewing only."),
                ("3. Disclaimer", "The materials on LABBY TV are provided on an \"as is\" basis. LABBY TV makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties."),
                ("4. Limitations", "In no event shall LABBY TV or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials."),
                ("5. Governing Law", "These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location."),
            ]
        case .licenses:
            [
                ("VLCKit (TVVLCKit)", "Movies and series in formats Apple TV can't play natively are played with VLCKit by VideoLAN and the VLC authors, licensed under the GNU Lesser General Public License, version 2.1 (LGPLv2.1). The library is used unmodified and linked dynamically. Its source code is available at code.videolan.org/videolan/VLCKit, and the licence text at gnu.org/licenses/old-licenses/lgpl-2.1.html."),
            ]
        }
    }

    var closing: String {
        switch self {
        case .privacy: "If you have any questions about this Privacy Policy, please contact us."
        case .terms: "If you do not agree with any of these terms, you are prohibited from using or accessing this site."
        case .licenses: "Thank you to the VideoLAN community."
        }
    }
}
