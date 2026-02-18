import SwiftUI

struct ChecklistRowView: View {
    let checklist: Checklist
    let progress: (checked: Int, total: Int)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(checklist.name)
                    .font(.body)
                    .lineLimit(1)

                if progress.total > 0 {
                    progressLabel
                }
            }

            Spacer()

            if progress.total > 0 {
                progressRing
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var progressLabel: some View {
        Text(L("checklist.progress", progress.checked, progress.total))
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 3)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))

            Text("\(percentComplete)%")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private var progressValue: CGFloat {
        guard progress.total > 0 else { return 0 }
        return CGFloat(progress.checked) / CGFloat(progress.total)
    }

    private var percentComplete: Int {
        guard progress.total > 0 else { return 0 }
        return Int(Double(progress.checked) / Double(progress.total) * 100)
    }

    private var progressColor: Color {
        if progress.checked == progress.total { return .green }
        return .accentColor
    }
}
