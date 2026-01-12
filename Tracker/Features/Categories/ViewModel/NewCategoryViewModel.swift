import Foundation

final class NewCategoryViewModel {
    
    var onStateChange: ((NewCategoryState) -> Void)?
    
    private(set) var state: NewCategoryState {
        didSet {
            onStateChange?(state)
        }
    }
    
    init(initialTitle: String = "") {
        self.state = NewCategoryState(title: initialTitle)
    }
    
    func bind() {
        onStateChange?(state)
    }
    
    func updateTitle(_ title: String) {
        state = NewCategoryState(title: title)
    }
    
    func makeCategory() -> String? {
        let trimmed = state.trimmedTitle
        return trimmed.isEmpty ? nil : trimmed
    }
}

