import UIKit

class CreateHabitViewController: BaseTrackerCreationViewController {
    
    // MARK: - UI
    
    private let daysCounterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(resource: .appBlack)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private let showDaysCounter: Bool
    private let daysCount: Int?
    
    // MARK: - Init
    
    init(viewModel: TrackerCreationViewModel = TrackerCreationViewModel(type: .habit),
         showDaysCounter: Bool = false,
         daysCount: Int? = nil) {
        self.showDaysCounter = showDaysCounter
        self.daysCount = daysCount
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    // MARK: - UI Elements
    
    private lazy var scheduleButton: UIButton = {
        let button = createSelectionButton(
            title: NSLocalizedString("Расписание", comment: "Schedule selection button"),
            subtitle: nil
        )
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
        titleLabel.text = NSLocalizedString("Новая привычка", comment: "Create habit title")
        categoryButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        updateScheduleSubtitle(with: viewModel.state.schedule)
        if showDaysCounter {
            updateDaysCounterLabel()
        }
    }
    
    // MARK: - Override Methods
    
    override func setupSpecificUI() {
        if showDaysCounter {
            contentView.addSubview(daysCounterLabel)
        }
        contentView.addSubview(scheduleButton)
        contentView.addSubview(separatorView)
        
        var constraints: [NSLayoutConstraint] = []
        if showDaysCounter {
            constraints.append(contentsOf: [
                daysCounterLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
                daysCounterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                daysCounterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        }
        
        constraints.append(contentsOf: [
            separatorView.centerYAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: categoryButton.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: categoryButton.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            scheduleButton.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            scheduleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scheduleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scheduleButton.heightAnchor.constraint(equalToConstant: 75)
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    override func getElementAboveEmojiTitle() -> UIView {
        return scheduleButton
    }
    
    override func nameTopAnchorView() -> UIView {
        guard showDaysCounter else { return super.nameTopAnchorView() }
        return daysCounterLabel
    }
    
    override func getNameTopSpacing() -> CGFloat {
        guard showDaysCounter else { return super.getNameTopSpacing() }
        return 40
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
            updateButton(scheduleButton, subtitle: NSLocalizedString("Каждый день", comment: "Every day schedule summary"))
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
    
    // MARK: - Days counter
    
    private func updateDaysCounterLabel() {
        guard let count = daysCount else { return }
        daysCounterLabel.text = formattedDaysText(for: count)
    }
    
    private func formattedDaysText(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        let suffix: String
        if remainder100 >= 11 && remainder100 <= 14 {
            suffix = NSLocalizedString("дней", comment: "Days plural genitive")
        } else {
            switch remainder10 {
            case 1:
                suffix = NSLocalizedString("день", comment: "Day singular")
            case 2...4:
                suffix = NSLocalizedString("дня", comment: "Days plural")
            default:
                suffix = NSLocalizedString("дней", comment: "Days plural genitive")
            }
        }
        return "\(count) \(suffix)"
    }
}

// MARK: - ScheduleViewControllerDelegate

extension CreateHabitViewController: ScheduleViewControllerDelegate {
    func scheduleViewController(_ viewController: ScheduleViewController,
                                didUpdate weekdays: [Weekday]) {
        viewModel.updateSchedule(weekdays)
    }
    
}

