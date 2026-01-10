import Foundation

enum TrackerCreationType {
    case habit
    case irregular
    
    var requiresSchedule: Bool {
        switch self {
        case .habit:
            return true
        case .irregular:
            return false
        }
    }
}
