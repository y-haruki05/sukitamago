import Foundation

/// Stable identifiers can be persisted independently of the Japanese display copy.
enum ExperienceFeeling: String, CaseIterable, Identifiable, Codable {
    case fun, neutral, notForMe
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .fun: "😊"
        case .neutral: "😌"
        case .notForMe: "🌱"
        }
    }
    var title: String {
        switch self {
        case .fun: "楽しかった！"
        case .neutral: "ふつう"
        case .notForMe: "ちょっと違ったかも"
        }
    }
    var subtitle: String {
        switch self {
        case .fun: "またやってみたいかも！"
        case .neutral: "新しい発見があったかも。"
        case .notForMe: "合わないとわかるのも発見だよ。"
        }
    }
    var completionMessage: String {
        switch self {
        case .fun: "その『楽しい』が、好きのはじまりかも！"
        case .neutral: "やってみたからこそ、わかったことがあるね。"
        case .notForMe: "自分に合うものを知るための、大切な一歩だよ。"
        }
    }
}

/// A value handed to a future record writer alongside the session's mission and image.
/// This issue deliberately performs no persistence.
struct ExperienceReflection: Equatable, Codable {
    static let noteLimit = 200
    let feeling: ExperienceFeeling
    let note: String

    init(feeling: ExperienceFeeling, note: String) {
        self.feeling = feeling
        self.note = Self.limitedNote(note).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func limitedNote(_ value: String) -> String { String(value.prefix(noteLimit)) }
}
