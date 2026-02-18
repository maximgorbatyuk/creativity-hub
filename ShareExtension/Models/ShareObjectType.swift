import Foundation

/// Object types that can be created from shared content.
enum ShareObjectType: String, CaseIterable, Identifiable {
    case idea
    case document
    case note

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idea: return L("share.type.idea")
        case .document: return L("share.type.document")
        case .note: return L("share.type.note")
        }
    }

    var icon: String {
        switch self {
        case .idea: return "lightbulb.fill"
        case .document: return "doc.fill"
        case .note: return "note.text"
        }
    }
}
