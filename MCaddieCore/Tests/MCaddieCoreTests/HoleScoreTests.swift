import Testing
import Foundation
@testable import MCaddieCore

@Suite("HoleScore Tests")
struct HoleScoreTests {

    @Test("Stroke options range from 1 to 2N+1")
    func strokeOptions() {
        #expect(HoleScore(holeNumber: 1, par: 3).strokeOptions == 1...7)
        #expect(HoleScore(holeNumber: 1, par: 4).strokeOptions == 1...9)
        #expect(HoleScore(holeNumber: 1, par: 5).strokeOptions == 1...11)
    }

    @Test("Score type is classified relative to par",
          arguments: [
            (1, 4, ScoreType.eagleOrBetter),
            (2, 4, .eagleOrBetter),
            (3, 4, .birdie),
            (4, 4, .par),
            (5, 4, .bogey),
            (6, 4, .doubleBogey),
            (7, 4, .tripleBogey),
            (8, 4, .quadrupleBogeyOrWorse),
            (9, 4, .quadrupleBogeyOrWorse),
            (3, 5, .eagleOrBetter),
          ])
    func scoreType(strokes: Int, par: Int, expected: ScoreType) {
        #expect(ScoreType(strokes: strokes, par: par) == expected)
    }

    @Test("Par 3 does not track fairway")
    func fairwayTracking() {
        #expect(!HoleScore(holeNumber: 1, par: 3).tracksFairway)
        #expect(HoleScore(holeNumber: 1, par: 4).tracksFairway)
    }

    @Test("Round uses hole par from course data, defaulting to 4")
    func parLookup() {
        let holes = [
            Hole(number: 1, par: 5, distance: Distance(yards: 520)),
            Hole(number: 2, par: 3, distance: Distance(yards: 160)),
        ]
        let round = Round(course: Round.CourseInfo(name: "Test", numberOfHoles: 18, holes: holes))
        #expect(round.holeScore(forHole: 1).par == 5)
        #expect(round.holeScore(forHole: 2).par == 3)
        #expect(round.holeScore(forHole: 3).par == 4)
    }

    @Test("Setting a hole score replaces the existing one and keeps holes ordered")
    func setHoleScore() {
        var round = Round(course: Round.CourseInfo(name: "Test"))
        round.setHoleScore(HoleScore(holeNumber: 2, par: 4, strokes: 5))
        round.setHoleScore(HoleScore(holeNumber: 1, par: 4, strokes: 4))
        round.setHoleScore(HoleScore(holeNumber: 2, par: 4, strokes: 6, putts: 2))

        #expect(round.holeScores.map(\.holeNumber) == [1, 2])
        #expect(round.holeScore(forHole: 2).strokes == 6)
        #expect(round.holeScore(forHole: 2).putts == 2)
        #expect(round.totalStrokes == 10)
        #expect(round.scoreToPar == 2)
    }

    @Test("HoleScore decodes data saved before trouble/recovery fields existed")
    func decodesLegacyData() throws {
        let legacy = #"[{"holeNumber":1,"par":4,"strokes":5,"putts":2,"fairway":"hit"}]"#
        let scores = try JSONDecoder().decode([HoleScore].self, from: Data(legacy.utf8))
        #expect(scores.first?.troubleShots == 0)
        #expect(scores.first?.recovery == nil)
        #expect(scores.first?.sandSave == nil)
        #expect(scores.first?.upAndDown == nil)
        #expect(scores.first?.fairway == .hit)
    }

    @Test("HoleScore round-trips through JSON")
    func codable() throws {
        let score = HoleScore(
            holeNumber: 7, par: 4, strokes: 5, putts: 2, fairway: .missLeft, green: .hit,
            troubleShots: 1, recovery: .green, sandSave: .one, upAndDown: .twoOrMore
        )
        let data = try JSONEncoder().encode([score])
        #expect(try JSONDecoder().decode([HoleScore].self, from: data) == [score])
    }
}

@Suite("Hole Fitting Tests")
struct HoleFittingTests {
    private func holes(_ pars: [Int]) -> [Hole] {
        pars.enumerated().map { Hole(number: $0.offset + 1, par: $0.element, distance: Distance(yards: Double(100 * $0.element)), handicap: $0.offset + 1) }
    }

    @Test("Takes the first N holes when the course has more")
    func truncates() {
        let fitted = Hole.fitting(holes([3, 4, 5, 4]), toCount: 2)
        #expect(fitted.map(\.par) == [3, 4])
        #expect(fitted.map(\.number) == [1, 2])
    }

    @Test("Repeats holes when the course has fewer")
    func repeats() {
        let fitted = Hole.fitting(holes([3, 4, 5]), toCount: 7)
        #expect(fitted.map(\.par) == [3, 4, 5, 3, 4, 5, 3])
        #expect(fitted.map(\.number) == Array(1...7))
        #expect(fitted[3].handicap == 1)
        #expect(fitted[3].distance == Distance(yards: 300))
    }

    @Test("Keeps holes unchanged when counts match")
    func matches() {
        let fitted = Hole.fitting(holes([4, 4, 3]), toCount: 3)
        #expect(fitted.map(\.par) == [4, 4, 3])
    }

    @Test("Empty source yields no holes")
    func empty() {
        #expect(Hole.fitting([], toCount: 9).isEmpty)
    }
}

@Suite("Round Reconfigure Tests")
struct RoundReconfigureTests {
    private func holes(_ pars: [Int]) -> [Hole] {
        pars.enumerated().map { Hole(number: $0.offset + 1, par: $0.element, distance: Distance(yards: 300)) }
    }

    private func roundWithScores(holeCount: Int, scored: Int) -> Round {
        var round = Round(course: Round.CourseInfo(name: "Test", numberOfHoles: holeCount, holes: holes(Array(repeating: 4, count: holeCount))))
        for number in 1...scored {
            round.setHoleScore(HoleScore(holeNumber: number, par: 4, strokes: 5))
        }
        return round
    }

    @Test("Reducing holes drops scores beyond the new count")
    func dropsExtraScores() {
        var round = roundWithScores(holeCount: 18, scored: 12)
        round.reconfigure(numberOfHoles: 9, holes: holes(Array(repeating: 4, count: 9)), teeName: nil, teeGender: nil, externalCourseID: nil)
        #expect(round.course.numberOfHoles == 9)
        #expect(round.holeScores.map(\.holeNumber) == Array(1...9))
    }

    @Test("Changing tee updates par of scored holes and keeps strokes")
    func updatesPar() {
        var round = roundWithScores(holeCount: 3, scored: 3)
        round.reconfigure(numberOfHoles: 3, holes: holes([3, 5, 4]), teeName: "Blue", teeGender: "male", externalCourseID: "42")
        #expect(round.holeScores.map(\.par) == [3, 5, 4])
        #expect(round.holeScores.map(\.strokes) == [5, 5, 5])
        #expect(round.scoredPar == 12)
        #expect(round.course.teeName == "Blue")
        #expect(round.course.externalCourseID == "42")
    }

    @Test("Completed round with new unscored holes returns to in progress")
    func reopensCompletedRound() {
        var round = roundWithScores(holeCount: 9, scored: 9)
        round.complete()
        round.reconfigure(numberOfHoles: 18, holes: nil, teeName: nil, teeGender: nil, externalCourseID: nil)
        #expect(round.status == .inProgress)
        #expect(round.endTime == nil)
        #expect(round.nextHoleToScore == 10)
    }

    @Test("Completed round stays completed when all holes remain scored")
    func staysCompleted() {
        var round = roundWithScores(holeCount: 18, scored: 18)
        round.complete()
        round.reconfigure(numberOfHoles: 9, holes: nil, teeName: nil, teeGender: nil, externalCourseID: nil)
        #expect(round.status == .completed)
    }
}
