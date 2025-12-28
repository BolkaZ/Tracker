import UIKit

final class CreateHabitViewController: BaseTrackerCreationViewController {
    
    // MARK: - UI Elements
    
    private lazy var scheduleButton: UIButton = {
        let button = createSelectionButton(title: "Расписание", subtitle: nil)
        button.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)
        button.backgroundColor = UIColor(resource: .appGrayOsn)
        button.layer.cornerRadius = 16
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return button
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(resource: .appGray)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Properties
    
    private var selectedSchedule: [Weekday] = [] {
        didSet { updateScheduleSubtitle() }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Новая привычка"
        categoryButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    // MARK: - Override Methods
    
    override func setupSpecificUI() {
        contentView.addSubview(scheduleButton)
        contentView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            separatorView.centerYAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: categoryButton.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: categoryButton.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            scheduleButton.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            scheduleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scheduleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scheduleButton.heightAnchor.constraint(equalToConstant: 75)
        ])
    }
    
    override func getElementAboveEmojiTitle() -> UIView {
        return scheduleButton
    }
    
    override func getSchedule() -> [Weekday] {
        return selectedSchedule
    }
    
    override func isScheduleValid() -> Bool {
        return !selectedSchedule.isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func scheduleTapped() {
        let controller = ScheduleViewController(selectedWeekdays: Set(selectedSchedule))
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true)
    }
    
    // MARK: - Subtitle updates
    
    private func updateScheduleSubtitle() {
        guard !selectedSchedule.isEmpty else {
            updateButton(scheduleButton, subtitle: nil)
            return
        }
        if selectedSchedule.count == Weekday.allCases.count {
            updateButton(scheduleButton, subtitle: "Каждый день")
        } else {
            let text = selectedSchedule
                .sorted { $0.rawValue < $1.rawValue }
                .map { $0.shortTitle }
                .joined(separator: ", ")
            updateButton(scheduleButton, subtitle: text)
        }
    }
}

// MARK: - ScheduleViewControllerDelegate

extension CreateHabitViewController: ScheduleViewControllerDelegate {
    func scheduleViewController(_ viewController: ScheduleViewController,
                                didUpdate weekdays: [Weekday]) {
        selectedSchedule = weekdays
    }
}
