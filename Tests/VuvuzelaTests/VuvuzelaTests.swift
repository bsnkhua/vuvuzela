import Foundation
import Testing
@testable import VuvuzelaCore

@Suite("FlagEmoji")
struct FlagEmojiTests {
    @Test func knownFlags() {
        #expect(FlagEmoji.flag(for: "BRA") == "🇧🇷")
        #expect(FlagEmoji.flag(for: "USA") == "🇺🇸")
        #expect(FlagEmoji.flag(for: "ENG") == "🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        #expect(FlagEmoji.flag(for: "SCO") == "🏴󠁧󠁢󠁳󠁣󠁴󠁿")
    }

    @Test func unknownFallback() {
        #expect(FlagEmoji.flag(for: "XYZ") == "🏳️")
    }
}

@Suite("QualificationStatus")
struct QualificationStatusTests {
    @Test func cases() {
        // Verify all cases exist and are distinct
        let all: [TeamRow.QualificationStatus] = [.direct, .bestThirdIn, .bestThirdOut, .eliminated, .unknown]
        #expect(all.count == 5)
    }
}

@Suite("BracketPlaceholder")
struct BracketTests {
    @Test func placeholderRounds() {
        let rounds = BracketRound.placeholder()
        #expect(rounds.count == 6)
        #expect(rounds.first?.id == "r32")
        #expect(rounds.first?.matches.count == 16)
    }
}

@Suite("VersionCompare")
struct VersionCompareTests {
    @Test func newerVersion() {
        #expect(isNewerVersion("v1.1.0", than: "1.0.0"))
        #expect(isNewerVersion("v2.0.0", than: "1.9.9"))
        #expect(!isNewerVersion("v1.0.0", than: "1.0.0"))
        #expect(!isNewerVersion("v0.9.0", than: "1.0.0"))
    }
}

@Suite("WidgetVisibility")
struct WidgetVisibilityTests {
    @Test func defaultsToVisibleWhenKeyAbsent() {
        let name = "test.visibility.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removeSuite(named: name) }
        // Key not set at all — must default to true
        #expect(WidgetSettings.isVisible(in: defaults))
    }

    @Test func respectsExplicitFalse() {
        let name = "test.visibility.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removeSuite(named: name) }
        defaults.set(false, forKey: WidgetSettings.widgetVisibleKey)
        #expect(!WidgetSettings.isVisible(in: defaults))
    }

    @Test func respectsExplicitTrue() {
        let name = "test.visibility.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removeSuite(named: name) }
        defaults.set(true, forKey: WidgetSettings.widgetVisibleKey)
        #expect(WidgetSettings.isVisible(in: defaults))
    }
}
