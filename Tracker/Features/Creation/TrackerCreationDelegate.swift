import Foundation

protocol TrackerCreationDelegate: AnyObject {
    func trackerCreationDidCreate(_ tracker: Tracker, in categoryTitle: String)
}

