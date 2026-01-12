import Foundation

struct TrackersViewState {
    enum EmptyReason {
        case none
        case noTrackersForDate
        case noResults
    }
    
    let sections: [TrackersViewModel.Section]
    let hasTrackers: Bool
    let hasAnyTrackersForDate: Bool
    let filter: TrackersFilter
    let emptyReason: EmptyReason
    
    var isFilterActive: Bool {
        filter.isActive
    }
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
    private(set) var selectedFilter: TrackersFilter = .all
    
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
        self.state = TrackersViewState(
            sections: [],
            hasTrackers: false,
            hasAnyTrackersForDate: false,
            filter: .all,
            emptyReason: .noTrackersForDate
        )
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
    
    func selectFilter(_ filter: TrackersFilter) {
        selectedFilter = filter
        if filter == .today {
            currentDate = normalized(date: Date())
        }
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
    
    func categoryTitle(for tracker: Tracker) -> String? {
        trackerStore.categoryTitle(for: tracker.id)
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
    
    func updateTracker(_ tracker: Tracker, in categoryTitle: String) {
        do {
            if categoryStore.categories.contains(where: { $0.title.caseInsensitiveCompare(categoryTitle) == .orderedSame }) == false {
                try categoryStore.createCategory(title: categoryTitle)
            }
            try trackerStore.updateTracker(tracker, in: categoryTitle)
            applyFilters()
        } catch {
            assertionFailure("Failed to update tracker: \(error)")
        }
    }
    
    func togglePin(for tracker: Tracker) {
        do {
            try trackerStore.updatePinStatus(trackerId: tracker.id, isPinned: tracker.isPinned == false)
        } catch {
            assertionFailure("Failed to update pin status: \(error)")
        }
    }
    
    func deleteTracker(_ tracker: Tracker) {
        do {
            try trackerStore.deleteTracker(with: tracker.id)
        } catch {
            assertionFailure("Failed to delete tracker: \(error)")
        }
    }
    
    private func applyFilters() {
        guard let weekday = Weekday.from(date: currentDate, calendar: calendar) else {
            state = TrackersViewState(
                sections: [],
                hasTrackers: false,
                hasAnyTrackersForDate: false,
                filter: selectedFilter,
                emptyReason: .noTrackersForDate
            )
            return
        }
        
        let normalizedDate = normalized(date: currentDate)
        let normalizedSearch = searchQuery.lowercased()
        let categories = categoryStore.categories
        
        let matchesTracker: (Tracker) -> Bool = { tracker in
            let matchesSearch = normalizedSearch.isEmpty
            || tracker.title.lowercased().contains(normalizedSearch)
            let matchesSchedule = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
            
            guard matchesSearch && matchesSchedule else { return false }
            
            switch self.selectedFilter {
            case .all, .today:
                return true
            case .completed:
                return self.recordStore.isCompleted(trackerId: tracker.id, date: normalizedDate)
            case .uncompleted:
                return self.recordStore.isCompleted(trackerId: tracker.id, date: normalizedDate) == false
            }
        }
        
        let hasAnyTrackersForDate = categories.contains { category in
            category.trackers.contains { tracker in
                tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
            }
        }
        
        let pinnedTrackers = categories
            .flatMap { $0.trackers }
            .filter { $0.isPinned && matchesTracker($0) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        let pinnedSection: Section? = pinnedTrackers.isEmpty
        ? nil
        : Section(title: NSLocalizedString("Закрепленные", comment: "Pinned trackers category title"),
                  trackers: pinnedTrackers)
        
        let regularSections = categories.compactMap { category -> Section? in
            let trackers = category.trackers.filter { tracker in
                matchesTracker(tracker) && tracker.isPinned == false
            }
            guard trackers.isEmpty == false else { return nil }
            let sortedTrackers = trackers.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return Section(title: category.title, trackers: sortedTrackers)
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        
        var assembledSections: [Section] = []
        if let pinnedSection {
            assembledSections.append(pinnedSection)
        }
        assembledSections.append(contentsOf: regularSections)
        
        let hasTrackers = assembledSections.flatMap { $0.trackers }.isEmpty == false
        let emptyReason: TrackersViewState.EmptyReason
        if hasTrackers {
            emptyReason = .none
        } else {
            emptyReason = hasAnyTrackersForDate ? .noResults : .noTrackersForDate
        }
        
        state = TrackersViewState(
            sections: assembledSections,
            hasTrackers: hasTrackers,
            hasAnyTrackersForDate: hasAnyTrackersForDate,
            filter: selectedFilter,
            emptyReason: emptyReason
        )
    }
    
    private func normalized(date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    func completedCount(for tracker: Tracker) -> Int {
        recordStore.records.filter { $0.trackerId == tracker.id }.count
    }
    
    private func formattedDaysText(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        let suffix: String
        if remainder100 >= 11 && remainder100 <= 14 {
            suffix = NSLocalizedString("дней", comment: "Days plural genitive")
        } else {
            switch remainder10 {
            case 1:
                suffix = NSLocalizedString("день", comment: "Day singular")
            case 2...4:
                suffix = NSLocalizedString("дня", comment: "Days plural")
            default:
                suffix = NSLocalizedString("дней", comment: "Days plural genitive")
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
        applyFilters()
        onRecordsUpdated?()
    }
}

