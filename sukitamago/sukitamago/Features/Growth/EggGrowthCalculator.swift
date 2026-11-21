import Foundation

enum EggGrowthStage: CaseIterable {
    case beginning, sprouting, hatched

    var title: String {
        switch self {
        case .beginning: "はじまり"
        case .sprouting: "芽生え"
        case .hatched: "孵化"
        }
    }
    var message: String {
        switch self {
        case .beginning: "小さな一歩から、好きの種を育てていこう。"
        case .sprouting: "いろんな体験が、少しずつ好きにつながっているよ。"
        case .hatched: "おめでとう！あなたの『好き』が見つかったね！"
        }
    }
    var showsCat: Bool { self == .hatched }
}

struct EggGrowth: Equatable {
    let experienceCount: Int
    let stage: EggGrowthStage
}

enum EggGrowthCalculator {
    static func calculate(recordIDs: some Sequence<UUID>, hasFoundLike: Bool = false) -> EggGrowth {
        calculate(experienceCount: Set(recordIDs).count, hasFoundLike: hasFoundLike)
    }
    static func calculate(experienceCount: Int, hasFoundLike: Bool = false) -> EggGrowth {
        let count = max(0, experienceCount)
        return EggGrowth(experienceCount: count,
                         stage: hasFoundLike ? .hatched : (count >= 3 ? .sprouting : .beginning))
    }
}
