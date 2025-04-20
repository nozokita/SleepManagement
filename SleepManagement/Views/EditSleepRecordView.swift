import SwiftUI

struct EditSleepRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
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
                            Text("睡眠記録の編集")
                                .font(Theme.Typography.headingFont)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("睡眠の詳細を更新します")
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.subtext)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Theme.Colors.cardGradient)
                        .cornerRadius(Theme.Layout.cardCornerRadius)
                        .padding(.horizontal)
                        
                        // 睡眠時間セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("睡眠時間")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            VStack(spacing: 12) {
                                DatePicker("開始時刻", selection: $startDate)
                                    .onChange(of: startDate) { oldValue, newValue in
                                        calculatePreview()
                                    }
                                    .foregroundColor(Theme.Colors.text)
                                
                                DatePicker("終了時刻", selection: $endDate)
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
                            Text("睡眠の質 (1〜5)")
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
                                    Text("悪い")
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
                                    
                                    Text("良い")
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
                            Text("メモ (任意)")
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
                                Text("スコアプレビュー")
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.primary)
                                
                                VStack(spacing: 16) {
                                    HStack {
                                        Spacer()
                                        
                                        VStack(spacing: 8) {
                                            ZStack {
                                                // スコア背景の円
                                                Circle()
                                                    .fill(qualityColor.opacity(0.1))
                                                    .frame(width: 150, height: 150)
                                                
                                                // スコアビュー
                                                SleepScoreView(score: previewScore, size: 120)
                                            }
                                            .padding(.bottom, 8)
                                            
                                            Text("睡眠スコア")
                                                .font(Theme.Typography.bodyFont)
                                                .foregroundColor(Theme.Colors.subtext)
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "bed.double")
                                                    .foregroundColor(Theme.Colors.primary)
                                                
                                                Text(formatDuration())
                                                    .font(Theme.Typography.bodyFont.bold())
                                                    .foregroundColor(Theme.Colors.text)
                                            }
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundColor(debtColor)
                                                
                                                Text("睡眠負債: \(String(format: "%.1f時間", previewDebt))")
                                                    .font(Theme.Typography.bodyFont.bold())
                                                    .foregroundColor(debtColor)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    
                                    // 睡眠分析結果
                                    if previewScore > 0 {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("睡眠分析")
                                                .font(Theme.Typography.subheadingFont)
                                                .foregroundColor(Theme.Colors.text)
                                            
                                            analysisRow(
                                                icon: "moon.stars",
                                                color: qualityColor,
                                                title: "睡眠の質",
                                                message: qualityMessage
                                            )
                                            
                                            analysisRow(
                                                icon: "clock",
                                                color: durationColor,
                                                title: "睡眠時間",
                                                message: durationMessage
                                            )
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(12)
                                    }
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
            .navigationTitle("睡眠記録の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        updateRecord()
                    } label: {
                        Text("保存")
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
    }
    
    private var durationMessage: String {
        let duration = endDate.timeIntervalSince(startDate) / 3600
        if duration < 5 {
            return "睡眠時間が短すぎます。最低でも7時間は睡眠を取りましょう。"
        } else if duration < 6 {
            return "睡眠時間がやや不足しています。"
        } else if duration < 8 {
            return "理想的な睡眠時間です。"
        } else {
            return "睡眠時間が長すぎるかもしれません。質の高い睡眠を心がけましょう。"
        }
    }
    
    private func formatDuration() -> String {
        let durationSeconds = endDate.timeIntervalSince(startDate)
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) % 3600 / 60
        return "\(hours)時間\(minutes)分"
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
} 