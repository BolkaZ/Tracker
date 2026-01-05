import UIKit

final class OnboardingPageViewController: UIPageViewController {
    
    static let completionKey = "hasCompletedOnboarding"
    
    var onFinish: (() -> Void)?
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Отслеживайте только то, что хотите",
            imageName: "Onbord1"
        ),
        OnboardingPage(
            title: "Даже если это не литры воды и йога",
            imageName: "Onbord2"
        )
    ]
    
    private lazy var controllers: [OnboardingContentViewController] = pages.map { OnboardingContentViewController(page: $0) }
    
    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.currentPageIndicatorTintColor = UIColor(resource: .appBlack)
        control.pageIndicatorTintColor = UIColor(resource: .appGrayOsn100)
        return control
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Вот это технологии!", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.black
        button.layer.cornerRadius = 16
        return button
    }()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) has not been implemented")
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        pageControl.numberOfPages = controllers.count
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        
        if let first = controllers.first {
            setViewControllers([first], direction: .forward, animated: false)
            pageControl.currentPage = 0
        }
        
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            skipButton.heightAnchor.constraint(equalToConstant: 60),
            
            pageControl.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func index(for viewController: UIViewController?) -> Int? {
        guard let target = viewController as? OnboardingContentViewController else { return nil }
        return controllers.firstIndex { $0 === target }
    }
    
    @objc private func skipTapped() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.completionKey)
        onFinish?()
    }
}

extension OnboardingPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = index(for: viewController),
              index - 1 >= 0 else {
            return nil
        }
        return controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = index(for: viewController),
              index + 1 < controllers.count else {
            return nil
        }
        return controllers[index + 1]
    }
}

extension OnboardingPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        if let index = index(for: pageViewController.viewControllers?.first) {
            pageControl.currentPage = index
        }
    }
}

