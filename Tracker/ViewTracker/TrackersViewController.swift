import UIKit

class TrackersViewController: UIViewController{

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
        let item = UIBarButtonItem(image: UIImage(named: "Plus"),
                                   style: .plain,
                                   target: self,
                                   action: #selector(addTapped))
        item.tintColor = UIColor(named: "AppBlack")
        return item
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Поиск"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        
        sb.searchTextField.textColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 1.0)
        sb.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Поиск",
            attributes: [
                .foregroundColor: UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 17)
            ]
        )
        
        if let glassIconView = sb.searchTextField.leftView as? UIImageView {
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1.0)
        }
        
        return sb
    }()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Star"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(named: "AppBlack")
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

    private var filteredCategories: [TrackerCategory] = []
    private var searchText: String = ""
    private let calendar = Calendar.current
    var currentDate: Date = Date()
    
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
        
        view.backgroundColor = .white
        configureNavigationBar()
        setupLayout()
        searchBar.delegate = self

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        loadMockData()
        currentDate = normalized(date: Date())
        datePicker.date = currentDate
        applyFilters()
        
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
    
    func updateEmptyState() {
        let hasTrackers = filteredCategories.flatMap { $0.trackers }.isEmpty == false
        emptyImageView.isHidden = hasTrackers
        emptyLabel.isHidden = hasTrackers
        collectionView.isHidden = !hasTrackers
    }
    
    private func applyFilters() {
        let selectedDate = currentDate
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let weekday = Weekday.from(date: selectedDate, calendar: calendar) else {
            filteredCategories = []
            collectionView.reloadData()
            updateEmptyState()
            return
        }
        
        filteredCategories = categories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                let matchesSearch = normalizedSearch.isEmpty || tracker.title.lowercased().contains(normalizedSearch)
                let matchesSchedule = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
                return matchesSearch && matchesSchedule
            }
            return trackers.isEmpty ? nil : TrackerCategory(title: category.title, trackers: trackers)
        }
        
        collectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - Actions
    
    @objc private func addTapped() {
        let vc = CreateTrackerTypeViewController()
        vc.creationDelegate = self
        vc.availableCategories = categories.reduce(into: [String]()) { result, category in
            if !result.contains(category.title) {
                result.append(category.title)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func dateChanged() {
        currentDate = normalized(date: datePicker.date)
        applyFilters()
    }
    
    // MARK: - Data
    var categories: [TrackerCategory] = []
    var completedTrackers: [TrackerRecord] = []
    private var completedTrackerSet: Set<TrackerRecord> = []

    func complete(tracker: Tracker, on date: Date) {
        let normalizedDate = normalized(date: date)
        let record = TrackerRecord(trackerId: tracker.id, date: normalizedDate)
        guard !completedTrackerSet.contains(record) else { return }
        completedTrackers.append(record)
        completedTrackerSet.insert(record)
    }

    func uncomplete(tracker: Tracker, on date: Date) {
        let normalizedDate = normalized(date: date)
        let record = TrackerRecord(trackerId: tracker.id, date: normalizedDate)
        completedTrackers.removeAll {
            $0.trackerId == tracker.id && calendar.isDate($0.date, inSameDayAs: normalizedDate)
        }
        completedTrackerSet.remove(record)
    }

    // Для теста 
    func loadMockData() {
        let plants = Tracker(
            id: UUID(),
            title: "Поливать растения",
            colorHex: "#34C759",
            emoji: "😪",
            schedule: Weekday.allCases
        )
        let running = Tracker(
            id: UUID(),
            title: "Бег 3 км",
            colorHex: "#FD4C49",
            emoji: "🏃‍♂️",
            schedule: [.monday, .wednesday, .friday]
        )
        let reading = Tracker(
            id: UUID(),
            title: "Чтение 30 мин",
            colorHex: "#4ECDC4",
            emoji: "📖",
            schedule: [.tuesday, .thursday, .saturday]
        )
        let cozyCategory = TrackerCategory(title: "Домашний уют", trackers: [plants])
        let healthCategory = TrackerCategory(title: "Здоровье", trackers: [running])
        let hobbyCategory = TrackerCategory(title: "Саморазвитие", trackers: [reading])
        categories = [cozyCategory, healthCategory, hobbyCategory]
    }
    
    private func normalized(date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }

    private func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        let record = TrackerRecord(trackerId: tracker.id, date: date)
        return completedTrackerSet.contains(record)
    }
    
    private func completedCount(for tracker: Tracker) -> Int {
        return completedTrackers.filter { $0.trackerId == tracker.id }.count
    }
    
    private func isFuture(date: Date) -> Bool {
        let today = normalized(date: Date())
        let selected = normalized(date: date)
        return selected > today
    }
    
    private func formattedDaysText(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        let suffix: String
        if remainder100 >= 11 && remainder100 <= 14 {
            suffix = "дней"
        } else {
            switch remainder10 {
            case 1:
                suffix = "день"
            case 2...4:
                suffix = "дня"
            default:
                suffix = "дней"
            }
        }
        return "\(count) \(suffix)"
    }
    
    private func color(for tracker: Tracker) -> UIColor {
        return UIColor(hex: tracker.colorHex) ?? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    }
    
    private func configureCell(_ cell: TrackerCell, with tracker: Tracker, on date: Date) {
        let normalizedDate = normalized(date: date)
        let isCompleted = isTrackerCompleted(tracker, on: normalizedDate)
        let count = completedCount(for: tracker)
        let daysText = formattedDaysText(for: count)
        let color = color(for: tracker)
        let buttonEnabled = !isFuture(date: date)
        
        cell.configure(with: tracker,
                       daysText: daysText,
                       color: color,
                       isCompleted: isCompleted,
                       isButtonEnabled: buttonEnabled)
    }

  }

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return filteredCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = filteredCategories[indexPath.section].trackers[indexPath.item]
        configureCell(cell, with: tracker, on: currentDate)
        
        cell.plusAction = { [weak self, weak collectionView, weak cell] in
            guard let self = self else { return }
            guard !self.isFuture(date: self.currentDate) else { return }
            let targetDate = self.normalized(date: self.currentDate)
            if self.isTrackerCompleted(tracker, on: targetDate) {
                self.uncomplete(tracker: tracker, on: targetDate)
            } else {
                self.complete(tracker: tracker, on: targetDate)
            }
            
            if let cell = cell {
                self.configureCell(cell, with: tracker, on: self.currentDate)
            }
            
            guard let collectionView = collectionView else {
                self.collectionView.reloadData()
                return
            }
            if indexPath.section < self.filteredCategories.count,
               indexPath.item < self.filteredCategories[indexPath.section].trackers.count {
                collectionView.reloadItems(at: [indexPath])
            } else {
                self.collectionView.reloadData()
            }
        }
        
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
        header.configure(title: filteredCategories[indexPath.section].title)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section < filteredCategories.count else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: 22)
    }
}

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        applyFilters()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TrackersViewController: TrackerCreationDelegate {
    func trackerCreationDidCreate(_ tracker: Tracker, in categoryTitle: String) {
        var updatedCategories = categories
        if let index = updatedCategories.firstIndex(where: { $0.title == categoryTitle }) {
            var trackers = updatedCategories[index].trackers
            trackers.append(tracker)
            let updatedCategory = TrackerCategory(title: categoryTitle, trackers: trackers)
            updatedCategories[index] = updatedCategory
        } else {
            updatedCategories.append(TrackerCategory(title: categoryTitle, trackers: [tracker]))
        }
        categories = updatedCategories
        applyFilters()
    }
}
