import Foundation

struct StatsMetric {
    let title: String
    let value: String
}

struct StatsState {
    let metrics: [StatsMetric]
    
    var hasData: Bool {
        metrics.isEmpty == false
    }
}

final class StatsViewModel: TrackerRecordStoreDelegate {
    
    var onStateChange: ((StatsState) -> Void)?
    
    private let recordStore: TrackerRecordStore
    private let calendar: Calendar
    private(set) var state: StatsState {
        didSet {
            onStateChange?(state)
        }
    }
    
    init(recordStore: TrackerRecordStore = TrackerRecordStore(),
         calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.recordStore = recordStore
        self.calendar = calendar
        self.state = StatsState(metrics: [])
        self.recordStore.delegate = self
    }
    
    func start() {
        updateState()
    }
    
    private func updateState() {
        let records = recordStore.records
        guard records.isEmpty == false else {
            state = StatsState(metrics: [])
            return
        }
        
        let completions = records.count
        let uniqueDays = uniqueCompletionDays(from: records)
        let bestPeriod = longestStreak(from: uniqueDays)
        let perfectDays = uniqueDays.count
        let uniqueTrackers = Set(records.map { $0.trackerId }).count
        let average = Double(completions) / Double(max(perfectDays, 1))
        
        let metrics = [
            StatsMetric(title: NSLocalizedString("Лучший период", comment: "Stats best period"), value: "\(bestPeriod)"),
            StatsMetric(title: NSLocalizedString("Идеальные дни", comment: "Stats perfect days"), value: "\(perfectDays)"),
            StatsMetric(title: NSLocalizedString("Трекеров завершено", comment: "Stats trackers completed"), value: "\(uniqueTrackers)"),
            StatsMetric(title: NSLocalizedString("Среднее значение", comment: "Stats average"), value: String(format: "%.0f", average))
        ]
        
        state = StatsState(metrics: metrics)
    }
    
    private func uniqueCompletionDays(from records: [TrackerRecord]) -> [Date] {
        let days = Set(records.map { calendar.startOfDay(for: $0.date) })
        return days.sorted()
    }
    
    private func longestStreak(from days: [Date]) -> Int {
        guard days.isEmpty == false else { return 0 }
        var longest = 1
        var current = 1
        for index in 1..<days.count {
            let previous = days[index - 1]
            let currentDay = days[index]
            if let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: currentDay) {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }
        return max(longest, current)
    }
    
    func trackerRecordStoreDidChange(_ store: TrackerRecordStore) {
        updateState()
    }
}

