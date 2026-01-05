import UIKit

final class TrackersViewController: UIViewController{

    // MARK: - UI Elements

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
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
        sb.placeholder = "Поиск"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        
        sb.searchTextField.textColor = UIColor(resource: .appBlack)
        
        sb.searchTextField.backgroundColor = UIColor(resource: .appSearchBackgraund)

        sb.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Поиск",
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
        label.text = "Что будем отслеживать?"
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
        return cv
    }()

    private let viewModel = TrackersViewModel()
    
    private func configureNavigationBar() {
        title = "Трекеры"
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
    }
    
    private func setupKeyboardDismiss() {
        // Скрываем клавиатуру при тапе на view
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
                self.updateEmptyState(hasTrackers: state.hasTrackers)
                self.datePicker.date = self.viewModel.currentDate
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
    }
    
    private func updateEmptyState(hasTrackers: Bool) {
        emptyImageView.isHidden = hasTrackers
        emptyLabel.isHidden = hasTrackers
        collectionView.isHidden = !hasTrackers
    }

    // MARK: - Actions
    
    @objc private func addTapped() {
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
            self?.viewModel.toggleCompletion(for: cellViewModel.tracker)
        }
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
}

extension TrackersViewController: UISearchBarDelegate {
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

