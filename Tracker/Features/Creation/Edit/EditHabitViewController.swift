import UIKit

final class EditHabitViewController: CreateHabitViewController {
    
    weak var editingDelegate: TrackerEditingDelegate?
    
    // MARK: - Init
    
    init(tracker: Tracker, categoryTitle: String, availableCategories: [String], daysCount: Int) {
        let viewModel = TrackerCreationViewModel(
            type: .habit,
            availableCategories: availableCategories,
            editingTracker: tracker,
            categoryTitle: categoryTitle
        )
        super.init(viewModel: viewModel, showDaysCounter: true, daysCount: daysCount)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = NSLocalizedString("Редактирование привычки", comment: "Edit habit title")
        createButton.setTitle(NSLocalizedString("Сохранить", comment: "Save tracker changes"), for: .normal)
        nameTextField.text = viewModel.state.name
    }
    
    // MARK: - Actions
    
    override func createTapped() {
        guard let result = viewModel.makeTracker() else { return }
        editingDelegate?.trackerEditingDidUpdate(result.tracker, in: result.categoryTitle)
        dismissCreationFlow()
    }
}
