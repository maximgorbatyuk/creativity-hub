import SwiftUI

struct DocumentRowView: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            fileIcon
            documentInfo
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: document.fileType.icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
        }
    }

    private var documentInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.displayName)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)

            if document.name != nil, !document.name!.isEmpty {
                Text(document.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                HStack(spacing: 8) {
                    Text(document.fileType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(document.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var iconColor: Color {
        switch document.fileType {
        case .pdf: return .red
        case .jpeg, .png, .heic: return .blue
        case .other: return .gray
        }
    }
}
