import SwiftUI
import Charts

struct SleepDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var sleepManager = SleepManager.shared
    
    // チャートデータ
    @State private var weeklyData: [SleepChartData] = []
    @State private var monthlyData: [SleepChartData] = []
    @State private var debtTrend: [Date: Double] = [:]
    
    // 表示期間の選択
    @State private var selectedPeriod: ChartPeriod = .week
    
    // アニメーション
    @State private var animateCharts: Bool = false
    @State private var refreshing: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // 期間切り替えセグメント
                    periodSelector
                    
                    // データサマリーカード
                    dataOverviewCard
                    
                    // 睡眠パターンチャート
                    sleepPatternCard
                    
                    // 睡眠スコアチャート
                    sleepScoreCard
                    
                    // 睡眠負債チャート
                    sleepDebtCard
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .navigationTitle("stats_tab".localized)
            .background(Theme.Colors.background.ignoresSafeArea())
            .onAppear {
                loadData()
                
                // アニメーション
                withAnimation(Theme.Animations.springy.delay(0.3)) {
                    animateCharts = true
                }
            }
            .refreshable {
                refreshData()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("HealthKitDataSynced"))) { _ in
                // HealthKit同期完了後にデータを再読み込み
                refreshData()
            }
        }
    }
    
    // 期間セレクタ
    private var periodSelector: some View {
        Picker("", selection: $selectedPeriod) {
            Text("week_period".localized).tag(ChartPeriod.week)
            Text("month_period".localized).tag(ChartPeriod.month)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedPeriod) { oldValue, newValue in
            withAnimation {
                animateCharts = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Theme.Animations.springy) {
                    animateCharts = true
                }
            }
        }
    }
    
    // データ概要カード
    private var dataOverviewCard: some View {
        let currentData = selectedPeriod == .week ? weeklyData : monthlyData
        
        return VStack(spacing: 0) {
            // カードヘッダー
            HStack {
                Label("data_overview".localized, systemImage: "chart.bar.doc.horizontal")
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("\(currentData.count)" + "days_of_data".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.cardGradient)
            
            Divider()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // 平均睡眠時間
                dataOverviewItem(
                    title: localizationManager.currentLanguage == "ja" ? "平均睡眠時間" : "Avg. Sleep Duration",
                    value: averageDurationFormatted(from: currentData),
                    icon: "clock",
                    color: Theme.Colors.primary
                )
                
                // 平均睡眠スコア
                dataOverviewItem(
                    title: localizationManager.currentLanguage == "ja" ? "平均睡眠スコア" : "Avg. Sleep Score",
                    value: averageScoreFormatted(from: currentData),
                    icon: "star.fill",
                    color: sleepScoreColor(for: currentData.averageScore)
                )
                
                // 最長睡眠日
                if let maxDay = currentData.maxDurationDay {
                    dataOverviewItem(
                        title: localizationManager.currentLanguage == "ja" ? "最長睡眠時間" : "Longest Sleep Duration",
                        value: formatDayAndDuration(date: maxDay.date, duration: maxDay.duration),
                        icon: "arrow.up.right",
                        color: Theme.Colors.success
                    )
                }
                
                // 最短睡眠日
                if let minDay = currentData.minDurationDay, minDay.duration > 0 {
                    dataOverviewItem(
                        title: "shortest_sleep_day",
                        value: formatDayAndDuration(date: minDay.date, duration: minDay.duration),
                        icon: "arrow.down.right",
                        color: Theme.Colors.warning
                    )
                }
            }
            .padding(16)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .offset(y: animateCharts ? 0 : 50)
        .opacity(animateCharts ? 1 : 0)
    }
    
    // 睡眠パターンチャート
    private var sleepPatternCard: some View {
        let chartData = selectedPeriod == .week ? weeklyData : monthlyData
        
        return VStack(spacing: 0) {
            // カードヘッダー
            HStack {
                Label("sleep_pattern".localized, systemImage: "waveform.path")
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("hours".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.cardGradient)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // チャート
                if chartData.isEmpty {
                    emptyChartView
                } else {
                    Chart {
                        ForEach(chartData) { item in
                            BarMark(
                                x: .value("Date", selectedPeriod == .week ? item.weekdayString : item.dayFormatted),
                                y: .value("Duration", item.duration / 3600) // 時間単位で表示
                            )
                            .foregroundStyle(Theme.Colors.primary.gradient)
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                if item.duration > 0 {
                                    Text("\(Int(item.duration / 3600))")
                                        .font(.caption2)
                                        .foregroundColor(Theme.Colors.subtext)
                                }
                            }
                        }
                        
                        // 推奨睡眠時間の目標ライン
                        RuleMark(
                            y: .value("Target", sleepManager.recommendedSleepHours)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Theme.Colors.subtext)
                        .annotation(position: .trailing) {
                            Text("goal".localized)
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.subtext)
                        }
                    }
                    // Y軸はデータに応じて自動スケーリング
                    .frame(height: 220)
                    .animation(.easeInOut, value: selectedPeriod)
                    .padding(.top, 8)
                }
                
                // チャート説明
                HStack {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 8, height: 8)
                    
                    Text("sleep_duration".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                    
                    Spacer()
                    
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundColor(Theme.Colors.subtext)
                        .frame(width: 20, height: 1)
                    
                    Text("recommended".localized + ": \(Int(sleepManager.recommendedSleepHours))" + "hours".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                }
            }
            .padding(16)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .offset(y: animateCharts ? 0 : 50)
        .opacity(animateCharts ? 1 : 0)
    }
    
    // 睡眠スコアチャート
    private var sleepScoreCard: some View {
        let chartData = selectedPeriod == .week ? weeklyData : monthlyData
        
        return VStack(spacing: 0) {
            // カードヘッダー
            HStack {
                Label("sleep_score".localized, systemImage: "star")
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("score_points".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.cardGradient)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // チャート
                if chartData.isEmpty {
                    emptyChartView
                } else {
                    Chart {
                        ForEach(chartData) { item in
                            if item.score > 0 {
                                LineMark(
                                    x: .value("Date", selectedPeriod == .week ? item.weekdayString : item.dayFormatted),
                                    y: .value("Score", item.score)
                                )
                                .foregroundStyle(Theme.Colors.secondary.gradient)
                                .symbol {
                                    Circle()
                                        .fill(sleepScoreColor(for: item.score))
                                        .frame(width: 8, height: 8)
                                }
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                
                                PointMark(
                                    x: .value("Date", selectedPeriod == .week ? item.weekdayString : item.dayFormatted),
                                    y: .value("Score", item.score)
                                )
                                .foregroundStyle(sleepScoreColor(for: item.score))
                                .annotation(position: .top) {
                                    if item.score > 0 {
                                        Text("\(Int(item.score))")
                                            .font(.caption2)
                                            .foregroundColor(Theme.Colors.subtext)
                                    }
                                }
                            }
                        }
                        
                        // 良質な睡眠のラインマーク
                        RuleMark(
                            y: .value("Good", 80)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Theme.Colors.success)
                        .annotation(position: .trailing) {
                            Text("good".localized)
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.success)
                        }
                        
                        // まあまあの睡眠のラインマーク
                        RuleMark(
                            y: .value("Fair", 60)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Theme.Colors.warning)
                        .annotation(position: .trailing) {
                            Text("fair".localized)
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.warning)
                        }
                    }
                    // Y軸はデータに応じて自動スケーリング
                    .frame(height: 220)
                    .animation(.easeInOut, value: selectedPeriod)
                    .padding(.top, 8)
                }
                
                // 凡例を言語対応で統一
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 8, height: 8)
                        Text("80-100: " + "excellent".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 8, height: 8)
                        Text("60-79: " + "good".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Theme.Colors.warning)
                            .frame(width: 8, height: 8)
                        Text("<60: " + "needs_improvement".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .offset(y: animateCharts ? 0 : 50)
        .opacity(animateCharts ? 1 : 0)
    }
    
    // 睡眠負債チャート
    private var sleepDebtCard: some View {
        let debtArray = debtTrend.sorted { $0.key < $1.key }
        
        return VStack(spacing: 0) {
            // カードヘッダー
            HStack {
                Label("sleep_debt".localized, systemImage: "chart.line.uptrend.xyaxis")
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("hours".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.cardGradient)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // チャート
                if debtArray.isEmpty {
                    emptyChartView
                } else {
                    Chart {
                        ForEach(debtArray.prefix(selectedPeriod == .week ? 7 : 30), id: \.key) { date, debt in
                            AreaMark(
                                x: .value("Date", formatDate(date)),
                                y: .value("Debt", debt)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [Theme.Colors.danger.opacity(0.8), Theme.Colors.danger.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            LineMark(
                                x: .value("Date", formatDate(date)),
                                y: .value("Debt", debt)
                            )
                            .foregroundStyle(Theme.Colors.danger)
                            .symbol {
                                Circle()
                                    .fill(Theme.Colors.danger)
                                    .frame(width: 6, height: 6)
                            }
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        
                        // 危険ラインマーク
                        RuleMark(
                            y: .value("Danger", 2)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Theme.Colors.danger)
                        .annotation(position: .trailing) {
                            Text("danger".localized)
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.danger)
                        }
                        
                        // 警告ラインマーク
                        RuleMark(
                            y: .value("Warning", 1)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Theme.Colors.warning)
                        .annotation(position: .trailing) {
                            Text("warning".localized)
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.warning)
                        }
                    }
                    // Y軸はデータに応じて自動スケーリング
                    .frame(height: 220)
                    .animation(.easeInOut, value: selectedPeriod)
                    .padding(.top, 8)
                }
                
                // 睡眠負債の説明
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Theme.Colors.info)
                        .font(.footnote)
                    
                    Text("sleep_debt_explanation".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding()
                .background(Theme.Colors.info.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(16)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .offset(y: animateCharts ? 0 : 50)
        .opacity(animateCharts ? 1 : 0)
    }
    
    // 空のチャートビュー
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.subtext.opacity(0.5))
            
            Text("no_data_available".localized)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.center)
            
            Text("add_sleep_records".localized)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(.vertical, 24)
    }
    
    // MARK: - ヘルパー関数
    
    // データアイテム表示
    private func dataOverviewItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
            
            Text(value)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // データのロード
    private func loadData() {
        weeklyData = sleepManager.getWeeklyChartData(context: viewContext)
        monthlyData = sleepManager.getMonthlyChartData(context: viewContext)
        debtTrend = sleepManager.getSleepDebtTrend(context: viewContext)
    }
    
    // データのリフレッシュ
    private func refreshData() {
        refreshing = true
        loadData()
        
        // リフレッシュアニメーション
        withAnimation {
            animateCharts = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(Theme.Animations.springy) {
                animateCharts = true
            }
            refreshing = false
        }
    }
    
    // 日付のフォーマット - 言語設定に合わせる
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = selectedPeriod == .week ? "E" : "MM/dd"
        
        // localizationManagerの言語設定に合わせてロケールを設定
        formatter.locale = Locale(identifier: localizationManager.currentLanguage == "ja" ? "ja_JP" : "en_US")
        return formatter.string(from: date)
    }
    
    // 日付と時間のフォーマット（最長・最短睡眠日用）
    private func formatDayAndDuration(date: Date, duration: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = formatter.string(from: date)
        
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if localizationManager.currentLanguage == "ja" {
            return "\(dateStr) (\(hours)時間\(minutes)分)"
        } else {
            return "\(dateStr) (\(hours)h \(minutes)m)"
        }
    }
    
    // 平均睡眠時間のフォーマット - 言語設定に合わせて単位を変更
    private func averageDurationFormatted(from data: [SleepChartData]) -> String {
        let averageDuration = data.averageDuration
        let hours = Int(averageDuration / 3600)
        let minutes = Int((averageDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if localizationManager.currentLanguage == "ja" {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // 平均睡眠スコアのフォーマット
    private func averageScoreFormatted(from data: [SleepChartData]) -> String {
        let score = data.averageScore
        return "\(Int(score))" + "points".localized
    }
    
    // 睡眠スコアの色
    private func sleepScoreColor(for score: Double) -> Color {
        if score >= 80 {
            return Theme.Colors.success
        } else if score >= 60 {
            return Theme.Colors.primary
        } else if score > 0 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.subtext.opacity(0.5)
        }
    }
}

// チャート期間の列挙型
enum ChartPeriod {
    case week
    case month
}

#Preview {
    SleepDashboardView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(LocalizationManager.shared)
} 