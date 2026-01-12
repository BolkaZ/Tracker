import Foundation

struct TrackerCreationState {
    let type: TrackerCreationType
    var name: String
    var category: String?
    var emoji: String?
    var colorHex: String?
    var schedule: [Weekday]
    var availableCategories: [String]
    let nameCharacterLimit: Int
    
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNameValid: Bool {
        trimmedName.isEmpty == false
    }

    var isNameLengthValid: Bool {
        name.count <= nameCharacterLimit
    }

    var shouldShowNameLimitWarning: Bool {
        name.count >= nameCharacterLimit
    }
    
    var isScheduleValid: Bool {
        type.requiresSchedule ? schedule.isEmpty == false : true
    }
    
    var isValid: Bool {
        isNameValid
        && isNameLengthValid
        && category != nil
        && emoji != nil
        && colorHex != nil
        && isScheduleValid
    }
    
    var scheduleSummary: String? {
        guard type.requiresSchedule, isScheduleValid else { return nil }
        if schedule.count == Weekday.allCases.count {
            return NSLocalizedString("Каждый день", comment: "Every day schedule summary")
        }
        let sorted = schedule.sorted { $0.rawValue < $1.rawValue }
        return sorted.map { $0.shortTitle }.joined(separator: ", ")
    }

    var nameLimitText: String {
        String(
            format: NSLocalizedString("Ограничение %d символов", comment: "Name character limit format"),
            nameCharacterLimit
        )
    }
}
