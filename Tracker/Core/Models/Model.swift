import Foundation

// MARK: - Tracker

struct Tracker {
    let id: UUID
    let title: String
    let colorHex: String
    let emoji: String
    let schedule: [Weekday]
}

// MARK: - Weekday

enum Weekday: Int, CaseIterable, Codable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

extension Weekday {
    var localizedName: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
    
    static func from(date: Date, calendar: Calendar = Calendar.current) -> Weekday? {
        let weekday = calendar.component(.weekday, from: date)
        let isoWeekday = ((weekday + 5) % 7) + 1
        return Weekday(rawValue: isoWeekday)
    }
}

// MARK: - TrackerCategory

struct TrackerCategory {
    let title: String
    let trackers: [Tracker]
}

// MARK: - TrackerRecord

struct TrackerRecord: Hashable {
    let trackerId: UUID
    let date: Date
}
