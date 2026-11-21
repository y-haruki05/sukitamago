import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
            PlaceholderView(title: "さがす", symbol: "safari", message: "あなたにぴったりの小さな体験を、\nここで見つけられるようになります。")
                .tabItem { Label("さがす", systemImage: "safari") }
            PlaceholderView(title: "たまご", symbol: "oval.portrait", message: "体験といっしょに育つたまご。\nこれからの変化をお楽しみに。")
                .tabItem { Label("たまご", systemImage: "oval.portrait") }
            PlaceholderView(title: "きろく", symbol: "book.closed", message: "やってみたこと、感じたこと。\nあなたの小さな一歩を残せるようになります。")
                .tabItem { Label("きろく", systemImage: "book.closed") }
        }
        .tint(AppTheme.outline)
        .foregroundStyle(AppTheme.text)
    }
}

#Preview { ContentView() }
