import Foundation
import UIKit

extension UIView {
    func addSubviews(_ subviews: UIView...) {
        subviews.forEach {addSubview($0)}
    }
}

final class TrackersViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews(searchBar,
                    starImage,
                    subLabel)
        view.backgroundColor = .white
        setupUI()
        configureNavigationBar()

    }
    
    private let searchBar = UISearchBar()
    private let starImage = UIImageView()
    private let subLabel = UILabel()
    private let addButton = UIBarButtonItem()
    
    func setupUI() {
        setupSubLabel()
        setupSearchBar()
        setupStarImage()
        setupAddButton()
    }
    
    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.textColor = .black
        searchBar.searchTextField.tintColor = UIColor(named: "Gray")
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Поиск",
            attributes: [
                .foregroundColor: UIColor(named: "Gray"),
                .font: UIFont.systemFont(ofSize: 17)
            ]
        )
        
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
    }
    
    private func setupStarImage() {
        starImage.translatesAutoresizingMaskIntoConstraints = false
        
        starImage.image = UIImage(named: "StarImage")
        
        starImage.widthAnchor.constraint(equalToConstant: 80).isActive = true
        starImage.heightAnchor.constraint(equalToConstant: 80).isActive = true
        starImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        starImage.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 220).isActive = true
    }
    
    private func setupSubLabel() {
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subLabel.text = "Что будем отслеживать?"
        subLabel.font = .systemFont(ofSize: 12, weight: .medium)
        
        subLabel.topAnchor.constraint(equalTo: starImage.bottomAnchor, constant: 8).isActive = true
        subLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    private func setupAddButton() {
        addButton.image = UIImage(named: "Plus")
        addButton.tintColor = .black
    }
    
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
    
    private func configureNavigationBar() {
        title = "Трекеры"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }
}
