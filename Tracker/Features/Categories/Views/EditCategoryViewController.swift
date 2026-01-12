import UIKit

protocol EditCategoryViewControllerDelegate: AnyObject {
    func editCategoryViewController(_ viewController: EditCategoryViewController,
                                    didUpdateFrom oldTitle: String,
                                    to newTitle: String)
}

final class EditCategoryViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: EditCategoryViewControllerDelegate?
    private let viewModel: NewCategoryViewModel
    private var state: NewCategoryState
    private let oldTitle: String
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17)
        textField.textColor = UIColor(resource: .appBlack)
        textField.backgroundColor = UIColor(resource: .appGrayOsn)
        textField.layer.cornerRadius = 16
        textField.placeholder = NSLocalizedString("Введите название категории", comment: "Category name placeholder")
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = leftPadding
        textField.leftViewMode = .always
        return textField
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Готово", comment: "Save category changes"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .appWhite), for: .normal)
        button.setTitleColor(.white, for: .disabled)
        button.backgroundColor = UIColor(resource: .appGray)
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    init(currentTitle: String) {
        self.oldTitle = currentTitle
        let vm = NewCategoryViewModel(initialTitle: currentTitle)
        self.viewModel = vm
        self.state = NewCategoryState(title: currentTitle)
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
        navigationItem.title = NSLocalizedString("Редактирование категории", comment: "Edit category title")
        bindViewModel()
        setupUI()
        setupKeyboardObservers()
        nameTextField.text = state.title
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(doneButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(nameTextField)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            nameTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupKeyboardObservers() {
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
    
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state: state)
        }
        viewModel.bind()
    }
    
    private func apply(state: NewCategoryState) {
        self.state = state
        updateDoneButtonState(isEnabled: state.isSaveEnabled && state.trimmedTitle.caseInsensitiveCompare(oldTitle) != .orderedSame)
    }
    
    // MARK: - Actions
    
    @objc private func textFieldEditingChanged() {
        viewModel.updateTitle(nameTextField.text ?? "")
    }
    
    @objc private func doneTapped() {
        guard let newTitle = viewModel.makeCategory() else { return }
        delegate?.editCategoryViewController(self, didUpdateFrom: oldTitle, to: newTitle)
        if let navController = navigationController, navController.presentingViewController != nil {
            navController.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let keyboardHeight = frame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        
        let textFieldFrame = nameTextField.convert(nameTextField.bounds, to: scrollView)
        let visibleRect = CGRect(x: 0, y: scrollView.contentOffset.y, width: scrollView.bounds.width, height: scrollView.bounds.height - keyboardHeight)
        
        if !visibleRect.contains(textFieldFrame) {
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve)) {
                self.scrollView.scrollRectToVisible(textFieldFrame, animated: false)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func updateDoneButtonState(isEnabled: Bool) {
        doneButton.isEnabled = isEnabled
        doneButton.backgroundColor = isEnabled
        ? UIColor(resource: .appBlack)
                  : UIColor(resource: .appGray)
    }
}

// MARK: - UITextFieldDelegate

extension EditCategoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if state.isSaveEnabled && state.trimmedTitle.caseInsensitiveCompare(oldTitle) != .orderedSame {
            doneTapped()
        }
        return true
    }
}

