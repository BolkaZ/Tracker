import UIKit

final class CreateHabitViewController: BaseTrackerCreationViewController {
    
    // MARK: - Init
    
    override init(viewModel: TrackerCreationViewModel = TrackerCreationViewModel(type: .habit)) {
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Новая привычка"
        categoryButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        updateScheduleSubtitle(with: viewModel.state.schedule)
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
    
    // MARK: - Actions
    
    @objc private func scheduleTapped() {
        let scheduleViewModel = ScheduleViewModel(selectedWeekdays: Set(viewModel.state.schedule))
        let controller = ScheduleViewController(viewModel: scheduleViewModel)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true)
    }
    
    // MARK: - Subtitle updates
    
    private func updateScheduleSubtitle(with schedule: [Weekday]) {
        guard !schedule.isEmpty else {
            updateButton(scheduleButton, subtitle: nil)
            return
        }
        if schedule.count == Weekday.allCases.count {
            updateButton(scheduleButton, subtitle: "Каждый день")
        } else {
            let text = schedule
                .sorted { $0.rawValue < $1.rawValue }
                .map { $0.shortTitle }
                .joined(separator: ", ")
            updateButton(scheduleButton, subtitle: text)
        }
    }
    
    override func stateDidUpdate(previous: TrackerCreationState?, current: TrackerCreationState) {
        super.stateDidUpdate(previous: previous, current: current)
        if previous?.schedule != current.schedule {
            updateScheduleSubtitle(with: current.schedule)
        }
    }
}

// MARK: - ScheduleViewControllerDelegate

extension CreateHabitViewController: ScheduleViewControllerDelegate {
    func scheduleViewController(_ viewController: ScheduleViewController,
                                didUpdate weekdays: [Weekday]) {
        viewModel.updateSchedule(weekdays)
    }
    
}

