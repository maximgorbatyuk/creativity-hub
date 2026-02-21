import SwiftUI

struct WorkLogPreviewRow: View {
    let workLog: WorkLog

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
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.indigo)
                .font(.subheadline)
                .frame(width: 32)

            if let title = workLog.title {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer()

                Text(localizedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(localizedDuration)
                    .font(.subheadline)

                Spacer()

                Text(workLog.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
