import Foundation
import SwiftUI

struct Tag: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var color: String

    init(
        id: UUID = UUID(),
        name: String,
        color: String = "blue"
    ) {
        self.id = id
        self.name = name
        self.color = color
    }

    var swiftUIColor: Color {
        switch color.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }
}
