import UIKit

class CreateIrregularViewController: BaseTrackerCreationViewController {
    
    // MARK: - Init
    
    override init(viewModel: TrackerCreationViewModel = TrackerCreationViewModel(type: .irregular)) {
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = NSLocalizedString("Новое нерегулярное событие", comment: "Create irregular event title")
    }
    
    // MARK: - Override Methods
    
    override func getElementAboveEmojiTitle() -> UIView {
        return categoryButton
    }
}
