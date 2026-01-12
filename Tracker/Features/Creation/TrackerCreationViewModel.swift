import Foundation

final class TrackerCreationViewModel {
    
    var onStateChange: ((TrackerCreationState) -> Void)?
    private let nameCharacterLimit = 38
    private let editingTracker: Tracker?
    
    private(set) var state: TrackerCreationState {
        didSet {
            onStateChange?(state)
        }
    }
    
    init(type: TrackerCreationType,
         availableCategories: [String] = [],
         editingTracker: Tracker? = nil,
         categoryTitle: String? = nil) {
        self.editingTracker = editingTracker
        self.state = TrackerCreationState(type: type,
                                          name: editingTracker?.title ?? "",
                                          category: categoryTitle,
                                          emoji: editingTracker?.emoji,
                                          colorHex: editingTracker?.colorHex,
                                          schedule: editingTracker?.schedule ?? [],
                                          availableCategories: availableCategories,
                                          nameCharacterLimit: nameCharacterLimit)
    }
    
    func bind() {
        onStateChange?(state)
    }
    
    func updateAvailableCategories(_ categories: [String]) {
        var newState = state
        newState.availableCategories = categories
        state = newState
    }
    
    func updateName(_ name: String) {
        var newState = state
        newState.name = name
        state = newState
    }
    
    func updateCategory(_ category: String, categories: [String]) {
        var newState = state
        newState.category = category
        newState.availableCategories = categories
        state = newState
    }
    
    func updateEmoji(_ emoji: String) {
        var newState = state
        newState.emoji = emoji
        state = newState
    }
    
    func updateColor(hex: String) {
        var newState = state
        newState.colorHex = hex
        state = newState
    }
    
    func updateSchedule(_ schedule: [Weekday]) {
        var newState = state
        newState.schedule = schedule
        state = newState
    }
    
    func makeTracker() -> (tracker: Tracker, categoryTitle: String)? {
        guard state.isValid,
              let category = state.category,
              let emoji = state.emoji,
              let colorHex = state.colorHex else {
            return nil
        }
        
        let trackerId = editingTracker?.id ?? UUID()
        let isPinned = editingTracker?.isPinned ?? false
        let tracker = Tracker(id: trackerId,
                              title: state.trimmedName,
                              colorHex: colorHex,
                              emoji: emoji,
                              schedule: state.schedule,
                              isPinned: isPinned)
        return (tracker, category)
    }
}

