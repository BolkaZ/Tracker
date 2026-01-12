import UIKit

final class TrackerCell: UICollectionViewCell {
    static let identifier = "TrackerCell"
    
    /// View to use for context menu highlight/preview (color block only)
    var contextPreviewTargetView: UIView { colorView }
    
    // MARK: - UI
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.backgroundColor = .clear
        return view
    }()
    
    private let colorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let footerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(resource: .appWhite)
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let emojiBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let baseColor = UIColor(resource: .appWhite)
        view.backgroundColor = baseColor.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pinImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(resource: .pin))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .appBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(resource: .appWhite)
        button.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.layer.cornerRadius = 17
        button.clipsToBounds = true
        return button
    }()
    
    var plusAction: (() -> Void)?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        plusAction = nil
        pinImageView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 16).cgPath
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        contentView.addSubview(containerView)
        containerView.addSubview(colorView)
        containerView.addSubview(footerView)
        colorView.addSubview(emojiBackground)
        emojiBackground.addSubview(emojiLabel)
        colorView.addSubview(pinImageView)
        colorView.addSubview(titleLabel)
        footerView.addSubview(daysLabel)
        footerView.addSubview(plusButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            colorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 90),
            
            footerView.topAnchor.constraint(equalTo: colorView.bottomAnchor),
            footerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 58),
            
            emojiBackground.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            emojiBackground.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            emojiBackground.heightAnchor.constraint(equalToConstant: 24),
            emojiBackground.widthAnchor.constraint(equalToConstant: 24),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),
            
            pinImageView.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            pinImageView.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -4),
            
            titleLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: colorView.bottomAnchor, constant: -12),
            
            daysLabel.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
            daysLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 12),
            
            plusButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 8),
            plusButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configure
    
    func configure(with tracker: Tracker,
                   daysText: String,
                   color: UIColor,
                   isCompleted: Bool,
                   isButtonEnabled: Bool) {
        colorView.backgroundColor = color
        titleLabel.text = tracker.title
        emojiLabel.text = tracker.emoji
        daysLabel.text = daysText
        pinImageView.isHidden = !tracker.isPinned
        updatePlusButton(color: color, isCompleted: isCompleted, isEnabled: isButtonEnabled)
    }
    
    private func updatePlusButton(color: UIColor, isCompleted: Bool, isEnabled: Bool) {
        let symbolName = isCompleted ? "checkmark" : "plus"
        let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        plusButton.setImage(UIImage(systemName: symbolName, withConfiguration: configuration), for: .normal)
        plusButton.backgroundColor = color
        plusButton.isEnabled = isEnabled
        if isEnabled {
            plusButton.alpha = isCompleted ? 0.3 : 1.0
        } else {
            plusButton.alpha = 0.3
        }
    }
    
    // MARK: - Actions
    
    @objc private func didTapPlus() {
        plusAction?()
    }
}
