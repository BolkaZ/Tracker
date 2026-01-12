#if canImport(XCTest) && canImport(SnapshotTesting)
import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackerTests: XCTestCase {

    func testTrackerTabSnapshot() {
        let tab = MainTabBarController()
        tab.loadViewIfNeeded()
        assertSnapshot(of: tab, as: .image)
    }
    
    func testStatsTabSnapshot() {
        let tab = MainTabBarController()
        tab.loadViewIfNeeded()
        tab.selectedIndex = 1
        assertSnapshot(of: tab, as: .image)
    }
    
    func testOnboardingSnapshot1() {
        let vc = OnboardingPageViewController()
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testOnboardingSnapshot2() {
        let vc = OnboardingPageViewController()
        vc.loadViewIfNeeded()
        if
            let first = vc.viewControllers?.first,
            let next = vc.pageViewController(vc, viewControllerAfter: first)//переключение на второй экран онборда напрямую через UIPageViewController API
        {
            vc.setViewControllers([next], direction: .forward, animated: false)
        }
        assertSnapshot(of: vc, as: .image)
    }
    
    func testFiltersSnapshot() {
        let vc = FiltersViewController(selectedFilter: .completed)//необходимо выбрать фильтр
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testFilterUncompletedSnapshot() {
        let vc = FiltersViewController(selectedFilter: .uncompleted)//необходимо выбрать фильтр
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testFilterTodaySnapshot() {
        let vc = FiltersViewController(selectedFilter: .today)//необходимо выбрать фильтр галочка ставится не должна так как переход осуществляется к сегодняшнему дню
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testFilterAllSnapshot() {
        let vc = FiltersViewController(selectedFilter: .all)//необхрдимо выбрать фильтр
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testCreateTrackerTypeSheetSnapshot() {
        let vm = CreateTrackerTypeViewModel(categories: [])
        let vc = CreateTrackerTypeViewController(viewModel: vm)
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testCreateHabitSnapshot() {
        let vm = TrackerCreationViewModel(type: .habit)
        let vc = CreateHabitViewController(viewModel: vm)
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    func testCreateIrregularSnapshot() {
        let vm = TrackerCreationViewModel(type: .irregular)
        let vc = CreateIrregularViewController(viewModel: vm)
        vc.loadViewIfNeeded()
        assertSnapshot(of: vc, as: .image)
    }
    
    //Не Удается указать эмодзи, цвет, категорию
    func testEditHabitSnapshot() {
        let tracker = Tracker(
            id: UUID(),
            title: "Бег утром",
            colorHex: "#FD4C49",
            emoji: "🙂",
            schedule: [.monday, .wednesday, .friday]
        )
        let vc = EditHabitViewController(
            tracker: tracker,
            categoryTitle: "Здоровье",
            availableCategories: ["Здоровье"],
            daysCount: 17
        )
        vc.loadViewIfNeeded()
        vc.viewModel.updateCategory("Здоровье", categories: ["Здоровье"])
        assertSnapshot(of: vc, as: .image)
    }
    
    //Не Удается указать эмодзи, цвет, категорию
    func testEditIrregularSnapshot() {
        let tracker = Tracker(
            id: UUID(),
            title: "Звонок бабушке",
            colorHex: MockData.colors.last ?? "#2FD058",
            emoji: MockData.emojis.last ?? "😪",
            schedule: []
        )
        let vc = EditIrregularViewController(
            tracker: tracker,
            categoryTitle: "Семья",
            availableCategories: ["Семья"]
        )
        vc.loadViewIfNeeded()
        vc.viewModel.updateCategory("Семья", categories: ["Семья"])
        assertSnapshot(of: vc, as: .image)
    }
    
    func testScheduleSnapshot() {
        let vm = ScheduleViewModel(selectedWeekdays: [.monday, .wednesday, .friday])
        let vc = ScheduleViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.loadViewIfNeeded()
        assertSnapshot(of: nav, as: .image)
    }
    
    func testCategorySelectionSnapshot() {
        let vm = CategorySelectionViewModel(selectedCategory: nil)
        let vc = CategorySelectionViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.loadViewIfNeeded()
        assertSnapshot(of: nav, as: .image)
    }
    
    func testNewCategorySnapshot() {
        let vc = NewCategoryViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.loadViewIfNeeded()
        assertSnapshot(of: nav, as: .image)
    }
    
}
#endif
