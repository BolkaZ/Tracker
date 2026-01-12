import Foundation

// MARK: - Tracker

struct Tracker {
    let id: UUID
    let title: String
    let colorHex: String
    let emoji: String
    let schedule: [Weekday]
    let isPinned: Bool
    
    init(id: UUID,
         title: String,
         colorHex: String,
         emoji: String,
         schedule: [Weekday],
         isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.emoji = emoji
        self.schedule = schedule
        self.isPinned = isPinned
    }
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

enum Localizable {
    enum Weekday {
        static let monday = NSLocalizedString("Понедельник", comment: "Weekday Monday")
        static let tuesday = NSLocalizedString("Вторник", comment: "Weekday Tuesday")
        static let wednesday = NSLocalizedString("Среда", comment: "Weekday Wednesday")
        static let thursday = NSLocalizedString("Четверг", comment: "Weekday Thursday")
        static let friday = NSLocalizedString("Пятница", comment: "Weekday Friday")
        static let saturday = NSLocalizedString("Суббота", comment: "Weekday Saturday")
        static let sunday = NSLocalizedString("Воскресенье", comment: "Weekday Sunday")
    }
    
    enum WeekdayShort {
        static let monday = NSLocalizedString("Пн", comment: "Weekday short Monday")
        static let tuesday = NSLocalizedString("Вт", comment: "Weekday short Tuesday")
        static let wednesday = NSLocalizedString("Ср", comment: "Weekday short Wednesday")
        static let thursday = NSLocalizedString("Чт", comment: "Weekday short Thursday")
        static let friday = NSLocalizedString("Пт", comment: "Weekday short Friday")
        static let saturday = NSLocalizedString("Сб", comment: "Weekday short Saturday")
        static let sunday = NSLocalizedString("Вс", comment: "Weekday short Sunday")
    }
}

extension Weekday {
    var localizedName: String {
        switch self {
        case .monday: Localizable.Weekday.monday
        case .tuesday: Localizable.Weekday.tuesday
        case .wednesday: Localizable.Weekday.wednesday
        case .thursday: Localizable.Weekday.thursday
        case .friday: Localizable.Weekday.friday
        case .saturday: Localizable.Weekday.saturday
        case .sunday: Localizable.Weekday.sunday
        }
    }
    
    var shortTitle: String {
        switch self {
        case .monday: Localizable.WeekdayShort.monday
        case .tuesday: Localizable.WeekdayShort.tuesday
        case .wednesday: Localizable.WeekdayShort.wednesday
        case .thursday: Localizable.WeekdayShort.thursday
        case .friday: Localizable.WeekdayShort.friday
        case .saturday: Localizable.WeekdayShort.saturday
        case .sunday: Localizable.WeekdayShort.sunday
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
