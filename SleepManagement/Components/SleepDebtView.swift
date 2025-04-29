import SwiftUI

struct SleepDebtView: View {
    let totalDebt: Double
    let maxDebt: Double = 24 // 表示する最大負債（3日分程度）
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("sleep_debt".localized)
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text(String(format: "%+.1f%@", totalDebt, "hours".localized))
                    .font(Theme.Typography.headingFont)
                    .foregroundColor(debtColor)
            }
            
            // リングチャート表示
            let idealHours = SettingsManager.shared.idealSleepDuration / 3600
            let progress = min(totalDebt / idealHours, 1)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.Colors.primary,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                Text(String(format: "%+.1f%@", totalDebt, "hours".localized))
                    .font(Theme.Typography.headingFont)
                    .foregroundColor(Theme.Colors.primary)
            }
            .frame(width: 120, height: 120)
            
            // 負債の説明テキスト
            Text(debtDescription)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.subtext)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 負債に応じた色
    private var debtColor: Color {
        switch totalDebt {
        case 0..<4:
            return Color(hex: "57B894") // 緑：良好
        case 4..<8:
            return Color(hex: "FFB067") // オレンジ：注意
        default:
            return Color(hex: "E5636E") // 赤：危険
        }
    }
    
    // 負債に応じた説明テキスト
    private var debtDescription: String {
        switch totalDebt {
        case 0..<4:
            return "睡眠負債は低レベルです。良好な睡眠習慣を維持しましょう。"
        case 4..<8:
            return "睡眠負債が蓄積しています。今週中に回復睡眠を取ることをお勧めします。"
        case 8..<12:
            return "睡眠負債レベルが高くなっています。できるだけ早く回復睡眠を取りましょう。"
        default:
            return "睡眠負債が危険レベルです。至急、長時間の回復睡眠が必要です。"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SleepDebtView(totalDebt: 2.5)
        SleepDebtView(totalDebt: 6.0)
        SleepDebtView(totalDebt: 12.5)
    }
    .padding()
    .background(Theme.Colors.background)
    .environmentObject(LocalizationManager.shared)
} 