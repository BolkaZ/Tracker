import UIKit

final class CreateTrackerTypeViewController: UIViewController {

    // MARK: - UI Elements
    
    weak var creationDelegate: TrackerCreationDelegate?
    var availableCategories: [String] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Создание трекера"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(resource: .appBlack)
        return label
    }()

    private lazy var habitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Привычка", for: .normal)
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
        button.setTitle("Нерегулярное событие", for: .normal)
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
        view.backgroundColor = .white
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
        let vc = CreateHabitViewController()
        vc.creationDelegate = creationDelegate
        vc.availableCategories = availableCategories
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func irregularTapped() {
        let vc = CreateIrregularViewController()
        vc.creationDelegate = creationDelegate
        vc.availableCategories = availableCategories
        navigationController?.pushViewController(vc, animated: true)
    }

}
