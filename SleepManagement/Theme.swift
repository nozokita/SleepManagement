import SwiftUI

// アプリ全体のテーマカラーと共通スタイルを定義
struct Theme {
    // カラーパレット
    struct Colors {
        static let primary = Color(UIColor(named: "AppPrimaryColor") ?? UIColor(hex: "4A6FA5"))
        static let secondary = Color(UIColor(named: "AppSecondaryColor") ?? UIColor(hex: "166088"))
        static let accent = Color(UIColor(named: "AccentColor") ?? UIColor(hex: "4DAAAB"))
        static let background = Color(UIColor(named: "BackgroundColor") ?? UIColor(hex: "F5F6FA"))
        static let cardBackground = Color(UIColor(named: "CardBackground") ?? .white)
        static let text = Color(UIColor(named: "TextColor") ?? UIColor(hex: "2D3142"))
        static let subtext = Color(UIColor(named: "SubtextColor") ?? UIColor(hex: "9C9EB9"))
        
        // 追加カラー
        static let success = Color(hex: "57B894")  // 緑
        static let warning = Color(hex: "FFB067")  // オレンジ
        static let danger = Color(hex: "E5636E")   // 赤
        static let info = Color(hex: "23A7F2")     // 青
        
        // グラデーション
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "4A6FA5"), Color(hex: "6366F1")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "4DAAAB"), Color(hex: "23A7F2")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            gradient: Gradient(colors: [primary.opacity(0.1), secondary.opacity(0.1)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // 睡眠スコア用のグラデーションカラー
        static func scoreColor(score: Double) -> Color {
            switch score {
            case 0..<50:
                return Color(hex: "E5636E")  // 赤 - 低スコア
            case 50..<70:
                return Color(hex: "FFB067")  // オレンジ - 中スコア
            case 70..<90:
                return Color(hex: "57B894")  // 緑 - 良好スコア
            default:
                return Color(hex: "23A7F2")  // 青 - 優秀スコア
            }
        }
        
        // スコアに基づくグラデーション
        static func scoreGradient(score: Double) -> LinearGradient {
            switch score {
            case 0..<50:
                return LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "E5636E"), Color(hex: "E57373")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case 50..<70:
                return LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "FFB067"), Color(hex: "FFCC80")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case 70..<90:
                return LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "57B894"), Color(hex: "81C784")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            default:
                return LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "23A7F2"), Color(hex: "64B5F6")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // タイポグラフィ
    struct Typography {
        static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let headingFont = Font.system(.title2, design: .rounded).weight(.semibold)
        static let subheadingFont = Font.system(.title3, design: .rounded).weight(.medium)
        static let bodyFont = Font.system(.body, design: .rounded)
        static let captionFont = Font.system(.caption, design: .rounded)
    }
    
    // レイアウト
    struct Layout {
        static let standardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
    }
    
    // シャドウ
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
    
    // アニメーション
    struct Animations {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let springy = Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// シャドウ構造体
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func apply<T: View>(_ view: T) -> some View {
        view.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// HEXカラーコードをSwiftUI Colorに変換するための拡張
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// UIColorにもhexコンストラクタを追加
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// ViewModifierの拡張
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Viewの拡張
extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
    
    func gradientBackground() -> some View {
        self.background(Theme.Colors.cardGradient)
    }
} 