import Foundation

struct ScheduleState {
    let selectedWeekdays: Set<Weekday>
    
    var orderedWeekdays: [Weekday] {
        selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
    }
}
