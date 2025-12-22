import UIKit

protocol CategorySelectionViewControllerDelegate: AnyObject {
    func categorySelection(_ viewController: CategorySelectionViewController,
                           didSelect category: String,
                           categories: [String])
}

final class CategorySelectionViewController: UIViewController {
    
    private enum Section: Int, CaseIterable {
        case categories
        case addCategory
    }
    
    // MARK: - Properties
    
    weak var delegate: CategorySelectionViewControllerDelegate?
    
    private var categories: [String]
    private var selectedCategory: String? {
        didSet { updateDoneButtonState() }
    }
    
    private let tableBackgroundColor = UIColor(named: "AppGrayOsn")
    
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
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "AppBlack")
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    init(categories: [String], selectedCategory: String?) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Категория"
        setupDoneButton()
        setupTableView()
        updateDoneButtonState()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.backgroundColor = UIColor(named: "AppWhite")
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
    
    private func updateDoneButtonState() {
        let enabled = selectedCategory != nil
        doneButton.isEnabled = enabled
        doneButton.alpha = enabled ? 1.0 : 0.3
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        guard let selectedCategory else { return }
        notifyDelegateAndDismiss(with: selectedCategory)
    }
    
    private func presentAddCategoryAlert() {
        let alert = UIAlertController(title: "Новая категория",
                                      message: "Введите название категории",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Например, Домашний уют"
        }
        
        var textObserver: NSObjectProtocol?
        
        let addAction = UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            guard
                let self = self,
                let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                !text.isEmpty
            else { return }
            if let observer = textObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            
            guard !self.categories.contains(where: { $0.caseInsensitiveCompare(text) == .orderedSame }) else {
                self.selectedCategory = text
                self.tableView.reloadSections(IndexSet(integer: Section.categories.rawValue), with: .automatic)
                return
            }
            
            self.categories.append(text)
            self.selectedCategory = text
            self.tableView.reloadSections(IndexSet(integer: Section.categories.rawValue), with: .automatic)
        }
        addAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in
            if let observer = textObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true) {
            textObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification,
                                                                  object: alert.textFields?.first,
                                                                  queue: .main) { notification in
                guard let field = notification.object as? UITextField else { return }
                addAction.isEnabled = !(field.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            }
        }
    }
    
    private func notifyDelegateAndDismiss(with category: String) {
        delegate?.categorySelection(self, didSelect: category, categories: categories)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CategorySelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .categories:
            return categories.count
        case .addCategory:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        guard let sectionType = Section(rawValue: indexPath.section) else { return cell }
        
        switch sectionType {
        case .categories:
            let category = categories[indexPath.row]
            cell.textLabel?.text = category
            cell.accessoryType = category == selectedCategory ? .checkmark : .none
        case .addCategory:
            cell.textLabel?.text = "Добавить категорию"
            cell.textLabel?.textColor = UIColor(named: "AppBlack")
            cell.accessoryType = .disclosureIndicator
        }
        cell.backgroundColor = tableBackgroundColor
        cell.contentView.backgroundColor = tableBackgroundColor
        cell.selectionStyle = .default
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CategorySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        switch sectionType {
        case .categories:
            selectedCategory = categories[indexPath.row]
            tableView.reloadSections(IndexSet(integer: Section.categories.rawValue), with: .automatic)
        case .addCategory:
            presentAddCategoryAlert()
        }
    }
}
