import Foundation

final class CreateTrackerTypeViewModel {
    
    private var categories: [String]
    
    init(categories: [String]) {
        self.categories = categories
    }
    
    func updateCategories(_ categories: [String]) {
        self.categories = categories
    }
    
    func habitsViewModel() -> TrackerCreationViewModel {
        TrackerCreationViewModel(type: .habit, availableCategories: categories)
    }
    
    func irregularViewModel() -> TrackerCreationViewModel {
        TrackerCreationViewModel(type: .irregular, availableCategories: categories)
    }
    
    func availableCategories() -> [String] {
        categories
    }
}

