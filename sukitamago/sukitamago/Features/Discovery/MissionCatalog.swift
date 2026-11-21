import Foundation

enum MissionCategory: String, CaseIterable, Identifiable {
    case photo, walk, music, creative, reading, observation
    var id: String { rawValue }
    var title: String {
        switch self {
        case .photo: "写真"
        case .walk: "散歩"
        case .music: "音楽"
        case .creative: "創作"
        case .reading: "読書"
        case .observation: "観察"
        }
    }
    var icon: String {
        switch self {
        case .photo: "camera"
        case .walk: "figure.walk"
        case .music: "music.note"
        case .creative: "paintpalette"
        case .reading: "book"
        case .observation: "magnifyingglass"
        }
    }
}

enum MissionExecution: Hashable {
    case photo, unavailable
}

struct ExperienceMission: Identifiable, Hashable {
    let id: String
    let title: String
    let category: MissionCategory
    let introduction: String
    let durationMinutes: Int
    let equipment: String
    let encouragement: String
    let execution: MissionExecution

    var genre: String { category.title }
    var icon: String { category.icon }
    var duration: String { "約\(durationMinutes)分" }
    var canStart: Bool { execution == .photo }
    static var first: Self { MissionCatalog.photo }
}

// Preserve the existing photo-flow API while sharing the same catalog definition.
typealias SmallExperience = ExperienceMission

enum MissionCatalog {
    // This ID is already stored in ExperienceRecord; do not rename it.
    static let photo = ExperienceMission(
        id: "photo.nearby-beauty", title: "身近な『きれい』を撮ろう", category: .photo,
        introduction: "いつもの景色の中から、ちょっといいなと思うものを探してみよう。",
        durationMinutes: 3, equipment: "スマートフォン",
        encouragement: "空でも、花でも、好きな色でも。正解はないよ。", execution: .photo)

    static let all: [ExperienceMission] = [
        photo,
        ExperienceMission(id: "walk.different-path", title: "いつもと違う道を歩こう", category: .walk,
            introduction: "少しだけ道を変えて、初めて見る景色を探してみよう。",
            durationMinutes: 10, equipment: "歩きやすい靴",
            encouragement: "遠くまで行かなくても大丈夫。歩き慣れた道のすぐそばから。", execution: .unavailable),
        ExperienceMission(id: "music.unfamiliar-song", title: "知らない曲を1曲聴こう", category: .music,
            introduction: "普段は選ばないジャンルの音楽に触れてみよう。",
            durationMinutes: 5, equipment: "音楽を聴ける環境",
            encouragement: "好きにならなくても大丈夫。まずは一曲、気軽に聴いてみよう。", execution: .unavailable),
        ExperienceMission(id: "creative.feelings-in-color", title: "今の気持ちを色で描こう", category: .creative,
            introduction: "上手に描く必要はないよ。好きな色を自由に使ってみよう。",
            durationMinutes: 5, equipment: "紙とペン",
            encouragement: "きれいに描こうとしなくていいよ。今、手に取りたい色から。", execution: .unavailable),
        ExperienceMission(id: "reading.three-pages", title: "気になる本を3ページ読もう", category: .reading,
            introduction: "気になった本を少しだけ読んで、新しい世界に触れてみよう。",
            durationMinutes: 5, equipment: "本",
            encouragement: "最後まで読まなくても大丈夫。気になるページを少しだけ。", execution: .unavailable),
        ExperienceMission(id: "observation.small-discovery", title: "身近な小さな発見を探そう", category: .observation,
            introduction: "空や植物、街の中で、普段気づかないものを探してみよう。",
            durationMinutes: 3, equipment: "なし",
            encouragement: "小さな気づきで十分だよ。いつもの景色をゆっくり見てみよう。", execution: .unavailable)
    ]

    /// nil is the UI's「すべて」selection; categories remain actual mission genres.
    static func missions(in category: MissionCategory?) -> [ExperienceMission] {
        guard let category else { return all }
        return all.filter { $0.category == category }
    }
}
