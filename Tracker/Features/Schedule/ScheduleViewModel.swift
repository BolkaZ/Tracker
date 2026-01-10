import Foundation

final class ScheduleViewModel {
    
    var onStateChange: ((ScheduleState) -> Void)?
    
    private(set) var state: ScheduleState {
        didSet {
            onStateChange?(state)
        }
    }
    
    init(selectedWeekdays: Set<Weekday>) {
        self.state = ScheduleState(selectedWeekdays: selectedWeekdays)
    }
    
    func bind() {
        onStateChange?(state)
    }
    
    func set(_ weekday: Weekday, isSelected: Bool) {
        var updated = state.selectedWeekdays
        if isSelected {
            updated.insert(weekday)
        } else {
            updated.remove(weekday)
        }
        state = ScheduleState(selectedWeekdays: updated)
    }
    
    func isSelected(_ weekday: Weekday) -> Bool {
        state.selectedWeekdays.contains(weekday)
    }
    
    func selectedWeekdaysList() -> [Weekday] {
        state.orderedWeekdays
    }
}

