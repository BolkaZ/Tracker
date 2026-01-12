//
//  CategorySelectionViewController.swift
//  Tracker
//
//  Created by Artem Kuzmenko on 19.11.2025.
//

import UIKit

protocol CategorySelectionViewControllerDelegate: AnyObject {
    func categorySelection(_ viewController: CategorySelectionViewController,
                           didSelect category: String,
                           categories: [String])
}

final class CategorySelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CategorySelectionViewControllerDelegate?
    
    private let viewModel: CategorySelectionViewModel
    private var state: CategorySelectionState
    private var tableHeightConstraint: NSLayoutConstraint?
    
    private let tableContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.separatorColor = UIColor(resource: .appGray)
        table.backgroundColor = UIColor(resource: .appGrayOsn)
        table.layer.cornerRadius = 16
        table.layer.masksToBounds = true
        return table
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Добавить категорию", comment: "Add category button"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .appWhite), for: .normal)
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
        label.text = NSLocalizedString("Привычки и события можно\nобъединить по смыслу", comment: "Empty categories text")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .appBlack)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    
    init(viewModel: CategorySelectionViewModel) {
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
        navigationItem.title = NSLocalizedString("Категория", comment: "Category selection title")
        setupEmptyState()
        setupDoneButton()
        setupTableView()
        bindViewModel()
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
        tableView.separatorStyle = .none
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        tableView.rowHeight = 75
        tableView.isScrollEnabled = false
        
        view.addSubview(tableContainerView)
        tableContainerView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableContainerView.bottomAnchor.constraint(lessThanOrEqualTo: doneButton.topAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: tableContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: tableContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: tableContainerView.trailingAnchor)
        ])
        
        let containerBottomConstraint = tableContainerView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        containerBottomConstraint.priority = .defaultHigh
        containerBottomConstraint.isActive = true
        
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
    }
    
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] newState in
            self?.apply(state: newState)
        }
        
        viewModel.onCategorySelected = { [weak self] category, categories in
            self?.notifyDelegateAndDismiss(with: category, categories: categories)
        }
        
        viewModel.onError = { [weak self] message in
            self?.presentError(message)
        }
        
        viewModel.bind()
    }
    
    private func apply(state: CategorySelectionState) {
        self.state = state
        tableView.reloadData()
        updateTableHeight()
        updateUI()
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
        let hasCategories = !state.categories.isEmpty
        
        // Показываем/скрываем заглушку
        emptyStateView.isHidden = hasCategories
        tableContainerView.isHidden = !hasCategories
        tableView.isHidden = !hasCategories
        
        // Кнопка "Добавить категорию" всегда активна
        doneButton.setTitle(NSLocalizedString("Добавить категорию", comment: "Add category button"), for: .normal)
        doneButton.isEnabled = true
        doneButton.alpha = 1.0
        doneButton.backgroundColor = UIColor(resource: .appBlack)
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        presentNewCategoryViewController()
    }
    
    private func presentNewCategoryViewController() {
        let newCategoryVC = NewCategoryViewController()
        newCategoryVC.delegate = self
        let navController = UINavigationController(rootViewController: newCategoryVC)
        present(navController, animated: true)
    }
    
    private func notifyDelegateAndDismiss(with category: String, categories: [String]) {
        delegate?.categorySelection(self, didSelect: category, categories: categories)
        dismiss(animated: true)
    }
    
    private func presentDeleteConfirmation(for category: String, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("Эта категория точно не нужна?", comment: "Delete category confirmation"),
            preferredStyle: .actionSheet
        )
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("Удалить", comment: "Delete category"),
            style: .destructive
        ) { [weak self] _ in
            self?.viewModel.deleteCategory(title: category)
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Отмена", comment: "Cancel action"),
            style: .cancel
        )
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController,
           let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        } else if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 1,
                height: 1
            )
        }
        
        present(alert, animated: true)
    }
    
    private func presentEditCategory(for category: String) {
        let editVC = EditCategoryViewController(currentTitle: category)
        editVC.delegate = self
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    private func presentError(_ message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("Ошибка", comment: "Category error title"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK"), style: .default))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }
    
    private func updateTableHeight() {
        tableView.layoutIfNeeded()
        let height = state.categories.isEmpty ? 0 : tableView.contentSize.height
        tableHeightConstraint?.constant = height
    }
}

// MARK: - UITableViewDataSource

extension CategorySelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        let category = state.categories[indexPath.row]
        let isLast = indexPath.row == state.categories.count - 1
        cell.configure(title: category,
                       isSelected: category == state.selectedCategory,
                       showsSeparator: !isLast)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CategorySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < state.categories.count else { return nil }
        let category = state.categories[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { [weak self] _ in
            let editAction = UIAction(
                title: NSLocalizedString("Редактировать", comment: "Edit category action")
            ) { [weak self] _ in
                self?.presentEditCategory(for: category)
            }
            
            let deleteAction = UIAction(
                title: NSLocalizedString("Удалить", comment: "Delete category action"),
                attributes: .destructive
            ) { _ in
                self?.presentDeleteConfirmation(for: category, at: indexPath)
            }
            
            return UIMenu(children: [editAction, deleteAction])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCategory(at: indexPath.row)
    }
}

// MARK: - NewCategoryViewControllerDelegate

extension CategorySelectionViewController: NewCategoryViewControllerDelegate {
    func newCategoryViewController(_ viewController: NewCategoryViewController,
                                 didCreate category: String) {
        viewModel.createCategory(category)
    }
}

// MARK: - EditCategoryViewControllerDelegate

extension CategorySelectionViewController: EditCategoryViewControllerDelegate {
    func editCategoryViewController(_ viewController: EditCategoryViewController,
                                    didUpdateFrom oldTitle: String,
                                    to newTitle: String) {
        viewModel.updateCategory(oldTitle: oldTitle, newTitle: newTitle)
    }
}
