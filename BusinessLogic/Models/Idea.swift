import Foundation
import SwiftUI

// MARK: - IdeaSourceType

enum IdeaSourceType: String, Codable, CaseIterable, Identifiable {
    case instagram
    case tiktok
    case pinterest
    case youtube
    case website
    case other

    var id: String { rawValue }

    // Brand names are not wrapped in L() — they are universal and not localized.
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .pinterest: return "Pinterest"
        case .youtube: return "YouTube"
        case .website: return L("idea.source.website")
        case .other: return L("idea.source.other")
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .tiktok: return "play.rectangle.fill"
        case .pinterest: return "pin.fill"
        case .youtube: return "play.tv.fill"
        case .website: return "globe"
        case .other: return "link"
        }
    }

    var color: Color {
        switch self {
        case .instagram: return .purple
        case .tiktok: return .pink
        case .pinterest: return .red
        case .youtube: return .red
        case .website: return .blue
        case .other: return .gray
        }
    }

    static func detect(from url: String) -> IdeaSourceType {
        let lowered = url.lowercased()
        if lowered.contains("instagram.com") || lowered.contains("instagr.am") {
            return .instagram
        } else if lowered.contains("tiktok.com") {
            return .tiktok
        } else if lowered.contains("pinterest.com") || lowered.contains("pin.it") {
            return .pinterest
        } else if lowered.contains("youtube.com") || lowered.contains("youtu.be") {
            return .youtube
        } else if lowered.contains("http") {
            return .website
        }
        return .other
    }
}

// MARK: - Idea

struct Idea: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let projectId: UUID
    var url: String?
    var title: String
    var thumbnailUrl: String?
    var sourceDomain: String?
    var sourceType: IdeaSourceType
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        url: String? = nil,
        title: String,
        thumbnailUrl: String? = nil,
        sourceDomain: String? = nil,
        sourceType: IdeaSourceType = .other,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.url = url
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.sourceDomain = sourceDomain
        self.sourceType = sourceType
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasUrl: Bool {
        guard let url = url else { return false }
        return !url.isEmpty
    }

    var hasNotes: Bool {
        guard let notes = notes else { return false }
        return !notes.isEmpty
    }

    var notesPreview: String? {
        guard let notes = notes, !notes.isEmpty else { return nil }
        let maxLength = 100
        if notes.count <= maxLength { return notes }
        return String(notes.prefix(maxLength)) + "..."
    }
}
