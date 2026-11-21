import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection = 0
    @Query private var hatchingStates: [EggHatchingState]
    @Query private var records: [ExperienceRecord]

    private var growth: EggGrowth {
        EggGrowthCalculator.calculate(recordIDs: records.map(\.id), hasFoundLike: !hatchingStates.isEmpty)
    }
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }.tag(0)
            PlaceholderView(title: "さがす", symbol: "safari", message: "あなたにぴったりの小さな体験を、\nここで見つけられるようになります。")
                .tabItem { Label("さがす", systemImage: "safari") }.tag(1)
            EggGrowthView(growth: growth, onExplore: { selection = 0 })
                .tabItem { Label("たまご", systemImage: "oval.portrait") }.tag(2)
            ExperienceHistoryView { selection = 0 }
                .tabItem { Label("きろく", systemImage: "book.closed") }.tag(3)
        }
        .environment(\.eggHasHatched, !hatchingStates.isEmpty)
        .tint(AppTheme.outline)
        .foregroundStyle(AppTheme.text)
    }
}

#Preview {
    if let persistence = try? ExperiencePersistence.make(inMemory: true) {
        ContentView().modelContainer(persistence.container)
            .environment(\.experiencePhotos, persistence.photos)
    }
}
