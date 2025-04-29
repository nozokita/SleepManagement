import SwiftUI
import CoreData
import HealthKit

// SleepDashboardViewの記述を削除

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var localizationManager: LocalizationManager
    @FetchRequest(fetchRequest: SleepRecord.allRecordsFetchRequest()) private var sleepRecords: FetchedResults<SleepRecord>
    
    @StateObject private var sleepManager = SleepManager.shared
    @State private var showingAddSheet = false
    @State private var showingSleepInputSheet = false
    @State private var totalDebt: Double = 0
    
    // 編集用・削除用状態
    @State private var selectedRecordForEdit: SleepRecord? = nil
    
    // アニメーション用の状態
    @State private var animatedCards: Bool = false
    @State private var selectedTab: Int = 0
    @State private var refreshing: Bool = false
    
    // 過去24時間の睡眠負債（時間）
    @State private var debtHours: Double = 0
    
    // タブアイテム
    private var tabs: [String] {
        return ["home_tab", "stats_tab", "sleep_log_tab"].map { $0.localized }
    }
    
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // カスタムヘッダー
                    headerView
                    
                    // カスタムタブビュー
                    customTabView
                    
                    // メインコンテンツ（サイズ拡大）
                    if selectedTab == 0 {
                        // ホームタブのコンテンツ
                        ScrollView {
                            VStack(spacing: 16) {
                                // 睡眠サマリーカード
                                sleepSummaryCard
                                
                                // 睡眠負債カード
                                sleepDebtCard
                                
                                // AI診断・アドバイスセクション
                                aiAdviceSection
                                
                                // 最近の睡眠記録
                                recentSleepRecordsSection
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 80) // FABのスペース確保
                        }
                        .refreshable {
                            refreshData()
                        }
                    } else if selectedTab == 1 {
                        // 統計タブ - 睡眠ダッシュボード
                        SleepDashboardView()
                            .environmentObject(localizationManager)
                            .environment(\.managedObjectContext, viewContext)
                    } else {
                        // 睡眠セッション一覧タブ
                        SleepSessionListView()
                            .padding(.bottom, 80) // FABのスペース確保
                    }
                }
                
                // FABボタン
                fabButton
            }
            .navigationBarHidden(true)
            .onAppear {
                // HealthKit自動同期（設定でオンなら起動時に同期を実行）
                if SettingsManager.shared.autoSyncHealthKit && HKHealthStore.isHealthDataAvailable() {
                    SleepManager.shared.syncSleepDataFromHealthKit(context: viewContext) { error in
                        if let error = error {
                            print("HomeView HealthKit sync error: \(error)")
                        } else {
                            print("HomeView HealthKit sync completed")
                        }
                    }
                }
                calculateTotalDebt()
                sleepManager.requestNotificationPermission()
                
                // 過去24時間の負債をロード
                loadDebt()
                
                // アニメーション
                withAnimation(Theme.Animations.springy.delay(0.3)) {
                    animatedCards = true
                }
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: {
                calculateTotalDebt()
            }) {
                AddSleepRecordView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingSleepInputSheet, onDismiss: {
                calculateTotalDebt()
            }) {
                SleepInputView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
            }
            // 編集シート表示
            .sheet(item: $selectedRecordForEdit) { record in
                EditSleepRecordView(record: record)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // ヘッダービュー
    private var headerView: some View {
        ZStack {
            // 背景グラデーション
            Theme.Colors.primaryGradient
                .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedAppName)
                            .font(Theme.Typography.headingFont)
                            .foregroundColor(.white)
                        
                        Text("home_subtitle".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // 言語切り替えボタン
                    Button(action: {
                        localizationManager.toggleLanguage()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.body)
                            Text("switch_language".localized)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                    }
                    
                    // 設定ボタン
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                
                if let latestRecord = sleepRecords.first, !sleepRecords.isEmpty {
                    // 最新の睡眠サマリー
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.stars")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("last_sleep".localized)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(latestRecord.durationText)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("sleep_score".localized)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(Int(latestRecord.score))" + "points".localized)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 45)
            .padding(.bottom, 15)
        }
        .frame(height: 150) // ヘッダーの高さを増やす
    }
    
    // カスタムタブビュー
    private var customTabView: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tabs[index])
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .bold : .regular)
                            .foregroundColor(selectedTab == index ? Theme.Colors.primary : Theme.Colors.subtext)
                        
                        // 選択インジケーター
                        Rectangle()
                            .fill(selectedTab == index ? Theme.Colors.primary : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
        .frame(height: 40) // タブの高さを増やす
    }
    
    // 睡眠サマリーカード
    private var sleepSummaryCard: some View {
        VStack(spacing: 0) {
            // カードヘッダー
            HStack {
                Label("sleep_summary".localized, systemImage: "bed.double")
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("\(sleepRecords.count)" + "records".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.cardGradient)
            
            Divider()
            
            // 睡眠統計グリッド
            if !sleepRecords.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // 平均睡眠時間
                    statView(
                        title: "avg_duration".localized,
                        value: averageSleepDurationText,
                        icon: "clock",
                        color: Theme.Colors.primary
                    )
                    
                    // 平均睡眠スコア
                    statView(
                        title: "avg_score".localized,
                        value: "\(Int(averageSleepScore))" + "points".localized,
                        icon: "star",
                        color: sleepScoreColor
                    )
                    
                    // 最長睡眠時間
                    statView(
                        title: "longest_sleep".localized,
                        value: longestSleepText,
                        icon: "arrow.up",
                        color: Theme.Colors.success
                    )
                    
                    // 平均就寝時間
                    statView(
                        title: "avg_bedtime".localized,
                        value: averageBedTimeText,
                        icon: "moon",
                        color: Theme.Colors.secondary
                    )
                }
                .padding(16)
            } else {
                // データがない場合のビュー
                emptyStateView
            }
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .offset(y: animatedCards ? 0 : 50)
        .opacity(animatedCards ? 1 : 0)
    }
    
    // 睡眠負債カード
    private var sleepDebtCard: some View {
        SleepDebtView(totalDebt: debtHours)
    }
    
    // AI診断・アドバイスセクション
    private var aiAdviceSection: some View {
        VStack(spacing: 0) {
            // カードヘッダー
            HStack {
                Label("ai_advice".localized, systemImage: "brain")
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Text("in_development".localized)
                    .font(Theme.Typography.captionFont.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.info.opacity(0.2))
                    .foregroundColor(Theme.Colors.info)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.cardGradient)
            
            Divider()
            
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.Colors.info)
                
                Text("ai_analysis".localized)
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Text("ai_description".localized)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.subtext)
                    .multilineTextAlignment(.center)
                
                Text("coming_soon".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .offset(y: animatedCards ? 0 : 50)
        .opacity(animatedCards ? 1 : 0)
    }
    
    // 最近の睡眠記録セクション
    private var recentSleepRecordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("recent_records".localized)
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                NavigationLink(destination: SleepRecordListView()) {
                    HStack(spacing: 4) {
                        Text("view_all".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .padding(.horizontal)
            
            if sleepRecords.isEmpty {
                emptyStateView
                    .padding(.top, 8)
            } else {
                // 最大3件の記録を表示
                let recentRecords = Array(sleepRecords.prefix(3))
                
                ForEach(Array(zip(recentRecords.indices, recentRecords)), id: \.0) { index, record in
                    NavigationLink {
                        SleepRecordDetailView(record: record)
                    } label: {
                        sleepRecordRow(record: record, index: index)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing) {
                        // 編集
                        Button {
                            selectedRecordForEdit = record
                        } label: {
                            Label("list.edit".localized, systemImage: "pencil")
                        }
                        .tint(.blue)
                        // 削除
                        Button(role: .destructive) {
                            deleteRecord(record)
                        } label: {
                            Label("list.delete".localized, systemImage: "trash")
                        }
                    }
                }
                // HealthKit同期案内メッセージ
                Text("recent.syncHealthKit.message".localized)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
                    .padding(.top, 4)
            }
        }
        .offset(y: animatedCards ? 0 : 50)
        .opacity(animatedCards ? 1 : 0)
    }
    
    // 睡眠記録の行アイテム
    private func sleepRecordRow(record: SleepRecord, index: Int) -> some View {
        HStack(spacing: 16) {
            // スコア表示
            SleepScoreView(score: record.score, size: 60, showAnimation: false)
            
            VStack(alignment: .leading, spacing: 4) {
                // 日付
                Text(record.sleepDateText)
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.text)
                
                // 睡眠時間
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("\(record.startTimeText) - \(record.endTimeText)")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.text)
                }
                
                // 睡眠の長さ
                HStack(spacing: 8) {
                    Image(systemName: "bed.double")
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text(record.durationText)
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.text)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.Colors.subtext)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .offset(y: animatedCards ? 0 : 20 * Double(index + 1))
        .opacity(animatedCards ? 1 : 0)
        .animation(Theme.Animations.springy.delay(0.1 * Double(index + 3)), value: animatedCards)
    }
    
    // FABボタン
    private var fabButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    print("記録を追加ボタンがタップされました")
                    DispatchQueue.main.async {
                        // 睡眠入力画面を表示
                        showingSleepInputSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.headline)
                        
                        Text("add_record".localized)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Theme.Colors.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                .padding([.trailing, .bottom], 24)
            }
        }
    }
    
    // 統計ビュー
    private func statView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // アイコンとタイトル
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
            
            // 値
            Text(value)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 空の状態ビュー
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.primary.opacity(0.8))
            
            Text("no_records".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
            
            Text("add_first_record".localized)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.center)
            
            Button(action: {
                print("記録を追加するボタンがタップされました")
                DispatchQueue.main.async {
                    // 睡眠入力画面を表示
                    showingSleepInputSheet = true
                }
            }) {
                Text("add_record_button".localized)
                    .font(Theme.Typography.bodyFont.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Theme.Colors.primaryGradient)
                    .cornerRadius(10)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - 計算プロパティ
    
    // 有効な通常睡眠レコード（仮眠や不正入力を除外）
    private var validNormalRecords: [SleepRecord] {
        sleepRecords.filter { record in
            // 通常睡眠のみ
            record.sleepType == SleepRecordType.normalSleep.rawValue &&
            // 開始/終了時刻の正当性チェック
            record.startAt != nil && record.endAt != nil && record.endAt! > record.startAt!
        }
    }
    
    // 平均睡眠時間
    private var averageSleepDuration: TimeInterval {
        let records = validNormalRecords
        guard !records.isEmpty else { return 0 }
        let durations = records.compactMap { record -> TimeInterval? in
            guard let start = record.startAt, let end = record.endAt else { return nil }
            return end.timeIntervalSince(start)
        }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private var averageSleepDurationText: String {
        let hours = Int(averageSleepDuration / 3600)
        let minutes = Int((averageSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        if localizationManager.currentLanguage == "ja" {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // 平均睡眠スコア
    private var averageSleepScore: Double {
        let records = validNormalRecords
        guard !records.isEmpty else { return 0 }
        let scores = records.map { $0.score }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private var sleepScoreColor: Color {
        return Theme.Colors.scoreColor(score: averageSleepScore)
    }
    
    // 最長睡眠時間
    private var longestSleepDuration: TimeInterval {
        let records = validNormalRecords
        guard !records.isEmpty else { return 0 }
        let durations = records.compactMap { record -> TimeInterval? in
            guard let start = record.startAt, let end = record.endAt else { return nil }
            return end.timeIntervalSince(start)
        }
        return durations.max() ?? 0
    }
    
    private var longestSleepText: String {
        let hours = Int(longestSleepDuration / 3600)
        let minutes = Int((longestSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        if localizationManager.currentLanguage == "ja" {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // 平均就寝時間
    private var averageBedTimeText: String {
        let records = validNormalRecords
        guard !records.isEmpty else { return "00:00" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let bedTimes = records.compactMap { record -> Int? in
            guard let startAt = record.startAt else { return nil }
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: startAt)
            let minute = calendar.component(.minute, from: startAt)
            return hour * 60 + minute
        }
        guard !bedTimes.isEmpty else { return "00:00" }
        let averageMinutes = bedTimes.reduce(0, +) / bedTimes.count
        let averageHour = averageMinutes / 60
        let averageMinute = averageMinutes % 60
        return String(format: "%02d:%02d", averageHour, averageMinute)
    }
    
    // MARK: - メソッド
    
    private func calculateTotalDebt() {
        totalDebt = sleepManager.calculateTotalDebt(context: viewContext)
    }
    
    private func refreshData() {
        refreshing = true
        calculateTotalDebt()
        
        // 最新の負債を再計算
        loadDebt()
        
        // リフレッシュアニメーション用の遅延
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshing = false
        }
    }
    
    // 削除関数
    private func deleteRecord(_ record: SleepRecord) {
        viewContext.delete(record)
        do {
            try viewContext.save()
            calculateTotalDebt()
        } catch {
            print("削除エラー: \(error)")
        }
    }
    
    // MARK: - データ処理
    /// 24時間分の急性睡眠負債（ローリング24h）を計算して更新
    private func loadDebt() {
        debtHours = sleepManager.calculateAcuteDebt(context: viewContext)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(LocalizationManager.shared)
} 