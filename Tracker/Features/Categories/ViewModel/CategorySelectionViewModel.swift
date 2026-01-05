import Foundation

final class CategorySelectionViewModel: NSObject {
    
    var onStateChange: ((CategorySelectionState) -> Void)?
    var onCategorySelected: ((String, [String]) -> Void)?
    var onError: ((String) -> Void)?
    
    private let store: TrackerCategoryStore
    
    private(set) var state: CategorySelectionState {
        didSet {
            let currentState = state
            DispatchQueue.main.async {
                self.onStateChange?(currentState)
            }
        }
    }
    
    init(selectedCategory: String?,
         store: TrackerCategoryStore = TrackerCategoryStore()) {
        self.store = store
        self.state = CategorySelectionState(categories: [], selectedCategory: selectedCategory)
        super.init()
        self.store.delegate = self
    }
    
    func bind() {
        reloadCategories()
    }
    
    func numberOfCategories() -> Int {
        state.categories.count
    }
    
    func titleForCategory(at index: Int) -> String? {
        guard index < state.categories.count else { return nil }
        return state.categories[index]
    }
    
    func selectCategory(at index: Int, notifyDelegate: Bool = true) {
        guard index < state.categories.count else { return }
        let category = state.categories[index]
        state = CategorySelectionState(categories: state.categories, selectedCategory: category)
        guard notifyDelegate else { return }
        notifySelection(with: category)
    }
    
    func createCategory(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        
        if let existingIndex = state.categories.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectCategory(at: existingIndex)
            return
        }
        
        do {
            try store.createCategory(title: trimmed)
            reloadCategories()
            selectCategoryIfPossible(with: trimmed, notifyDelegate: true)
        } catch {
            handle(error: error)
        }
    }
    
    private func reloadCategories() {
        let titles = store.categories.map { $0.title }
        let selected = state.selectedCategory.flatMap { selectedTitle in
            titles.first(where: { $0.caseInsensitiveCompare(selectedTitle) == .orderedSame })
        }
        state = CategorySelectionState(categories: titles, selectedCategory: selected)
    }
    
    private func selectCategoryIfPossible(with title: String,
                                          notifyDelegate: Bool = false) {
        guard let index = state.categories.firstIndex(where: { $0.caseInsensitiveCompare(title) == .orderedSame }) else {
            return
        }
        selectCategory(at: index, notifyDelegate: notifyDelegate)
    }
    
    private func notifySelection(with category: String) {
        let categories = state.categories
        DispatchQueue.main.async {
            self.onCategorySelected?(category, categories)
        }
    }
    
    private func handle(error: Error) {
        let message: String
        if let storeError = error as? TrackerCategoryStoreError {
            switch storeError {
            case .duplicateTitle:
                message = "Такая категория уже существует."
            case .invalidTitle:
                message = "Введите корректное название категории."
            case .categoryNotFound:
                message = "Категория не найдена."
            }
        } else {
            message = "Не удалось сохранить категорию. Попробуйте ещё раз."
        }
        DispatchQueue.main.async {
            self.onError?(message)
        }
    }
}

extension CategorySelectionViewModel: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidChange(_ store: TrackerCategoryStore) {
        reloadCategories()
    }
}

