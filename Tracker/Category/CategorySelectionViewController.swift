import UIKit

protocol CategorySelectionViewControllerDelegate: AnyObject {
    func categorySelection(_ viewController: CategorySelectionViewController,
                           didSelect category: String,
                           categories: [String])
}

final class CategorySelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CategorySelectionViewControllerDelegate?
    
    private var categories: [String]
    private var selectedCategory: String?
    
    private let tableBackgroundColor = UIColor(resource: .appGrayOsn)
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.backgroundColor = tableBackgroundColor
        table.tableHeaderView = UIView(frame: .zero)
        table.tableFooterView = UIView(frame: .zero)
        return table
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(resource: .appBlack)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(resource: .star))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .appBlack)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    
    init(categories: [String], selectedCategory: String?) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Категория"
        setupEmptyState()
        setupDoneButton()
        setupTableView()
        updateUI()
    }
    
    // MARK: - Setup
    
    private func setupEmptyState() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.backgroundColor = UIColor(resource: .appWhite)
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
    
    private func updateUI() {
        let hasCategories = !categories.isEmpty
        
        // Показываем/скрываем заглушку
        emptyStateView.isHidden = hasCategories
        tableView.isHidden = !hasCategories
        
        // Кнопка "Добавить категорию" всегда активна
        doneButton.setTitle("Добавить категорию", for: .normal)
        doneButton.isEnabled = true
        doneButton.alpha = 1.0
        doneButton.backgroundColor = UIColor(resource: .appBlack)
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        // Кнопка "Добавить категорию" всегда открывает экран создания категории
        presentNewCategoryViewController()
    }
    
    private func presentNewCategoryViewController() {
        let newCategoryVC = NewCategoryViewController()
        newCategoryVC.delegate = self
        let navController = UINavigationController(rootViewController: newCategoryVC)
        present(navController, animated: true)
    }
    
    private func notifyDelegateAndDismiss(with category: String) {
        delegate?.categorySelection(self, didSelect: category, categories: categories)
        dismiss(animated: true)
    }
    
    private func addCategory(_ categoryName: String) {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Проверяем, не существует ли уже такая категория
        guard !categories.contains(where: { $0.caseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            // Если категория уже существует, просто выбираем её
            selectedCategory = trimmedName
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            updateUI()
            // Автоматически возвращаемся в настройки трекера
            notifyDelegateAndDismiss(with: trimmedName)
            return
        }
        
        // Добавляем новую категорию
        let wasEmpty = categories.isEmpty
        categories.append(trimmedName)
        selectedCategory = trimmedName
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        updateUI()
        
        // Если список был пуст, автоматически возвращаемся в настройки трекера
        if wasEmpty {
            notifyDelegateAndDismiss(with: trimmedName)
        }
    }
}

// MARK: - UITableViewDataSource

extension CategorySelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = categories[indexPath.row]
        cell.textLabel?.text = category
        cell.accessoryType = category == selectedCategory ? .checkmark : .none
        cell.backgroundColor = tableBackgroundColor
        cell.contentView.backgroundColor = tableBackgroundColor
        cell.selectionStyle = .default
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CategorySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = categories[indexPath.row]
        selectedCategory = category
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        // Автоматически возвращаемся в настройки трекера при выборе категории
        notifyDelegateAndDismiss(with: category)
    }
}

// MARK: - NewCategoryViewControllerDelegate

extension CategorySelectionViewController: NewCategoryViewControllerDelegate {
    func newCategoryViewController(_ viewController: NewCategoryViewController,
                                 didCreate category: String) {
        addCategory(category)
    }
}
