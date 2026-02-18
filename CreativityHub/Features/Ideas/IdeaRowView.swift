import SwiftUI

struct IdeaRowView: View {
    let idea: Idea

    var body: some View {
        HStack(spacing: 12) {
            sourceIcon
            ideaInfo
            Spacer()
            trailingIndicators
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var sourceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(idea.sourceType.color.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: idea.sourceType.icon)
                .font(.body)
                .foregroundColor(idea.sourceType.color)
        }
    }

    private var ideaInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(idea.title)
                .font(.body)
                .lineLimit(2)

            if let url = idea.url, !url.isEmpty {
                Text(idea.sourceDomain ?? url)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .lineLimit(1)
            }

            if let preview = idea.notesPreview {
                Text(preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var trailingIndicators: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(idea.sourceType.displayName)
                .font(.caption2)
                .foregroundColor(idea.sourceType.color)

            if idea.hasUrl {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
