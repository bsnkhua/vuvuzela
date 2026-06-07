import Testing
@testable import Vuvuzela

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
    @Test func colorMapping() {
        #expect(TeamRow.QualificationStatus.direct.indicatorColor == "#81D6AC")
        #expect(TeamRow.QualificationStatus.bestThird.indicatorColor == "#B5E7CE")
        #expect(TeamRow.QualificationStatus.eliminated.indicatorColor == "#FF7F84")
        #expect(TeamRow.QualificationStatus.unknown.indicatorColor == nil)
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
