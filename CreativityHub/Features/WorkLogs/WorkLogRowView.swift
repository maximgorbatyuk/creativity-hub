import SwiftUI

struct WorkLogRowView: View {
    let workLog: WorkLog
    let checklistItemName: String?

    private var localizedDuration: String {
        let days = workLog.totalMinutes / 1440
        let hours = (workLog.totalMinutes % 1440) / 60
        let minutes = workLog.totalMinutes % 60

        let dayUnit = L("worklog.duration.unit.day_short")
        let hourUnit = L("worklog.duration.unit.hour_short")
        let minuteUnit = L("worklog.duration.unit.minute_short")

        var parts: [String] = []
        if days > 0 { parts.append("\(days)\(dayUnit)") }
        if hours > 0 { parts.append("\(hours)\(hourUnit)") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes)\(minuteUnit)") }
        return parts.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.indigo)
                    .font(.subheadline)

                if let title = workLog.title {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text(localizedDuration)
                        .font(.headline)
                }

                Spacer()

                Text(workLog.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                if workLog.title != nil {
                    Text(localizedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let itemName = checklistItemName {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(itemName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
