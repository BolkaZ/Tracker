import UIKit

protocol ScheduleViewControllerDelegate: AnyObject {
    func scheduleViewController(_ viewController: ScheduleViewController,
                                didUpdate weekdays: [Weekday])
}

final class ScheduleViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ScheduleViewControllerDelegate?
    
    private let viewModel: ScheduleViewModel
    private var state: ScheduleState
    
    private let tableBackgroundColor = UIColor(resource: .appGrayOsn)
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.separatorColor = UIColor(resource: .appGray)
        table.backgroundColor = UIColor(resource: .appWhite)
        table.tableHeaderView = UIView(frame: .zero)
        table.tableFooterView = UIView(frame: .zero)
        return table
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .appWhite), for: .normal)
        button.backgroundColor = UIColor(resource: .appBlack)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    init(viewModel: ScheduleViewModel) {
        self.viewModel = viewModel
        self.state = viewModel.state
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .appWhite)
        navigationItem.title = "Расписание"
        setupDoneButton()
        setupTableView()
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.apply(state: state)
            }
        }
        viewModel.bind()
    }
    
    private func apply(state: ScheduleState) {
        self.state = state
        tableView.reloadData()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScheduleCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16)
        ])
    }
    
    private func setupDoneButton() {
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        delegate?.scheduleViewController(self, didUpdate: viewModel.selectedWeekdaysList())
        dismiss(animated: true)
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        guard let weekday = Weekday(rawValue: sender.tag) else { return }
        viewModel.set(weekday, isSelected: sender.isOn)
    }
    
}

// MARK: - UITableViewDataSource

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Weekday.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath)
        let weekday = Weekday.allCases[indexPath.row]
        cell.selectionStyle = .none
        cell.backgroundColor = tableBackgroundColor
        cell.textLabel?.text = weekday.localizedName
        
        let toggle = UISwitch()
        toggle.isOn = state.selectedWeekdays.contains(weekday)
        toggle.tag = weekday.rawValue
        toggle.onTintColor = UIColor(resource: .appBlue)
        toggle.thumbTintColor = UIColor(resource: .appWhite)
        toggle.backgroundColor = UIColor(resource: .appGrayOsn100)
        toggle.layer.cornerRadius = 16
        toggle.clipsToBounds = true
        toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

