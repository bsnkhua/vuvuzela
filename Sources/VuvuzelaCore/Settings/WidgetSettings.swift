import Foundation

public enum WidgetSettings {
    public static let backgroundOpacityKey = "backgroundOpacity"
    public static let defaultOpacity: Double = 0.92
    public static let positionLockedKey = "positionLocked"
    public static let widgetWidthKey = "widgetWidth"
    public static let defaultWidth: Double = 900
    public static let minWidth: Double = 720
    public static let maxWidth: Double = 1200
    public static let favoriteTeamsKey = "favoriteTeams"
    public static let launchAtLoginKey = "launchAtLogin"
    public static let activeTabKey = "activeTab"
    public static let highlightLiveResultsKey = "highlightLiveResults"   // default: on
    public static let soundEnabledKey = "soundEnabled"                   // default: on
    public static let widgetVisibleKey = "widgetVisible"                 // default: on

    public static func isVisible(in defaults: UserDefaults) -> Bool {
        defaults.object(forKey: widgetVisibleKey) == nil
            ? true
            : defaults.bool(forKey: widgetVisibleKey)
    }

    public static func clampWidth(_ w: Double) -> Double { min(max(w, minWidth), maxWidth) }
    public static func clampOpacity(_ o: Double) -> Double { min(max(o, 0.3), 1.0) }

    // Defaults to true when never set (UserDefaults.bool would return false).
    public static var soundEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: soundEnabledKey) == nil
                ? true
                : UserDefaults.standard.bool(forKey: soundEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: soundEnabledKey) }
    }

    public static var favoriteTeams: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: favoriteTeamsKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: favoriteTeamsKey)
        }
    }
}
