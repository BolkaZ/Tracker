import UIKit

final class FiltersViewController: UIViewController {
    
    var onSelectFilter: ((TrackersFilter) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Фильтры", comment: "Filters screen title")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor(resource: .appBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        return table
    }()
    
    private var selectedFilter: TrackersFilter
    private let filters = TrackersFilter.allCases
    
    init(selectedFilter: TrackersFilter) {
        self.selectedFilter = selectedFilter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(resource: .appWhite)
        
        tableView.rowHeight = 75
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(resource: .appWhite)
        tableView.tintColor = UIColor(resource: .appBlue)
        tableView.register(FiltersCell.self, forCellReuseIdentifier: FiltersCell.reuseIdentifier)
        
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FiltersCell.reuseIdentifier, for: indexPath) as? FiltersCell else {
            return UITableViewCell()
        }
        let filter = filters[indexPath.row]
        let shouldCheck = filter.showsCheckmark && filter == selectedFilter
        let showsSeparator = indexPath.row < filters.count - 1
        cell.configure(title: filter.title, isSelected: shouldCheck, showsSeparator: showsSeparator)
        return cell
    }
}

extension FiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let filter = filters[indexPath.row]
        selectedFilter = filter
        onSelectFilter?(filter)
        dismiss(animated: true)
    }
}
