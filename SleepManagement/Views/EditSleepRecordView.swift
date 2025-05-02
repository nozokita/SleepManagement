import SwiftUI

struct EditSleepRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    // 編集対象の睡眠記録
    var record: SleepRecord
    
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var quality: Int16
    @State private var memo: String
    
    @State private var showPreview = false
    @State private var previewScore: Double = 0
    @State private var previewDebt: Double = 0
    
    // 初期化
    init(record: SleepRecord) {
        self.record = record
        
        // 初期値の設定
        _startDate = State(initialValue: record.startAt ?? Date())
        _endDate = State(initialValue: record.endAt ?? Date())
        _quality = State(initialValue: record.quality)
        _memo = State(initialValue: record.memo ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー部分
                        VStack(alignment: .leading, spacing: 6) {
                            Text("edit_sleep_record_title".localized)
                            
                            Text("edit_sleep_record_subtitle".localized)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Theme.Colors.cardGradient)
                        .cornerRadius(Theme.Layout.cardCornerRadius)
                        .padding(.horizontal)
                        
                        // 睡眠時間セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("sleep_time".localized)
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            VStack(spacing: 12) {
                                DatePicker("bedtime".localized, selection: $startDate)
                                    .onChange(of: startDate) { oldValue, newValue in
                                        calculatePreview()
                                    }
                                    .foregroundColor(Theme.Colors.text)
                                
                                DatePicker("wake_time".localized, selection: $endDate)
                                    .onChange(of: endDate) { oldValue, newValue in
                                        calculatePreview()
                                    }
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Layout.cardCornerRadius)
                        }
                        .padding(.horizontal)
                        
                        // 睡眠の質セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("sleep_quality".localized)
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            VStack {
                                HStack {
                                    Text("1")
                                        .font(Theme.Typography.captionFont)
                                        .foregroundColor(Theme.Colors.subtext)
                                    
                                    Spacer()
                                    
                                    Text("5")
                                        .font(Theme.Typography.captionFont)
                                        .foregroundColor(Theme.Colors.subtext)
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(quality) },
                                    set: { quality = Int16($0) }
                                ), in: 1...5, step: 1)
                                .onChange(of: quality) { oldValue, newValue in
                                    calculatePreview()
                                }
                                .accentColor(qualityColor)
                                
                                HStack {
                                    Text("bad".localized)
                                        .font(Theme.Typography.captionFont)
                                        .foregroundColor(Theme.Colors.subtext)
                                    
                                    Spacer()
                                    
                                    Text("\(quality)")
                                        .font(Theme.Typography.bodyFont.bold())
                                        .foregroundColor(qualityColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(qualityColor.opacity(0.1))
                                        .cornerRadius(12)
                                    
                                    Spacer()
                                    
                                    Text("good_quality".localized)
                                        .font(Theme.Typography.captionFont)
                                        .foregroundColor(Theme.Colors.subtext)
                                }
                            }
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Layout.cardCornerRadius)
                        }
                        .padding(.horizontal)
                        
                        // メモセクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("memo_optional".localized)
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            TextEditor(text: $memo)
                                .frame(minHeight: 60)
                                .foregroundColor(Theme.Colors.text)
                                .padding()
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.Layout.cardCornerRadius)
                        }
                        .padding(.horizontal)
                        
                        // スコアプレビュー
                        if showPreview {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("score_preview".localized)
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.primary)
                                
                                VStack(spacing: 16) {
                                    HStack {
                                        Spacer()
                                        
                                        VStack(spacing: 8) {
                                            // 仮眠時はNapラベルを表示
                                            if record.sleepType == SleepRecordType.nap.rawValue {
                                                ZStack {
                                                    Circle()
                                                        .stroke(Theme.Colors.subtext, lineWidth: 1)
                                                        .frame(width: 150, height: 150)
                                                    Text("nap".localized)
                                                        .font(.system(size: 24, weight: .bold))
                                                        .foregroundColor(Theme.Colors.subtext)
                                                }
                                                Text("nap".localized)
                                                    .font(Theme.Typography.captionFont)
                                                    .foregroundColor(Theme.Colors.subtext)
                                            } else {
                                                ZStack {
                                                    // スコア背景の円
                                                    Circle()
                                                        .fill(qualityColor.opacity(0.1))
                                                        .frame(width: 150, height: 150)
                                                    // スコアビュー
                                                    SleepScoreView(score: previewScore, size: 120)
                                                }
                                                .padding(.bottom, 8)
                                                Text("sleep_score".localized)
                                                    .font(Theme.Typography.bodyFont)
                                                    .foregroundColor(Theme.Colors.subtext)
                                            }
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "bed.double")
                                                    .foregroundColor(Theme.Colors.primary)
                                                
                                                Text(formatDuration())
                                                    .font(Theme.Typography.bodyFont.bold())
                                                    .foregroundColor(Theme.Colors.text)
                                            }
                                            
                                            // nap時は睡眠負債と分析を非表示
                                            if record.sleepType != SleepRecordType.nap.rawValue {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .foregroundColor(debtColor)
                                                    Text("\("sleep_debt".localized): \(String(format: "%.1fh", previewDebt))")
                                                        .font(Theme.Typography.bodyFont.bold())
                                                        .foregroundColor(debtColor)
                                                }
                                                Spacer()
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding()
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.Layout.cardCornerRadius)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("edit_sleep_record_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("cancel".localized)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { updateRecord() }) {
                        Text("save".localized)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.primary)
                }
            }
            .onAppear {
                calculatePreview()
            }
        }
    }
    
    private var qualityColor: Color {
        return Theme.Colors.scoreColor(score: Double(quality) * 20)
    }
    
    private var debtColor: Color {
        return Theme.Colors.scoreColor(score: max(0, 100 - previewDebt * 10))
    }
    
    private var durationColor: Color {
        let duration = endDate.timeIntervalSince(startDate) / 3600
        if duration < 6 {
            return Theme.Colors.danger
        } else if duration < 7 {
            return Theme.Colors.warning
        } else if duration < 9 {
            return Theme.Colors.success
        } else {
            return Theme.Colors.info
        }
    }
    
    private var qualityMessage: String {
        if localizationManager.currentLanguage == "ja" {
            switch quality {
            case 1:
                return "非常に悪い睡眠です。改善が必要です。"
            case 2:
                return "あまり良くない睡眠でした。"
            case 3:
                return "平均的な睡眠の質です。"
            case 4:
                return "良好な睡眠が取れました。"
            case 5:
                return "素晴らしい睡眠の質です！"
            default:
                return ""
            }
        } else {
            switch quality {
            case 1: return "Very poor sleep. Improvement needed."
            case 2: return "Not very good sleep."
            case 3: return "Average sleep quality."
            case 4: return "Good sleep quality."
            case 5: return "Excellent sleep quality!"
            default: return ""
            }
        }
    }
    
    private var durationMessage: String {
        let duration = endDate.timeIntervalSince(startDate) / 3600
        if localizationManager.currentLanguage == "ja" {
            if duration < 5 {
                return "睡眠時間が短すぎます。最低でも7時間は睡眠を取りましょう。"
            } else if duration < 6 {
                return "睡眠時間がやや不足しています。"
            } else if duration < 8 {
                return "理想的な睡眠時間です。"
            } else {
                return "睡眠時間が長すぎるかもしれません。質の高い睡眠を心がけましょう。"
            }
        } else {
            if duration < 5 {
                return "Sleep duration is too short. Aim for at least 7 hours."
            } else if duration < 6 {
                return "Sleep duration is slightly low."
            } else if duration < 8 {
                return "Ideal sleep duration."
            } else {
                return "You may be oversleeping; focus on sleep quality."
            }
        }
    }
    
    private func formatDuration() -> String {
        let durationSeconds = endDate.timeIntervalSince(startDate)
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) % 3600 / 60
        // 単位をローカライズ
        let hoursKey = "hours".localized
        let minutesKey = "minutes".localized
        if LocalizationManager.shared.currentLanguage == "ja" {
            // 日本語: 例: 3時間15分
            return "\(hours)\(hoursKey)\(minutes)\(minutesKey)"
        } else {
            // 英語: 例: 3 hours 15 min
            return "\(hours) \(hoursKey) \(minutes)\(minutesKey)"
        }
    }
    
    private func analysisRow(icon: String, color: Color, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(8)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.bodyFont.bold())
                    .foregroundColor(Theme.Colors.text)
                
                Text(message)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func calculatePreview() {
        let sleepManager = SleepManager.shared
        previewScore = sleepManager.calculateSleepScore(startAt: startDate, endAt: endDate, quality: quality)
        
        let durationHours = endDate.timeIntervalSince(startDate) / 3600
        previewDebt = sleepManager.calculateDailyDebt(sleepHours: durationHours)
        
        showPreview = true
    }
    
    private func updateRecord() {
        // 既存のレコードを更新
        record.startAt = startDate
        record.endAt = endDate
        record.quality = quality
        record.memo = memo.isEmpty ? nil : memo
        
        // スコアと負債の再計算
        let sleepManager = SleepManager.shared
        let durationHours = endDate.timeIntervalSince(startDate) / 3600
        record.score = sleepManager.calculateSleepScore(startAt: startDate, endAt: endDate, quality: quality)
        record.debt = sleepManager.calculateDailyDebt(sleepHours: durationHours)
        
        // 保存
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("睡眠記録の更新に失敗しました: \(error)")
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let record = SleepRecord(context: context)
    record.id = UUID()
    record.startAt = Calendar.current.date(byAdding: .hour, value: -8, to: Date())!
    record.endAt = Date()
    record.quality = 4
    record.score = 85
    record.debt = 1.5
    record.memo = "よく眠れました"
    
    return EditSleepRecordView(record: record)
        .environment(\.managedObjectContext, context)
        .environmentObject(LocalizationManager.shared)
} 