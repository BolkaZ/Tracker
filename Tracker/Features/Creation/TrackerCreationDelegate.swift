import Foundation

protocol TrackerCreationDelegate: AnyObject {
    func trackerCreationDidCreate(_ tracker: Tracker, in categoryTitle: String)
}

protocol TrackerEditingDelegate: AnyObject {
    func trackerEditingDidUpdate(_ tracker: Tracker, in categoryTitle: String)
}

