import Foundation

struct CategorySelectionState {
    let categories: [String]
    let selectedCategory: String?
    
    var isEmpty: Bool {
        categories.isEmpty
    }
}
