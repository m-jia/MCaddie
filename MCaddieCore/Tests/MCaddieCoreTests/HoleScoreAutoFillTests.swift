import Testing
@testable import MCaddieCore

@Suite("HoleScore AutoFill Tests")
struct HoleScoreAutoFillTests {

    /// 模拟用户依次选择杆数、推杆、FH
    private func score(par: Int, strokes: Int, putts: Int? = nil, fairway: TargetResult? = nil) -> HoleScore {
        var score = HoleScore(holeNumber: 1, par: par)
        score.strokes = strokes
        score.autoFill(after: .strokes)
        if let putts {
            score.putts = putts
            score.autoFill(after: .putts)
        }
        if let fairway {
            score.fairway = fairway
            score.autoFill(after: .fairway)
        }
        return score
    }

    @Test("Par selects 2 putts, FH and GIR")
    func parDefaults() {
        let s = score(par: 4, strokes: 4)
        #expect(s.putts == 2)
        #expect(s.fairway == .hit)
        #expect(s.green == .hit)
        #expect(s.upAndDown == nil)
        #expect(s.recovery == nil)
    }

    @Test("Par 3 does not auto-select FH")
    func parThreeHasNoFairway() {
        let s = score(par: 3, strokes: 3)
        #expect(s.fairway == nil)
        #expect(s.green == .hit)
    }

    @Test("Par with 1 or 0 putts clears GIR and selects UD-OK", arguments: [0, 1])
    func parOnePutt(putts: Int) {
        let s = score(par: 4, strokes: 4, putts: putts)
        #expect(s.green == nil)
        #expect(s.upAndDown == .ok)
    }

    @Test("Par with 2 putts and missed fairway selects GIR and REC-G")
    func parMissedFairway() {
        let s = score(par: 4, strokes: 4, fairway: .missLeft)
        #expect(s.green == .hit)
        #expect(s.recovery == .green)
    }

    @Test("Bogey with 2 putts misses GIR and selects UD-1")
    func bogeyDefaults() {
        let s = score(par: 4, strokes: 5)
        #expect(s.putts == 2)
        #expect(s.fairway == .hit)
        #expect(s.green == nil)
        #expect(s.upAndDown == .one)
    }

    @Test("Bogey with 1 putt selects UD-OK")
    func bogeyOnePutt() {
        let s = score(par: 4, strokes: 5, putts: 1)
        #expect(s.green == nil)
        #expect(s.upAndDown == .ok)
    }

    @Test("Bogey with 3 putts is still GIR")
    func bogeyThreePutts() {
        let s = score(par: 4, strokes: 5, putts: 3)
        #expect(s.green == .hit)
        #expect(s.upAndDown == nil)
    }

    @Test("Bogey with missed fairway and 2 putts selects REC-1")
    func bogeyMissedFairway() {
        let s = score(par: 5, strokes: 6, fairway: .missRight)
        #expect(s.recovery == .one)
        #expect(s.upAndDown == .one)
    }

    @Test("Changing FH back to hit clears the inferred recovery")
    func fairwayHitClearsRecovery() {
        var s = score(par: 4, strokes: 4, fairway: .missLeft)
        s.fairway = .hit
        s.autoFill(after: .fairway)
        #expect(s.recovery == nil)
    }

    @Test("A missed-green direction chosen by the user is kept")
    func keepsGreenMissDirection() {
        var s = score(par: 4, strokes: 5)
        s.green = .missShort
        s.putts = 2
        s.autoFill(after: .putts)
        #expect(s.green == .missShort)
    }

    @Test("Existing putts are kept when strokes change")
    func keepsExistingPutts() {
        var s = score(par: 4, strokes: 4, putts: 1)
        s.strokes = 5
        s.autoFill(after: .strokes)
        #expect(s.putts == 1)
    }

    @Test("Scores other than par and bogey are not auto-filled", arguments: [3, 6, 7])
    func otherScoresUntouched(strokes: Int) {
        let s = score(par: 4, strokes: strokes)
        #expect(s.putts == nil)
        #expect(s.fairway == nil)
        #expect(s.green == nil)
    }

    @Test("Next hole to score is the first unscored hole")
    func nextHoleToScore() {
        var round = Round(course: Round.CourseInfo(name: "Test", numberOfHoles: 3))
        #expect(round.nextHoleToScore == 1)
        round.setHoleScore(HoleScore(holeNumber: 1, par: 4, strokes: 4))
        #expect(round.nextHoleToScore == 2)
        round.setHoleScore(HoleScore(holeNumber: 2, par: 4, strokes: 4))
        round.setHoleScore(HoleScore(holeNumber: 3, par: 4, strokes: 4))
        #expect(round.nextHoleToScore == nil)
    }
}
