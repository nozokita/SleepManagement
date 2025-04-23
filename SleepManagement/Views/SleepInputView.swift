import SwiftUI

struct SleepInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    @State private var startDate = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var quality: Int16 = 3
    @State private var memo: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if watchManager.isCheckingAvailability {
                    // Apple Watchの有無チェック中
                    loadingView
                } else if watchManager.isWatchAvailable {
                    // Apple Watchを持っている場合（開発中）
                    watchUserView
                } else {
                    // Apple Watchを持っていない場合（手動入力）
                    manualInputView
                }
            }
            .navigationTitle("睡眠記録")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // ローディング中ビュー
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("デバイス確認中...")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.text)
        }
    }
    
    // Apple Watch持ちユーザー向けビュー（開発中）
    private var watchUserView: some View {
        VStack(spacing: 24) {
            Image(systemName: "applewatch")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary.opacity(0.6))
            
            Text("Apple Watch連携")
                .font(Theme.Typography.headingFont)
                .foregroundColor(Theme.Colors.text)
            
            Text("この機能は現在開発中です")
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.subtext)
            
            Text("Apple Watchの睡眠データを自動で取得し、より正確な睡眠分析を提供します。")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            HStack {
                Spacer()
                
                Text("開発中")
                    .font(Theme.Typography.captionFont.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.info.opacity(0.2))
                    .foregroundColor(Theme.Colors.info)
                    .cornerRadius(20)
                
                Spacer()
            }
            .padding(.top, 16)
            
            Button(action: {
                // 一時的に手動入力モードに切り替え（開発用）
                self.watchManager.isWatchAvailable = false
            }) {
                Text("手動で睡眠を記録する")
                    .font(Theme.Typography.bodyFont.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.primaryGradient)
                    .cornerRadius(12)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
        }
    }
    
    // 手動入力ビュー（Apple Watchなしユーザー向け）
    private var manualInputView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 6) {
                    Text("睡眠時間を記録")
                        .font(Theme.Typography.headingFont)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("就寝時間と起床時間を記録して、睡眠状態を把握しましょう")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Theme.Colors.cardGradient)
                .cornerRadius(Theme.Layout.cardCornerRadius)
                .padding(.horizontal)
                
                // 睡眠時間入力セクション
                VStack(alignment: .leading, spacing: 16) {
                    Text("睡眠時間")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    VStack(spacing: 12) {
                        DatePicker("就寝時間", selection: $startDate)
                            .foregroundColor(Theme.Colors.text)
                        
                        DatePicker("起床時間", selection: $endDate)
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
                
                // 睡眠時間情報
                VStack(alignment: .leading, spacing: 8) {
                    Text("睡眠時間: \(formatDuration())")
                        .font(Theme.Typography.bodyFont.bold())
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("※正確な睡眠データにはApple Watchが必要です")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 保存ボタン
                Button(action: {
                    saveRecord()
                }) {
                    Text("睡眠記録を保存")
                        .font(Theme.Typography.bodyFont.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.primaryGradient)
                        .cornerRadius(12)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
        }
    }
    
    // 睡眠の質に応じた色
    private var qualityColor: Color {
        return Theme.Colors.scoreColor(score: Double(quality) * 20)
    }
    
    // 睡眠時間のフォーマット
    private func formatDuration() -> String {
        let durationSeconds = endDate.timeIntervalSince(startDate)
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) % 3600 / 60
        return "\(hours)時間\(minutes)分"
    }
    
    // 睡眠記録の保存
    private func saveRecord() {
        let sleepManager = SleepManager.shared
        let _ = sleepManager.addSleepRecord(
            context: viewContext,
            startAt: startDate,
            endAt: endDate,
            quality: quality,
            memo: memo.isEmpty ? nil : memo
        )
        
        dismiss()
    }
}

#Preview {
    SleepInputView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
} 