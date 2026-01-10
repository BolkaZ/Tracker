import Foundation

struct TrackersViewState {
    let sections: [TrackersViewModel.Section]
    let hasTrackers: Bool
}

final class TrackersViewModel: NSObject {
    
    struct Section {
        let title: String
        let trackers: [Tracker]
    }
    
    struct CellViewModel {
        let tracker: Tracker
        let daysText: String
        let colorHex: String
        let isCompleted: Bool
        let isButtonEnabled: Bool
    }
    
    var onStateChange: ((TrackersViewState) -> Void)?
    var onRecordsUpdated: (() -> Void)?
    
    private let trackerStore: TrackerStore
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    private let calendar: Calendar
    
    private var searchQuery: String = ""
    private(set) var currentDate: Date
    
    private(set) var state: TrackersViewState {
        didSet {
            onStateChange?(state)
        }
    }
    
    init(trackerStore: TrackerStore = TrackerStore(),
         categoryStore: TrackerCategoryStore = TrackerCategoryStore(),
         recordStore: TrackerRecordStore = TrackerRecordStore(),
         calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.trackerStore = trackerStore
        self.categoryStore = categoryStore
        self.recordStore = recordStore
        self.calendar = calendar
        self.currentDate = calendar.startOfDay(for: Date())
        self.state = TrackersViewState(sections: [], hasTrackers: false)
        super.init()
        self.trackerStore.delegate = self
        self.categoryStore.delegate = self
        self.recordStore.delegate = self
    }
    
    func start() {
        currentDate = normalized(date: Date())
        applyFilters()
    }
    
    func updateSearch(query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        applyFilters()
    }
    
    func updateDate(_ date: Date) {
        currentDate = normalized(date: date)
        applyFilters()
    }
    
    func numberOfSections() -> Int {
        state.sections.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard section < state.sections.count else { return 0 }
        return state.sections[section].trackers.count
    }
    
    func sectionTitle(for section: Int) -> String? {
        guard section < state.sections.count else { return nil }
        return state.sections[section].title
    }
    
    func tracker(section: Int, item: Int) -> Tracker? {
        guard section < state.sections.count else { return nil }
        let trackers = state.sections[section].trackers
        guard item < trackers.count else { return nil }
        return trackers[item]
    }
    
    func cellViewModel(section: Int, item: Int) -> CellViewModel? {
        guard let tracker = tracker(section: section, item: item) else { return nil }
        let normalizedDate = normalized(date: currentDate)
        let isCompleted = recordStore.isCompleted(trackerId: tracker.id, date: normalizedDate)
        let count = completedCount(for: tracker)
        let text = formattedDaysText(for: count)
        let colorHex = tracker.colorHex
        let enabled = !isFuture(date: normalizedDate)
        return CellViewModel(tracker: tracker,
                             daysText: text,
                             colorHex: colorHex,
                             isCompleted: isCompleted,
                             isButtonEnabled: enabled)
    }
    
    func toggleCompletion(for tracker: Tracker) {
        let normalizedDate = normalized(date: currentDate)
        do {
            if recordStore.isCompleted(trackerId: tracker.id, date: normalizedDate) {
                try recordStore.removeRecord(trackerId: tracker.id, date: normalizedDate)
            } else {
                try recordStore.addRecord(trackerId: tracker.id, date: normalizedDate)
            }
        } catch {
            assertionFailure("Failed to toggle tracker completion: \(error)")
        }
    }
    
    func availableCategoryTitles() -> [String] {
        categoryStore.categories.map { $0.title }
    }
    
    func createTracker(_ tracker: Tracker, in categoryTitle: String) {
        do {
            if categoryStore.categories.contains(where: { $0.title.caseInsensitiveCompare(categoryTitle) == .orderedSame }) == false {
                try categoryStore.createCategory(title: categoryTitle)
            }
            try trackerStore.createTracker(tracker, in: categoryTitle)
            applyFilters()
        } catch {
            assertionFailure("Failed to create tracker: \(error)")
        }
    }
    
    private func applyFilters() {
        guard let weekday = Weekday.from(date: currentDate, calendar: calendar) else {
            state = TrackersViewState(sections: [], hasTrackers: false)
            return
        }
        
        let normalizedSearch = searchQuery.lowercased()
        let categories = categoryStore.categories
        
        let sections = categories.compactMap { category -> Section? in
            let trackers = category.trackers.filter { tracker in
                let matchesSearch = normalizedSearch.isEmpty
                || tracker.title.lowercased().contains(normalizedSearch)
                let matchesSchedule = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
                return matchesSearch && matchesSchedule
            }
            guard trackers.isEmpty == false else { return nil }
            return Section(title: category.title, trackers: trackers)
        }
        
        state = TrackersViewState(sections: sections, hasTrackers: sections.flatMap { $0.trackers }.isEmpty == false)
    }
    
    private func normalized(date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    private func completedCount(for tracker: Tracker) -> Int {
        recordStore.records.filter { $0.trackerId == tracker.id }.count
    }
    
    private func formattedDaysText(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        let suffix: String
        if remainder100 >= 11 && remainder100 <= 14 {
            suffix = "дней"
        } else {
            switch remainder10 {
            case 1:
                suffix = "день"
            case 2...4:
                suffix = "дня"
            default:
                suffix = "дней"
            }
        }
        return "\(count) \(suffix)"
    }
    
    private func isFuture(date: Date) -> Bool {
        let today = normalized(date: Date())
        return date > today
    }
}

// MARK: - Store Delegates

extension TrackersViewModel: TrackerStoreDelegate {
    func trackerStoreDidChange(_ store: TrackerStore) {
        applyFilters()
    }
}

extension TrackersViewModel: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidChange(_ store: TrackerCategoryStore) {
        applyFilters()
    }
}

extension TrackersViewModel: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidChange(_ store: TrackerRecordStore) {
        onRecordsUpdated?()
    }
}

