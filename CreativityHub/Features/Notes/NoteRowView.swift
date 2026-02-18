import SwiftUI

struct NoteRowView: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            noteIcon
            noteInfo
            Spacer()
            trailingInfo
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var noteIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                .font(.body)
                .foregroundColor(.orange)
        }
    }

    private var noteInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(note.title)
                .font(.body)
                .fontWeight(note.isPinned ? .semibold : .regular)
                .lineLimit(2)

            if note.hasContent {
                Text(note.contentPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(note.updatedAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)

            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}
