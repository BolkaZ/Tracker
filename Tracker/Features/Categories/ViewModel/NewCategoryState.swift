import Foundation

struct NewCategoryState {
    let title: String
    
    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isSaveEnabled: Bool {
        trimmedTitle.isEmpty == false
    }
}
