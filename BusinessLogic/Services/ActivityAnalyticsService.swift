import Foundation

struct ActivityChartPoint: Identifiable, Equatable {
    let date: Date
    let count: Int

    var id: Date { date }
}

final class ActivityAnalyticsService {
    static let shared = ActivityAnalyticsService()

    private var repository: ActivityLogRepository? {
        DatabaseManager.shared.activityLogRepository
    }

    private init() {}

    func weeklyActivityCounts(projectId: UUID, months: Int = 6, referenceDate: Date = Date()) -> [ActivityChartPoint] {
        guard months > 0 else { return [] }

        let calendar = Calendar.current
        let endWeekStart = startOfWeek(for: referenceDate)
        guard let periodStart = calendar.date(byAdding: .month, value: -months, to: referenceDate) else {
            return []
        }

        let startWeekStart = startOfWeek(for: periodStart)
        return weeklyActivityCounts(projectId: projectId, from: startWeekStart, to: endWeekStart)
    }

    func weeklyActivityCounts(projectId: UUID, from startDate: Date, to endDate: Date) -> [ActivityChartPoint] {
        let calendar = Calendar.current
        let startWeek = startOfWeek(for: startDate)
        let endWeek = startOfWeek(for: endDate)

        guard startWeek <= endWeek,
              let weekAfterEnd = calendar.date(byAdding: .day, value: 7, to: endWeek)
        else {
            return []
        }

        let dailyCounts = repository?.fetchDailyCountsByProjectId(
            projectId: projectId,
            since: startWeek,
            until: weekAfterEnd
        ) ?? [:]

        var weeklyMap: [Date: Int] = [:]
        for (day, count) in dailyCounts {
            let weekStart = startOfWeek(for: day)
            weeklyMap[weekStart, default: 0] += count
        }

        var points: [ActivityChartPoint] = []
        var currentWeek = startWeek
        while currentWeek <= endWeek {
            points.append(ActivityChartPoint(date: currentWeek, count: weeklyMap[currentWeek, default: 0]))
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentWeek) else { break }
            currentWeek = nextWeek
        }

        return points
    }

    func biweeklyActivityCounts(projectId: UUID, months: Int = 6, referenceDate: Date = Date()) -> [ActivityChartPoint] {
        guard months > 0 else { return [] }

        let calendar = Calendar.current
        let endPeriodStart = startOfWeek(for: referenceDate)
        guard let periodStart = calendar.date(byAdding: .month, value: -months, to: referenceDate) else {
            return []
        }

        let startPeriodStart = startOfWeek(for: periodStart)

        guard startPeriodStart <= endPeriodStart,
              let dayAfterEnd = calendar.date(byAdding: .day, value: 14, to: endPeriodStart)
        else {
            return []
        }

        let dailyCounts = repository?.fetchDailyCountsByProjectId(
            projectId: projectId,
            since: startPeriodStart,
            until: dayAfterEnd
        ) ?? [:]

        // Build biweekly buckets starting from startPeriodStart
        var buckets: [(date: Date, count: Int)] = []
        var bucketStart = startPeriodStart

        while bucketStart <= endPeriodStart {
            var bucketCount = 0
            for dayOffset in 0..<14 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: bucketStart) else { continue }
                bucketCount += dailyCounts[day, default: 0]
            }
            buckets.append((date: bucketStart, count: bucketCount))
            guard let nextBucket = calendar.date(byAdding: .day, value: 14, to: bucketStart) else { break }
            bucketStart = nextBucket
        }

        return buckets.map { ActivityChartPoint(date: $0.date, count: $0.count) }
    }

    func dailyActivityCounts(projectId: UUID, days: Int = 30, referenceDate: Date = Date()) -> [ActivityChartPoint] {
        guard days > 0 else { return [] }

        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: referenceDate)
        guard let startDay = calendar.date(byAdding: .day, value: -(days - 1), to: endDay),
              let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: endDay)
        else {
            return []
        }

        let countsByDay = repository?.fetchDailyCountsByProjectId(
            projectId: projectId,
            since: startDay,
            until: dayAfterEnd
        ) ?? [:]

        var points: [ActivityChartPoint] = []
        points.reserveCapacity(days)

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            points.append(ActivityChartPoint(date: day, count: countsByDay[day, default: 0]))
        }

        return points
    }

    func dailyActivityCounts(projectId: UUID, from startDate: Date, to endDate: Date) -> [ActivityChartPoint] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        guard startDay <= endDay,
              let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: endDay)
        else {
            return []
        }

        let countsByDay = repository?.fetchDailyCountsByProjectId(
            projectId: projectId,
            since: startDay,
            until: dayAfterEnd
        ) ?? [:]

        var points: [ActivityChartPoint] = []
        var currentDay = startDay

        while currentDay <= endDay {
            points.append(ActivityChartPoint(date: currentDay, count: countsByDay[currentDay, default: 0]))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = next
        }

        return points
    }

    private func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return calendar.startOfDay(for: interval.start)
        }
        return calendar.startOfDay(for: date)
    }
}
