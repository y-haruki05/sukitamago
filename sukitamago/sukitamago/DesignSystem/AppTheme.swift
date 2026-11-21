import SwiftUI
import UIKit

/// All palette and surface decisions live here, including accessible dark variants.
enum AppTheme {
    private static func color(_ light: UInt32, _ dark: UInt32) -> Color {
        func ui(_ value: UInt32) -> UIColor {
            UIColor(red: CGFloat((value >> 16) & 255) / 255,
                    green: CGFloat((value >> 8) & 255) / 255,
                    blue: CGFloat(value & 255) / 255, alpha: 1)
        }
        return Color(UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
    }
    static let background = color(0xFFFFFF, 0x172331)
    static let subBackground = color(0xF5FAFF, 0x202F40)
    static let primary = color(0x5B9BD5, 0x94C7F2)
    static let outline = color(0x477FB5, 0x94C7F2)
    static let lightBlue = color(0xDCEFFF, 0x263E53)
    static let pink = Color(red: 1, green: 0.776, blue: 0.851)
    static let text = color(0x34465A, 0xEDF5FF)
    // Slightly deeper than the initial palette for small-text contrast.
    static let secondaryText = color(0x64778B, 0xB3C3D5)
    static let button = color(0x477FB5, 0x94C7F2)
    static let buttonText = color(0xFFFFFF, 0x172331)
    static let shell = Color.white
    static let ink = Color(red: 0.278, green: 0.498, blue: 0.710)
    static let cardRadius: CGFloat = 28
    static let pagePadding: CGFloat = 24
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title).fixedSize(horizontal: false, vertical: true)
                Image(systemName: "arrow.right")
            }
            .font(.body.weight(.bold))
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(16)
            .foregroundStyle(AppTheme.buttonText)
            .background(AppTheme.button, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
