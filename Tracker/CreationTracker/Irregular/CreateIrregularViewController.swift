import UIKit

final class CreateIrregularViewController: BaseTrackerCreationViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Новое нерегулярное событие"
    }
    
    // MARK: - Override Methods
    
    override func getElementAboveEmojiTitle() -> UIView {
        return categoryButton
    }
    
    override func getSchedule() -> [Weekday] {
        return []
    }
    
    override func isScheduleValid() -> Bool {
        return true
    }
}
