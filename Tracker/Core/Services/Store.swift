import Foundation
import CoreData

// MARK: - DataBase Store

final class DataBaseStore {
    static let shared = DataBaseStore()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Library")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                assertionFailure("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private init() {}
    
    func saveContextIfNeeded() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            assertionFailure("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

// MARK: - Container Provider


protocol PersistentContainerProviding {
    var persistentContainer: NSPersistentContainer { get }
}

struct AppDelegateContainerProvider: PersistentContainerProviding {
    var persistentContainer: NSPersistentContainer {
        return DataBaseStore.shared.persistentContainer
    }
}

// MARK: - Base Store

class CoreDataStore<Object: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    let context: NSManagedObjectContext
    private(set) var resultsController: NSFetchedResultsController<Object>
    
    init(fetchRequest: NSFetchRequest<Object>,
         sectionNameKeyPath: String? = nil,
         provider: PersistentContainerProviding = AppDelegateContainerProvider()) {
        self.context = provider.persistentContainer.viewContext
        self.resultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil
        )
        super.init()
        resultsController.delegate = self
        performFetch(on: resultsController)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard controller == resultsController else { return }
        contentDidChange()
    }
    
    func contentDidChange() {
    }
    
    func saveContextIfNeeded() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
    
    private func performFetch(on controller: NSFetchedResultsController<Object>) {
        do {
            try controller.performFetch()
        } catch {
            assertionFailure("Failed to perform fetch: \(error)")
        }
    }
}

// MARK: - Tracker Store

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidChange(_ store: TrackerStore)
}

enum TrackerStoreError: Error {
    case categoryNotFound
    case trackerNotFound
    case invalidData
}

final class TrackerStore: CoreDataStore<TrackerEntity> {
    
    weak var delegate: TrackerStoreDelegate?
    private let calendar = Calendar(identifier: .gregorian)
    
    override init(fetchRequest: NSFetchRequest<TrackerEntity> = TrackerEntity.fetchRequest(),
                  sectionNameKeyPath: String? = "category.title",
                  provider: PersistentContainerProviding = AppDelegateContainerProvider()) {
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: "category.title",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            ),
            NSSortDescriptor(
                key: "title",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        super.init(fetchRequest: fetchRequest, sectionNameKeyPath: sectionNameKeyPath, provider: provider)
    }
    
    override func contentDidChange() {
        delegate?.trackerStoreDidChange(self)
    }
    
    var trackers: [Tracker] {
        guard let objects = resultsController.fetchedObjects else { return [] }
        return objects.compactMap { (entity: TrackerEntity) -> Tracker? in
            entity.toDomainModel()
        }
    }
    
    func trackers(in categoryTitle: String) -> [Tracker] {
        return trackers.filter { (tracker: Tracker) -> Bool in
            guard let category = categoryFor(trackerId: tracker.id) else { return false }
            return category.caseInsensitiveCompare(categoryTitle) == .orderedSame
        }
    }
    
    func createTracker(_ tracker: Tracker, in categoryTitle: String) throws {
        try context.performAndWait {
            guard let category = try fetchCategoryEntity(title: categoryTitle) else {
                throw TrackerStoreError.categoryNotFound
            }
            
            let entity = TrackerEntity(context: context)
            entity.id = tracker.id
            entity.title = tracker.title
            entity.emoji = tracker.emoji
            entity.colorHex = tracker.colorHex
            entity.type = Int16(tracker.schedule.isEmpty ? 1 : 0)
            entity.createdAt = Date()
            entity.updatedAt = Date()
            entity.isPinned = tracker.isPinned
            entity.category = category
            
            for weekday in tracker.schedule {
                let item = TrackerScheduleItemEntity(context: context)
                item.weekday = Int16(weekday.rawValue)
                item.tracker = entity
            }
            
            try saveContextIfNeeded()
        }
    }
    
    func deleteTracker(with id: UUID) throws {
        try context.performAndWait {
            guard let tracker = try fetchTrackerEntity(id: id) else {
                throw TrackerStoreError.trackerNotFound
            }
            context.delete(tracker)
            try saveContextIfNeeded()
        }
    }
    
    func updatePinStatus(trackerId: UUID, isPinned: Bool) throws {
        try context.performAndWait {
            guard let tracker = try fetchTrackerEntity(id: trackerId) else {
                throw TrackerStoreError.trackerNotFound
            }
            tracker.isPinned = isPinned
            tracker.updatedAt = Date()
            try saveContextIfNeeded()
        }
    }
    
    func updateTracker(_ tracker: Tracker, in categoryTitle: String) throws {
        try context.performAndWait {
            guard let entity = try fetchTrackerEntity(id: tracker.id) else {
                throw TrackerStoreError.trackerNotFound
            }
            guard let category = try fetchCategoryEntity(title: categoryTitle) else {
                throw TrackerStoreError.categoryNotFound
            }
            
            entity.title = tracker.title
            entity.emoji = tracker.emoji
            entity.colorHex = tracker.colorHex
            entity.type = Int16(tracker.schedule.isEmpty ? 1 : 0)
            entity.updatedAt = Date()
            entity.isPinned = tracker.isPinned
            entity.category = category
            
            if let items = entity.scheduleItems as? Set<TrackerScheduleItemEntity> {
                items.forEach { context.delete($0) }
            }
            
            for weekday in tracker.schedule {
                let item = TrackerScheduleItemEntity(context: context)
                item.weekday = Int16(weekday.rawValue)
                item.tracker = entity
            }
            
            try saveContextIfNeeded()
        }
    }
    
    func categoryTitle(for trackerId: UUID) -> String? {
        categoryFor(trackerId: trackerId)
    }
    
    private func fetchTrackerEntity(id: UUID) throws -> TrackerEntity? {
        let request: NSFetchRequest<TrackerEntity> = TrackerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    private func fetchCategoryEntity(title: String) throws -> TrackerCategoryEntity? {
        let request: NSFetchRequest<TrackerCategoryEntity> = TrackerCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title ==[c] %@", title)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    private func categoryFor(trackerId: UUID) -> String? {
        guard let tracker = resultsController.fetchedObjects?.first(where: { $0.id == trackerId }) else {
            return nil
        }
        return tracker.category?.title
    }
}

// MARK: - Tracker Category Store

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidChange(_ store: TrackerCategoryStore)
}

enum TrackerCategoryStoreError: Error {
    case duplicateTitle
    case categoryNotFound
    case invalidTitle
    case categoryNotEmpty
}

final class TrackerCategoryStore: CoreDataStore<TrackerCategoryEntity> {
    
    weak var delegate: TrackerCategoryStoreDelegate?
    
    override init(fetchRequest: NSFetchRequest<TrackerCategoryEntity> = TrackerCategoryEntity.fetchRequest(),
                  sectionNameKeyPath: String? = nil,
                  provider: PersistentContainerProviding = AppDelegateContainerProvider()) {
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: "title",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        super.init(fetchRequest: fetchRequest, sectionNameKeyPath: sectionNameKeyPath, provider: provider)
    }
    
    override func contentDidChange() {
        delegate?.trackerCategoryStoreDidChange(self)
    }
    
    var categories: [TrackerCategory] {
        guard let objects = resultsController.fetchedObjects else { return [] }
        return objects.map { (entity: TrackerCategoryEntity) -> TrackerCategory in
            entity.toDomainModel()
        }
    }
    
    func createCategory(title: String) throws {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw TrackerCategoryStoreError.invalidTitle
        }
        
        try context.performAndWait {
            if try fetchCategoryEntity(title: normalized) != nil {
                throw TrackerCategoryStoreError.duplicateTitle
            }
            
            let entity = TrackerCategoryEntity(context: context)
            entity.id = UUID()
            entity.title = normalized
            entity.createdAt = Date()
            try saveContextIfNeeded()
        }
    }
    
    func updateCategory(from oldTitle: String, to newTitle: String) throws {
        let normalized = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw TrackerCategoryStoreError.invalidTitle
        }
        
        try context.performAndWait {
            guard let entity = try fetchCategoryEntity(title: oldTitle) else {
                throw TrackerCategoryStoreError.categoryNotFound
            }
            
            if oldTitle.caseInsensitiveCompare(normalized) != .orderedSame,
               try fetchCategoryEntity(title: normalized) != nil {
                throw TrackerCategoryStoreError.duplicateTitle
            }
            
            entity.title = normalized
            try saveContextIfNeeded()
        }
    }
    
    func deleteCategory(title: String) throws {
        try context.performAndWait {
            guard let entity = try fetchCategoryEntity(title: title) else {
                throw TrackerCategoryStoreError.categoryNotFound
            }
            let trackersCount = (entity.trackers as? Set<TrackerEntity>)?.count ?? 0
            if trackersCount > 0 {
                throw TrackerCategoryStoreError.categoryNotEmpty
            }
            context.delete(entity)
            try saveContextIfNeeded()
        }
    }
    
    private func fetchCategoryEntity(title: String) throws -> TrackerCategoryEntity? {
        let request: NSFetchRequest<TrackerCategoryEntity> = TrackerCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title ==[c] %@", title)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

// MARK: - Tracker Record Store

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidChange(_ store: TrackerRecordStore)
}

enum TrackerRecordStoreError: Error {
    case trackerNotFound
    case recordAlreadyExists
    case recordNotFound
}

final class TrackerRecordStore: CoreDataStore<TrackerRecordEntity> {
    
    weak var delegate: TrackerRecordStoreDelegate?
    private let calendar = Calendar(identifier: .gregorian)
    
    override init(fetchRequest: NSFetchRequest<TrackerRecordEntity> = TrackerRecordEntity.fetchRequest(),
                  sectionNameKeyPath: String? = nil,
                  provider: PersistentContainerProviding = AppDelegateContainerProvider()) {
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: true),
            NSSortDescriptor(key: "tracker.id", ascending: true)
        ]
        super.init(fetchRequest: fetchRequest, sectionNameKeyPath: sectionNameKeyPath, provider: provider)
    }
    
    override func contentDidChange() {
        delegate?.trackerRecordStoreDidChange(self)
    }
    
    var records: [TrackerRecord] {
        guard let objects = resultsController.fetchedObjects else { return [] }
        return objects.compactMap { (entity: TrackerRecordEntity) -> TrackerRecord? in
            entity.toDomainModel()
        }
    }
    
    func addRecord(trackerId: UUID, date: Date) throws {
        let normalizedDate = calendar.startOfDay(for: date)
        try context.performAndWait {
            guard let tracker = try fetchTrackerEntity(id: trackerId) else {
                throw TrackerRecordStoreError.trackerNotFound
            }
            if try fetchRecord(trackerId: trackerId, date: normalizedDate) != nil {
                throw TrackerRecordStoreError.recordAlreadyExists
            }
            
            let record = TrackerRecordEntity(context: context)
            record.id = UUID()
            record.date = normalizedDate
            record.tracker = tracker
            try saveContextIfNeeded()
        }
    }
    
    func removeRecord(trackerId: UUID, date: Date) throws {
        let normalizedDate = calendar.startOfDay(for: date)
        try context.performAndWait {
            guard let record = try fetchRecord(trackerId: trackerId, date: normalizedDate) else {
                throw TrackerRecordStoreError.recordNotFound
            }
            context.delete(record)
            try saveContextIfNeeded()
        }
    }
    
    func isCompleted(trackerId: UUID, date: Date) -> Bool {
        let normalized = calendar.startOfDay(for: date)
        let predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg,
            normalized as NSDate
        )
        let request: NSFetchRequest<TrackerRecordEntity> = TrackerRecordEntity.fetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1
        do {
            return try context.count(for: request) > 0
        } catch {
            assertionFailure("Failed to check completion: \(error)")
            return false
        }
    }
    
    private func fetchRecord(trackerId: UUID, date: Date) throws -> TrackerRecordEntity? {
        let request: NSFetchRequest<TrackerRecordEntity> = TrackerRecordEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg,
            date as NSDate
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    private func fetchTrackerEntity(id: UUID) throws -> TrackerEntity? {
        let request: NSFetchRequest<TrackerEntity> = TrackerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

// MARK: - Domain Mappers

private extension TrackerEntity {
    func toDomainModel() -> Tracker? {
        guard let id = id,
              let title = title,
              let emoji = emoji,
              let colorHex = colorHex else {
            return nil
        }
        let isPinned = isPinned
        
        let items = (scheduleItems?.allObjects as? [TrackerScheduleItemEntity]) ?? []
        let weekdays = items.compactMap { (item: TrackerScheduleItemEntity) -> Weekday? in
            Weekday(rawValue: Int(item.weekday))
        }
            .sorted { $0.rawValue < $1.rawValue }
        
        return Tracker(
            id: id,
            title: title,
            colorHex: colorHex,
            emoji: emoji,
            schedule: weekdays,
            isPinned: isPinned
        )
    }
}

private extension TrackerCategoryEntity {
    func toDomainModel() -> TrackerCategory {
        let trackersList = (trackers?.allObjects as? [TrackerEntity] ?? [])
            .compactMap { (entity: TrackerEntity) -> Tracker? in
                entity.toDomainModel()
            }
        return TrackerCategory(title: title ?? "", trackers: trackersList)
    }
}

private extension TrackerRecordEntity {
    func toDomainModel() -> TrackerRecord? {
        guard let id = tracker?.id,
              let date = date else {
            return nil
        }
        return TrackerRecord(trackerId: id, date: date)
    }
}
