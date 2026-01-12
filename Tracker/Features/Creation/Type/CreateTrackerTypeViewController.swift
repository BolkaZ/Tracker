import UIKit

final class CreateTrackerTypeViewController: UIViewController {

    // MARK: - UI Elements
    
    weak var creationDelegate: TrackerCreationDelegate?
    private let viewModel: CreateTrackerTypeViewModel

    init(viewModel: CreateTrackerTypeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Создание трекера", comment: "Tracker type sheet title")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(resource: .appBlack)
        return label
    }()

    private lazy var habitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Привычка", comment: "Create habit button"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .appWhite), for: .normal)
        button.backgroundColor = (UIColor(resource: .appBlack))
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(habitTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var irregularButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Нерегулярное событие", comment: "Create irregular event button"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .appWhite), for: .normal)
        button.backgroundColor = (UIColor(resource: .appBlack))
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(irregularTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .appWhite)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSheet()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup UI

    private func configureUI() {
        view.addSubview(titleLabel)
        view.addSubview(habitButton)
        view.addSubview(irregularButton)

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            habitButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            habitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            habitButton.heightAnchor.constraint(equalToConstant: 60),

            irregularButton.topAnchor.constraint(equalTo: habitButton.bottomAnchor, constant: 16),
            irregularButton.leadingAnchor.constraint(equalTo: habitButton.leadingAnchor),
            irregularButton.trailingAnchor.constraint(equalTo: habitButton.trailingAnchor),
            irregularButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 16
        }
    }

    // MARK: - Actions

    @objc private func habitTapped() {
        let creationViewModel = viewModel.habitsViewModel()
        let vc = CreateHabitViewController(viewModel: creationViewModel)
        vc.creationDelegate = creationDelegate
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func irregularTapped() {
        let creationViewModel = viewModel.irregularViewModel()
        let vc = CreateIrregularViewController(viewModel: creationViewModel)
        vc.creationDelegate = creationDelegate
        navigationController?.pushViewController(vc, animated: true)
    }

}

#Preview {
    CreateTrackerTypeViewController(viewModel: CreateTrackerTypeViewModel(categories: []))
}
