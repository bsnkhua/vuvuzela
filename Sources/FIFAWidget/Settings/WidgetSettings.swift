import Foundation

enum WidgetSettings {
    static let backgroundOpacityKey = "backgroundOpacity"
    static let defaultOpacity: Double = 0.92
    static let positionLockedKey = "positionLocked"
    static let widgetWidthKey = "widgetWidth"
    static let defaultWidth: Double = 900
    static let minWidth: Double = 720
    static let maxWidth: Double = 1200
    static let favoriteTeamsKey = "favoriteTeams"
    static let launchAtLoginKey = "launchAtLogin"
    static let activeTabKey = "activeTab"

    static func clampWidth(_ w: Double) -> Double { min(max(w, minWidth), maxWidth) }
    static func clampOpacity(_ o: Double) -> Double { min(max(o, 0.3), 1.0) }

    static var favoriteTeams: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: favoriteTeamsKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: favoriteTeamsKey)
        }
    }
}
