import Foundation

final class NewCategoryViewModel {
    
    var onStateChange: ((NewCategoryState) -> Void)?
    
    private(set) var state: NewCategoryState {
        didSet {
            onStateChange?(state)
        }
    }
    
    init() {
        self.state = NewCategoryState(title: "")
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

