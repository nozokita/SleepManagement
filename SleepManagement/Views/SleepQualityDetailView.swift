import SwiftUI

/// 睡眠の質スコアの詳細表示画面
struct SleepQualityDetailView: View {
    let sleepEntry: SleepEntry
    
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var sleepManager = SleepManager.shared
    
    @State private var sleepQualityScore: SleepQualityScore?
    @State private var sleepQualityData: SleepQualityData?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let score = sleepQualityScore, let data = sleepQualityData {
                    // スコア表示ビュー
                    SleepQualityScoreView(score: score, sleepData: data)
                } else {
                    // データ読み込み中
                    ProgressView()
                        .padding()
                    Text("睡眠データを分析中...")
                        .foregroundColor(.secondary)
                }
                
                // 睡眠データの概要セクション
                sleepEntrySummary
            }
            .padding()
        }
        .navigationTitle("睡眠の質詳細")
        .onAppear {
            // 画面表示時にスコア計算
            calculateSleepQualityScore()
        }
    }
    
    private var sleepEntrySummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠記録の概要")
                .font(.headline)
                .padding(.top)
            
            Divider()
            
            // 睡眠日時情報
            if let date = sleepEntry.date {
                detailRow(title: "日付", value: formatDate(date))
            }
            
            // 睡眠時間帯
            HStack {
                if let bedTime = sleepEntry.bedTime {
                    detailRow(title: "就寝時刻", value: formatTime(bedTime))
                }
                
                Spacer()
                
                if let wakeTime = sleepEntry.wakeTime {
                    detailRow(title: "起床時刻", value: formatTime(wakeTime))
                }
            }
            
            // 睡眠時間
            if let duration = sleepEntry.duration {
                detailRow(
                    title: "睡眠時間",
                    value: formatDuration(duration)
                )
            }
            
            // 主観評価
            subjektiveSleepQualitySection
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var subjektiveSleepQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主観的評価")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // 主観的な睡眠の質
            if let quality = sleepEntry.sleepQuality {
                ratingRow(title: "睡眠の質", rating: quality)
            }
            
            // 入眠のしやすさ
            if let fallAsleepEase = sleepEntry.fallAsleepEase {
                ratingRow(title: "入眠のしやすさ", rating: fallAsleepEase)
            }
            
            // 睡眠の連続性
            if let continuity = sleepEntry.sleepContinuity {
                ratingRow(title: "睡眠の連続性", rating: continuity)
            }
            
            // 目覚めの気分
            if let feeling = sleepEntry.morningFeeling {
                ratingRow(title: "目覚め時の気分", rating: feeling)
            }
        }
    }
    
    // 詳細行
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // 評価行（星評価）
    private func ratingRow(title: String, rating: Int16) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .foregroundColor(i <= rating ? .yellow : .gray)
                        .font(.system(size: 12))
                }
            }
        }
    }
    
    // 睡眠の質スコアを計算
    private func calculateSleepQualityScore() {
        // 睡眠データを生成
        let sleepData = generateSleepQualityData()
        self.sleepQualityData = sleepData
        
        // スコア計算
        let score = SleepQualityScore.calculate(from: sleepData)
        self.sleepQualityScore = score
    }
    
    // 睡眠の質データを生成
    private func generateSleepQualityData() -> SleepQualityData {
        // 過去7日間の睡眠データを取得
        let previousEntries = fetchPreviousSleepEntries()
        
        // SleepQualityDataを生成
        return SleepQualityData.fromSleepEntry(
            sleepEntry,
            sleepHistoryEntries: previousEntries,
            windowDays: 7
        )
    }
    
    // 過去の睡眠データを取得
    private func fetchPreviousSleepEntries() -> [SleepEntry] {
        guard let date = sleepEntry.date else { return [] }
        
        // 現在の日付から7日前までのデータを取得
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: date) else {
            return []
        }
        
        let fetchRequest: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND id != %@", 
                                           startDate as NSDate, 
                                           date as NSDate,
                                           sleepEntry.id as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("睡眠データの取得エラー: \(error)")
            return []
        }
    }
    
    // 日付のフォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // 時刻のフォーマット
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // 期間のフォーマット
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
} 