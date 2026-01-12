import UIKit

final class TrackersViewController: UIViewController{

    // MARK: - UI Elements

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.widthAnchor.constraint(equalToConstant: 110).isActive = true
        picker.heightAnchor.constraint(equalToConstant: 34).isActive = true
        return picker
    }()

    private lazy var addTrackerBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(resource: .plus),
                                   style: .plain,
                                   target: self,
                                   action: #selector(addTapped))
        item.tintColor = UIColor(resource: .appBlack)
        return item
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = NSLocalizedString("Поиск", comment: "Search bar placeholder")
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        
        sb.searchTextField.textColor = UIColor(resource: .appBlack)
        
        sb.searchTextField.backgroundColor = UIColor(resource: .appSearchBackgraund)

        sb.searchTextField.attributedPlaceholder = NSAttributedString(
            string: NSLocalizedString("Поиск", comment: "Search bar placeholder"),
            attributes: [
                .foregroundColor: UIColor(resource: .appGraySearch),
                .font: UIFont.systemFont(ofSize: 17)
            ]
        )
        
        if let glassIconView = sb.searchTextField.leftView as? UIImageView {
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = UIColor(resource: .appGraySearch)
        }
        
        return sb
    }()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(resource: .star))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Что будем отслеживать?", comment: "Empty state title")
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .appBlack)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Коллекция трекеров
    private var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 12, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.alwaysBounceVertical = true
        return cv
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Фильтры", comment: "Filters button title"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(resource: .appBlue)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        return button
    }()

    private let viewModel = TrackersViewModel()
    private let logger = LoggingService.makeLogger(label: "tracker.ui.trackers")
    private let filterButtonHeight: CGFloat = 50
    
    private func configureNavigationBar() {
        title = NSLocalizedString("Трекеры", comment: "Trackers screen title")
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = addTrackerBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(resource: .appWhite)
        configureNavigationBar()
        setupLayout()
        searchBar.delegate = self
        setupKeyboardDismiss()

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        bindViewModel()
        viewModel.start()
        updateCollectionInsets(isFilterHidden: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reportMainEvent(event: "open")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reportMainEvent(event: "close")
    }
    
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                guard let self else { return }
                self.collectionView.reloadData()
                self.updateEmptyState(state: state)
                self.datePicker.date = self.viewModel.currentDate
                self.updateFilterButton(state: state)
            }
        }
        
        viewModel.onRecordsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
    }
    
    
    // MARK: - Layout
    private func setupLayout() {
        
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        view.addSubview(emptyImageView)
        view.addSubview(emptyLabel)
        view.addSubview(filterButton)
        
        NSLayoutConstraint.activate([
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(TrackersSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: TrackersSectionHeader.reuseIdentifier)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: filterButtonHeight)
        ])
    }
    
    private func updateEmptyState(state: TrackersViewState) {
        emptyImageView.isHidden = state.hasTrackers
        emptyLabel.isHidden = state.hasTrackers
        collectionView.isHidden = !state.hasTrackers
        
        switch state.emptyReason {
        case .noTrackersForDate:
            emptyImageView.image = UIImage(resource: .star)
            emptyLabel.text = NSLocalizedString("Что будем отслеживать?", comment: "Empty state title")
        case .noResults:
            emptyImageView.image = UIImage(resource: .look)
            emptyLabel.text = NSLocalizedString("Ничего не найдено", comment: "Empty search or filter result")
        case .none:
            break
        }
    }

    // MARK: - Actions
    
    @objc private func addTapped() {
        reportMainEvent(event: "click", item: "add_track")
        let typeViewModel = CreateTrackerTypeViewModel(categories: viewModel.availableCategoryTitles())
        let vc = CreateTrackerTypeViewController(viewModel: typeViewModel)
        vc.creationDelegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func dateChanged() {
        viewModel.updateDate(datePicker.date)
    }
    
    @objc private func filterTapped() {
        reportMainEvent(event: "click", item: "filter")
        let vc = FiltersViewController(selectedFilter: viewModel.selectedFilter)
        vc.onSelectFilter = { [weak self] filter in
            self?.viewModel.selectFilter(filter)
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    private func updateFilterButton(state: TrackersViewState) {
        filterButton.isHidden = state.hasAnyTrackersForDate == false
        let titleColor: UIColor = state.isFilterActive ? .cyan : .white
        filterButton.setTitleColor(titleColor, for: .normal)
        updateCollectionInsets(isFilterHidden: filterButton.isHidden)
    }
    
    private func updateCollectionInsets(isFilterHidden: Bool) {
        let bottomInset = isFilterHidden ? 16 : (filterButtonHeight + 24)
        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    // MARK: - Data
    
    private func configureCell(_ cell: TrackerCell, at indexPath: IndexPath) {
        guard let cellViewModel = viewModel.cellViewModel(section: indexPath.section, item: indexPath.item) else { return }
        let color = UIColor(hex: cellViewModel.colorHex) ?? UIColor(resource: .appGrayOsn100)
        cell.configure(with: cellViewModel.tracker,
                       daysText: cellViewModel.daysText,
                       color: color,
                       isCompleted: cellViewModel.isCompleted,
                       isButtonEnabled: cellViewModel.isButtonEnabled)
        cell.plusAction = { [weak self] in
            guard let self else { return }
            self.reportMainEvent(event: "click", item: "track")
            self.viewModel.toggleCompletion(for: cellViewModel.tracker)
        }
    }
    
    private func presentDeleteConfirmation(for tracker: Tracker, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("Уверены что хотите удалить трекер?", comment: "Delete tracker confirmation"),
            preferredStyle: .actionSheet
        )
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("Удалить", comment: "Delete tracker"),
            style: .destructive
        ) { [weak self] _ in
            self?.viewModel.deleteTracker(tracker)
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Отмена", comment: "Cancel action"),
            style: .cancel
        )
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController,
           let cell = collectionView.cellForItem(at: indexPath) {
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
    
    private func presentEdit(for tracker: Tracker) {
        guard let categoryTitle = viewModel.categoryTitle(for: tracker) else {
            return
        }
        let availableCategories = viewModel.availableCategoryTitles()
        let controller: UIViewController
        if tracker.schedule.isEmpty {
            let vc = EditIrregularViewController(tracker: tracker,
                                                 categoryTitle: categoryTitle,
                                                 availableCategories: availableCategories)
            vc.editingDelegate = self
            controller = vc
        } else {
            let daysCount = viewModel.completedCount(for: tracker)
            let vc = EditHabitViewController(tracker: tracker,
                                             categoryTitle: categoryTitle,
                                             availableCategories: availableCategories,
                                             daysCount: daysCount)
            vc.editingDelegate = self
            controller = vc
        }
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

  }

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width
        let inset: CGFloat = 16 * 2
        let spacing: CGFloat = 9
        let columns: CGFloat = 2
        let width = (availableWidth - inset - spacing) / columns
        return CGSize(width: floor(width), height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                           withReuseIdentifier: TrackersSectionHeader.reuseIdentifier,
                                                                           for: indexPath) as? TrackersSectionHeader else {
            return UICollectionReusableView()
        }
        if let title = viewModel.sectionTitle(for: indexPath.section) {
            header.configure(title: title)
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard viewModel.sectionTitle(for: section) != nil else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: 22)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let tracker = viewModel.tracker(section: indexPath.section, item: indexPath.item) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { [weak self] _ in
            let pinTitleKey = tracker.isPinned ? "Открепить" : "Закрепить"
            let pinAction = UIAction(
                title: NSLocalizedString(pinTitleKey, comment: "Pin tracker action")
            ) { _ in
                self?.viewModel.togglePin(for: tracker)
            }
            
            let editAction = UIAction(
                title: NSLocalizedString("Редактировать", comment: "Edit tracker action")
            ) { _ in
                self?.reportMainEvent(event: "click", item: "edit")
                self?.presentEdit(for: tracker)
            }
            
            let deleteAction = UIAction(
                title: NSLocalizedString("Удалить", comment: "Delete tracker action"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.reportMainEvent(event: "click", item: "delete")
                self?.presentDeleteConfirmation(for: tracker, at: indexPath)
            }
            
            return UIMenu(children: [pinAction, editAction, deleteAction])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard
            let indexPath = configuration.identifier as? IndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell
        else {
            return nil
        }
        return UITargetedPreview(view: cell.contextPreviewTargetView)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard
            let indexPath = configuration.identifier as? IndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell
        else {
            return nil
        }
        return UITargetedPreview(view: cell.contextPreviewTargetView)
    }
}

extension TrackersViewController: UISearchBarDelegate {
    private func reportMainEvent(event: String, item: String? = nil) {
        var params: [String: Any] = [
            "event": event,
            "screen": "Main"
        ]
        
        if let item {
            params["item"] = item
        }
        
        AnalyticsService.report(event: "main_screen_event", params: params)
        logger.info("Analytics event: \(params)")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.updateSearch(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TrackersViewController: TrackerCreationDelegate {
    func trackerCreationDidCreate(_ tracker: Tracker, in categoryTitle: String) {
        viewModel.createTracker(tracker, in: categoryTitle)
    }
}

extension TrackersViewController: TrackerEditingDelegate {
    func trackerEditingDidUpdate(_ tracker: Tracker, in categoryTitle: String) {
        viewModel.updateTracker(tracker, in: categoryTitle)
    }
}

