import UIKit

class BaseTrackerCreationViewController: UIViewController {
    
    // MARK: - UI Elements
    
    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor(resource: .appBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17)
        textField.textColor = UIColor(resource: .appBlack)
        textField.backgroundColor = UIColor(resource: .appGrayOsn)
        textField.layer.cornerRadius = 16
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.placeholder = "Введите название трекера"
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(nameFieldEditingChanged), for: .editingChanged)
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = leftPadding
        textField.leftViewMode = .always
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightView = rightPadding
        textField.rightViewMode = .unlessEditing
        return textField
    }()
    
    let emojiTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = UIColor(resource: .appBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = gridSpacing
        layout.minimumInteritemSpacing = gridSpacing
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        collection.showsVerticalScrollIndicator = false
        collection.allowsMultipleSelection = false
        collection.isScrollEnabled = false
        collection.register(EmojiCollectionViewCell.self,
                            forCellWithReuseIdentifier: EmojiCollectionViewCell.reuseIdentifier)
        return collection
    }()
    
    let colorTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = UIColor(resource: .appBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = gridSpacing
        layout.minimumInteritemSpacing = gridSpacing
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        collection.showsVerticalScrollIndicator = false
        collection.allowsMultipleSelection = false
        collection.isScrollEnabled = false
        collection.register(ColorCollectionViewCell.self,
                            forCellWithReuseIdentifier: ColorCollectionViewCell.reuseIdentifier)
        return collection
    }()
    
    let characterLimitLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = .systemFont(ofSize: 17)
        label.textColor = UIColor(resource: .appRed)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var categoryButton: UIButton = {
        let button = createSelectionButton(title: "Категория", subtitle: nil)
        button.addTarget(self, action: #selector(categoryTapped), for: .touchUpInside)
        button.backgroundColor = UIColor(resource: .appGrayOsn)
        button.layer.cornerRadius = 16
        return button
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(resource: .appRed).cgColor
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(resource: .appGrayButton)
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    weak var creationDelegate: TrackerCreationDelegate?
    var availableCategories: [String] = []
    
    var selectedCategory: String? {
        didSet { updateCategorySubtitle() }
    }
    
    var selectedEmoji: String? {
        didSet { validateForm() }
    }
    
    var selectedColorHex: String? {
        didSet { validateForm() }
    }
    
    let nameLimit = 38
    let gridItemsPerRow = 6
    let gridSpacing: CGFloat = 0
    
    var emojiHeightConstraint: NSLayoutConstraint?
    var colorHeightConstraint: NSLayoutConstraint?
    var selectedEmojiIndexPath: IndexPath?
    var selectedColorIndexPath: IndexPath?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .appWhite)
        configureUI()
        setupKeyboardObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeights()
    }
    
    // MARK: - Abstract Methods
    
    /// Метод для получения расписания (переопределяется в подклассах)
    func getSchedule() -> [Weekday] {
        return []
    }
    
    /// Метод для проверки валидности расписания (переопределяется в подклассах)
    func isScheduleValid() -> Bool {
        return true
    }
    
    /// Метод для настройки UI элементов, специфичных для подкласса
    func setupSpecificUI() {
        // Переопределяется в подклассах
    }
    
    /// Метод для получения элемента, который должен быть выше emojiTitleLabel
    func getElementAboveEmojiTitle() -> UIView {
        return categoryButton
    }
    
    /// Метод для получения отступа сверху для emojiTitleLabel
    func getEmojiTitleTopSpacing() -> CGFloat {
        return 32
    }
    
    // MARK: - UI Setup
    
    func configureUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(nameContainer)
        contentView.addSubview(categoryButton)
        contentView.addSubview(emojiTitleLabel)
        contentView.addSubview(emojiCollectionView)
        contentView.addSubview(colorTitleLabel)
        contentView.addSubview(colorCollectionView)
        
        nameContainer.addArrangedSubview(nameTextField)
        nameContainer.addArrangedSubview(characterLimitLabel)
        
        setupSpecificUI()
        
        let elementAboveEmoji = getElementAboveEmojiTitle()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            nameContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            categoryButton.topAnchor.constraint(equalTo: characterLimitLabel.bottomAnchor, constant: 24),
            categoryButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryButton.heightAnchor.constraint(equalToConstant: 75),
            
            emojiTitleLabel.topAnchor.constraint(equalTo: elementAboveEmoji.bottomAnchor, constant: getEmojiTitleTopSpacing()),
            emojiTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            emojiTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emojiCollectionView.topAnchor.constraint(equalTo: emojiTitleLabel.bottomAnchor, constant: 16),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -19),
            
            colorTitleLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 16),
            colorTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            colorTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            colorCollectionView.topAnchor.constraint(equalTo: colorTitleLabel.bottomAnchor, constant: 16),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -19),
            colorCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.widthAnchor.constraint(equalTo: createButton.widthAnchor),
            
            createButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        emojiHeightConstraint = emojiCollectionView.heightAnchor.constraint(equalToConstant: 0)
        emojiHeightConstraint?.isActive = true
        colorHeightConstraint = colorCollectionView.heightAnchor.constraint(equalToConstant: 0)
        colorHeightConstraint?.isActive = true
    }
    
    func updateCollectionViewHeights() {
        let availableWidth = max(view.bounds.width - 32, 0)
        emojiHeightConstraint?.constant = calculatedHeight(availableWidth: availableWidth,
                                                           itemCount: MockData.emojis.count)
        colorHeightConstraint?.constant = calculatedHeight(availableWidth: availableWidth,
                                                           itemCount: MockData.colors.count)
    }
    
    func calculatedHeight(availableWidth: CGFloat, itemCount: Int) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        let itemWidth = itemWidth(forAvailableWidth: availableWidth)
        let rows = Int(ceil(Double(itemCount) / Double(max(gridItemsPerRow, 1))))
        let spacing = CGFloat(max(rows - 1, 0)) * gridSpacing
        return CGFloat(rows) * itemWidth + spacing
    }
    
    func calculateItemWidth(for collectionView: UICollectionView) -> CGFloat {
        let width = collectionView.bounds.width > 0
            ? collectionView.bounds.width
            : max(view.bounds.width - 32, 0)
        return itemWidth(forAvailableWidth: width)
    }
    
    func itemWidth(forAvailableWidth availableWidth: CGFloat) -> CGFloat {
        let items = CGFloat(max(gridItemsPerRow, 1))
        let totalSpacing = CGFloat(max(gridItemsPerRow - 1, 0)) * gridSpacing
        let usableWidth = availableWidth - totalSpacing
        guard usableWidth > 0 else { return 44 }
        return floor(usableWidth / items)
    }
    
    func handleEmojiSelection(at indexPath: IndexPath) {
        if selectedEmojiIndexPath == indexPath { return }
        let previous = selectedEmojiIndexPath
        selectedEmojiIndexPath = indexPath
        selectedEmoji = MockData.emojis[indexPath.item]
        var toReload = [indexPath]
        if let previous = previous {
            toReload.append(previous)
        }
        emojiCollectionView.reloadItems(at: toReload)
    }
    
    func handleColorSelection(at indexPath: IndexPath) {
        if selectedColorIndexPath == indexPath { return }
        let previous = selectedColorIndexPath
        selectedColorIndexPath = indexPath
        selectedColorHex = MockData.colors[indexPath.item]
        var toReload = [indexPath]
        if let previous = previous {
            toReload.append(previous)
        }
        colorCollectionView.reloadItems(at: toReload)
    }
    
    func createSelectionButton(title: String, subtitle: String?) -> UIButton {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let mainTitle = UILabel()
        mainTitle.text = title
        mainTitle.font = .systemFont(ofSize: 17)
        mainTitle.textColor = UIColor(resource: .appBlack)
        
        stackView.addArrangedSubview(mainTitle)
        
        if let subtitle = subtitle {
            let s = UILabel()
            s.text = subtitle
            s.font = .systemFont(ofSize: 17)
            s.textColor = UIColor(resource: .appGray)
            stackView.addArrangedSubview(s)
        }
        
        button.addSubview(stackView)
        
        let chevron = UIImageView(image: UIImage(resource: .right))
        chevron.tintColor = UIColor(resource: .appGray)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),
            
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 24),
            chevron.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return button
    }
    
    // MARK: - Subtitle updates
    
    func updateCategorySubtitle() {
        updateButton(categoryButton, subtitle: selectedCategory)
    }
    
    func updateButton(_ button: UIButton, subtitle: String?) {
        guard let stack = button.subviews.first(where: { $0 is UIStackView }) as? UIStackView else { return }
        
        // Оставляем первый label (title), остальные убираем
        while stack.arrangedSubviews.count > 1 {
            stack.arrangedSubviews.last?.removeFromSuperview()
        }
        
        if let subtitle = subtitle {
            let s = UILabel()
            s.font = .systemFont(ofSize: 17)
            s.textColor = .systemGray
            s.text = subtitle
            stack.addArrangedSubview(s)
        }
        
        validateForm()
    }
    
    // MARK: - Keyboard
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height
        scrollView.verticalScrollIndicatorInsets.bottom = frame.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @objc func nameFieldEditingChanged() {
        updateNameLimitLabel(for: nameTextField.text ?? "")
        validateForm()
    }
    
    func updateNameLimitLabel(for text: String) {
        characterLimitLabel.isHidden = text.count <= nameLimit
    }
    
    @objc func categoryTapped() {
        let controller = CategorySelectionViewController(categories: availableCategories,
                                                         selectedCategory: selectedCategory)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true)
    }
    
    @objc func cancelTapped() {
        dismissCreationFlow()
    }
    
    @objc func createTapped() {
        guard
            let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !title.isEmpty,
            let category = selectedCategory,
            let emoji = selectedEmoji,
            let colorHex = selectedColorHex
        else { return }
        
        let tracker = Tracker(id: UUID(),
                              title: title,
                              colorHex: colorHex,
                              emoji: emoji,
                              schedule: getSchedule())
        creationDelegate?.trackerCreationDidCreate(tracker, in: category)
        dismissCreationFlow()
    }
    
    func validateForm() {
        let trimmedName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let nameValid = !trimmedName.isEmpty
        let categoryValid = selectedCategory != nil
        let scheduleValid = isScheduleValid()
        let emojiValid = selectedEmoji != nil
        let colorValid = selectedColorHex != nil
        
        let valid = nameValid && categoryValid && scheduleValid && emojiValid && colorValid
        
        createButton.isEnabled = valid
        createButton.backgroundColor = valid
            ? UIColor(resource: .appBlack)
            : UIColor(resource: .appGray)
    }
    
    func dismissCreationFlow() {
        if let nav = navigationController {
            nav.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

// MARK: - UITextFieldDelegate

extension BaseTrackerCreationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }
        let updatedText = current.replacingCharacters(in: stringRange, with: string)
        updateNameLimitLabel(for: updatedText)
        return updatedText.count <= nameLimit
    }
}

// MARK: - CategorySelectionViewControllerDelegate

extension BaseTrackerCreationViewController: CategorySelectionViewControllerDelegate {
    func categorySelection(_ viewController: CategorySelectionViewController,
                           didSelect category: String,
                           categories: [String]) {
        availableCategories = categories
        selectedCategory = category
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension BaseTrackerCreationViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return MockData.emojis.count
        }
        return MockData.colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? EmojiCollectionViewCell else {
                return UICollectionViewCell()
            }
            let emoji = MockData.emojis[indexPath.item]
            cell.configure(with: emoji, isSelected: indexPath == selectedEmojiIndexPath)
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ColorCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? ColorCollectionViewCell else {
            return UICollectionViewCell()
        }
        let hex = MockData.colors[indexPath.item]
        cell.configure(hex: hex, isSelected: indexPath == selectedColorIndexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            handleEmojiSelection(at: indexPath)
        } else {
            handleColorSelection(at: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = calculateItemWidth(for: collectionView)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return gridSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return gridSpacing
    }
}

// MARK: - Collection View Cells

private final class EmojiCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "EmojiCollectionViewCell"
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.backgroundColor = UIColor(resource: .appWhite)
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    func configure(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        updateSelectionAppearance(isSelected: isSelected)
    }
    
    private func updateSelectionAppearance(isSelected: Bool) {
        contentView.backgroundColor = isSelected
            ? UIColor(resource: .appGrayOsn100)
            : UIColor(resource: .appWhite)
    }
}

private final class ColorCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorCollectionViewCell"
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let innerInset: CGFloat = 6
    private var currentColor: UIColor?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(colorView)
        
        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: innerInset),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: innerInset),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -innerInset),
            colorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -innerInset)
        ])
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    func configure(hex: String, isSelected: Bool) {
        let color = UIColor(hex: hex) ?? UIColor(resource: .appGrayOsn100)
        currentColor = color
        colorView.backgroundColor = color
        updateSelectionAppearance(isSelected: isSelected)
    }
    
    private func updateSelectionAppearance(isSelected: Bool) {
        guard let color = currentColor else {
            contentView.backgroundColor = .clear
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
            return
        }
        
        contentView.backgroundColor = isSelected ? color.withAlphaComponent(0.0) : .clear
        contentView.layer.borderWidth = isSelected ? 3 : 0
        contentView.layer.borderColor = isSelected ? color.withAlphaComponent(0.3).cgColor : nil
    }
}

