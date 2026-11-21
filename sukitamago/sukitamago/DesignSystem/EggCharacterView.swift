import SwiftUI

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        path.move(to: p(0.5, 0.03))
        path.addCurve(to: p(0.94, 0.69), control1: p(0.72, 0.01), control2: p(0.94, 0.43))
        path.addCurve(to: p(0.5, 0.97), control1: p(0.97, 0.90), control2: p(0.76, 0.98))
        path.addCurve(to: p(0.06, 0.69), control1: p(0.24, 0.98), control2: p(0.03, 0.90))
        path.addCurve(to: p(0.5, 0.03), control1: p(0.06, 0.43), control2: p(0.28, 0.01))
        path.closeSubpath()
        return path
    }
}

/// Presentation state is independent of future growth and persistence logic.
struct EggCharacterView: View {
    enum Expression { case calm, happy }
    var expression: Expression = .calm
    var hatched: Bool? = nil
    var sways = false
    @Environment(\.eggHasHatched) private var savedHatched
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var delighted = false
    @State private var bouncing = false
    @State private var bounceTask: Task<Void, Never>?

    var body: some View {
        Button {
            guard !bouncing else { return }
            delighted = true
            if !reduceMotion {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { bouncing = true }
            }
            bounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(550))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : .spring(response: 0.4)) { bouncing = false }
                delighted = false
            }
        } label: {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                let wave = reduceMotion ? 0 : sin(context.date.timeIntervalSinceReferenceDate * 1.7)
                ZStack {
                    Ellipse().fill(AppTheme.ink.opacity(0.10))
                        .frame(width: 110, height: 14).offset(y: 91)
                    character
                        .rotationEffect(.degrees(!reduceMotion && sways ? wave * 1.5 : 0))
                        .scaleEffect(bouncing ? 1.045 : 1 + wave * 0.012)
                        .offset(y: bouncing ? -16 : wave * 4)
                }
            }
            .frame(width: 208, height: 214)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("あなたの好きのたまご")
        .accessibilityValue((hatched ?? savedHatched) ? "猫" : "卵")
        .accessibilityHint("ダブルタップすると、たまごが喜びます")
        .onDisappear { bounceTask?.cancel(); bouncing = false; delighted = false }
    }

    @ViewBuilder private var character: some View {
        if let mascot = UIImage(named: (hatched ?? savedHatched) ? "PhotoCat" : "Egg") {
            Image(uiImage: mascot).resizable().scaledToFit()
                .frame(width: 190, height: 202)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            eggFace
        }
    }

    private var eggFace: some View {
        ZStack {
            EggShape().fill(AppTheme.shell)
            EggShape().stroke(AppTheme.ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            HStack(spacing: 70) {
                Ellipse().fill(AppTheme.pink).frame(width: 25, height: 15)
                Ellipse().fill(AppTheme.pink).frame(width: 25, height: 15)
            }.offset(y: 28)
            HStack(spacing: 43) {
                eye
                eye
            }.offset(y: 12)
            Path { p in
                p.move(to: CGPoint(x: 75, y: 111))
                p.addQuadCurve(to: CGPoint(x: 93, y: 111), control: CGPoint(x: 84, y: 124))
            }
            .stroke(AppTheme.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .frame(width: 168, height: 180)
    }

    @ViewBuilder private var eye: some View {
        if delighted || expression == .happy {
            Image(systemName: "chevron.up").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.ink)
        } else {
            Ellipse().fill(AppTheme.ink).frame(width: 8, height: 11)
        }
    }
}

#Preview { EggCharacterView().padding(40).background(AppTheme.lightBlue) }
