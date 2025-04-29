import SwiftUI

struct SleepDebtView: View {
    @State private var showDetail: Bool = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    let totalDebt: Double
    let windowStart: Date
    let windowEnd: Date
    let maxDebt: Double = 24 // 表示する最大負債（3日分程度）
    let detailTitle: String
    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: localizationManager.currentLanguage == "ja" ? "ja_JP" : "en_US")
        df.timeStyle = .short
        return df
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("sleep_debt".localized)
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                HStack(spacing: 4) {
                    // 負債値と単位を別行で表示
                    VStack(spacing: 0) {
                        Text(String(format: "%+.1f", totalDebt))
                            .font(Theme.Typography.headingFont)
                            .foregroundColor(debtColor)
                        Text("hours".localized)
                            .font(Theme.Typography.subheadingFont)
                            .foregroundColor(debtColor)
                    }
                    Button(action: { showDetail = true }) {
                        Image(systemName: "info.circle")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.subtext)
                    }
                }
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
                        debtColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                // サークル内の負債値と単位を別行で表示
                VStack(spacing: 0) {
                    Text(String(format: "%+.1f", totalDebt))
                        .font(Theme.Typography.headingFont)
                        .foregroundColor(debtColor)
                    Text("hours".localized)
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(debtColor)
                }
            }
            .frame(width: 120, height: 120)
            
            // ７日間固定集計時には期間ラベルを表示しない
            if detailTitle == (localizationManager.currentLanguage == "ja" ? "7日間の計算過程" : "7-Day Calculation Detail") {
                EmptyView()
            } else {
                Text(localizationManager.currentLanguage == "ja"
                     ? "集計期間: \(timeFormatter.string(from: windowStart)) ～ \(timeFormatter.string(from: windowEnd))"
                     : "Reporting Period: \(timeFormatter.string(from: windowStart)) - \(timeFormatter.string(from: windowEnd))")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        // ℹ︎ ボタンで詳細画面を表示
        .sheet(isPresented: $showDetail) {
            SleepDebtDetailView(
                windowStart: windowStart,
                windowEnd: windowEnd,
                detailTitle: detailTitle
            )
            .environmentObject(localizationManager)
        }
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
}

#Preview {
    VStack(spacing: 20) {
        SleepDebtView(totalDebt: 2.5, windowStart: Date(), windowEnd: Date(), detailTitle: "Calculation Detail")
        SleepDebtView(totalDebt: 6.0, windowStart: Date(), windowEnd: Date(), detailTitle: "Calculation Detail")
        SleepDebtView(totalDebt: 12.5, windowStart: Date(), windowEnd: Date(), detailTitle: "Calculation Detail")
    }
    .padding()
    .background(Theme.Colors.background)
    .environmentObject(LocalizationManager.shared)
} 