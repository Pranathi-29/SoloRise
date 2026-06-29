import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var workoutDone: Bool
    var nutritionDone: Bool
    var studyDone: Bool
    var readingDone: Bool
    var recoveryDone: Bool
    var supplementsBuff: Bool
    var waterBuff: Bool
    var proteinBuff: Bool
    var shieldEarned: Bool = false

    init(date: Date = .now) {
        self.date = date
        self.workoutDone = false
        self.nutritionDone = false
        self.studyDone = false
        self.readingDone = false
        self.recoveryDone = false
        self.supplementsBuff = false
        self.waterBuff = false
        self.proteinBuff = false
        self.shieldEarned = false
    }

    var completedCount: Int {
        [workoutDone, nutritionDone, studyDone, readingDone, recoveryDone].filter { $0 }.count
    }

    var allComplete: Bool { completedCount == 5 }
}