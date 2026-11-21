import Testing
import Foundation
@testable import sukitamago

struct EggGrowthTests {
    @Test func countsAloneNeverHatch() {
        for count in [0, 1, 2, 3, 5, 100, Int.max, -1, Int.min] {
            let growth = EggGrowthCalculator.calculate(experienceCount: count)
            #expect(!growth.stage.showsCat)
            #expect(growth.stage == (count >= 3 ? .sprouting : .beginning))
        }
        let id = UUID()
        #expect(EggGrowthCalculator.calculate(recordIDs: [id, id]).experienceCount == 1)
    }
}
