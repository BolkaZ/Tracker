import Foundation

enum TrackersFilter: String, CaseIterable {
    case all
    case today
    case completed
    case uncompleted
    
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("Все трекеры", comment: "Filter: all")
        case .today:
            return NSLocalizedString("Трекеры на сегодня", comment: "Filter: today")
        case .completed:
            return NSLocalizedString("Завершённые", comment: "Filter: completed")
        case .uncompleted:
            return NSLocalizedString("Незавершённые", comment: "Filter: uncompleted")
        }
    }
    
    var showsCheckmark: Bool {
        switch self {
        case .completed, .uncompleted:
            return true
        case .all, .today:
            return false
        }
    }
    
    var isActive: Bool {
        switch self {
        case .completed, .uncompleted:
            return true
        case .all, .today:
            return false
        }
    }
}
