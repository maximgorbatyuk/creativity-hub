import SwiftUI

struct IdeaGridItemView: View {
    let idea: Idea

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: idea.sourceType.icon)
                    .font(.caption)
                    .foregroundColor(idea.sourceType.color)

                Text(idea.sourceType.displayName)
                    .font(.caption2)
                    .foregroundColor(idea.sourceType.color)

                Spacer()

                if idea.hasUrl {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(idea.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer()

            if let domain = idea.sourceDomain {
                Text(domain)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(idea.sourceType.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(idea.sourceType.color.opacity(0.15), lineWidth: 1)
        )
    }
}
