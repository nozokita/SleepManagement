import SwiftUI
import CoreData
import Combine

struct SleepInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @ObservedObject var watchConnectivityManager = WatchConnectivityManager.shared
    
    // 睡眠データの入力用
    @State private var selectedDate = Date()
    @State private var sleepTime = Date().addingTimeInterval(-8 * 3600) // 8時間前をデフォルトに
    @State private var wakeTime = Date()
    @State private var quality: Double = 3
    @State private var sleepMode: SleepMode = .manual
    
    // アラート表示用
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // 入力モード
    enum SleepMode: String, CaseIterable, Identifiable {
        case manual = "manual"
        case watchData = "watch_data"
        
        var id: String { self.rawValue }
        
        var localizedTitle: String {
            return self.rawValue.localized
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ヘッダー表示
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    
                    // 入力モード選択
                    inputModeSelector
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .padding(.bottom, 8) // 入力モードの下部パディングを減らす
                    
                    // スクロール可能なコンテンツエリア
                    if sleepMode == .manual {
                        // 手動入力フォーム
                        manualInputForm
                            .padding(.bottom, 85) // 保存ボタンの高さ分空ける
                    } else {
                        // Apple Watchデータ取得
                        watchDataView
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .padding(.bottom, 85) // 保存ボタンの高さ分空ける
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // 保存ボタン（下部に固定）
                VStack {
                    Spacer()
                    
                    Button(action: saveSleepRecord) {
                        Text("save".localized)
                            .font(Theme.Typography.bodyFont.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.primaryGradient)
                            .cornerRadius(12)
                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .background(
                        Rectangle()
                            .fill(Theme.Colors.background)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -3)
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("cancel".localized)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("sleep_input_title".localized)
                        .font(Theme.Typography.titleFont)
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // ヘッダー
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sleep_record_instruction".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
            
            Text("sleep_input_description".localized)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 入力モード選択
    private var inputModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("input_mode".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
            
            Picker("Input Mode", selection: $sleepMode) {
                ForEach(SleepMode.allCases) { mode in
                    Text(mode.localizedTitle).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: sleepMode) { newValue in
                if newValue == .watchData {
                    watchConnectivityManager.requestSleepData()
                }
            }
        }
    }
    
    // 手動入力フォーム
    private var manualInputForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 日付選択
                VStack(alignment: .leading, spacing: 10) {
                    Text("date".localized)
                        .font(Theme.Typography.subheadingFont)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                    
                    ZStack {
                        // カレンダー内のDatePicker
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden() // ラベルを非表示
                            .frame(height: 270)
                            .scaleEffect(0.9)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.cardBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                    }
                    .frame(height: 260)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .padding(.horizontal, 2)
                .padding(.bottom, 8) // 入力モードと同じ8ピクセルに変更
                
                // セクション区切り（空のスペース）
                // Spacerを削除（入力モードと日付の間にはSpacerがないため）
                
                // 就寝時間とウェイク時間セクション（背景色で区別）
                VStack(alignment: .leading, spacing: 12) {
                    Text("sleep_duration".localized)
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(Theme.Colors.text)
                        .padding(.top, 5) // 見出しの上にも少しスペースを追加
                    
                    HStack(spacing: 20) {
                        // 就寝時間
                        VStack(alignment: .leading, spacing: 6) {
                            Text("sleep_time".localized)
                                .font(Theme.Typography.bodyFont)
                                .foregroundColor(Theme.Colors.subtext)
                            
                            DatePicker("", selection: $sleepTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Theme.Colors.cardBackground)
                                )
                        }
                        
                        // 起床時間
                        VStack(alignment: .leading, spacing: 6) {
                            Text("wake_time".localized)
                                .font(Theme.Typography.bodyFont)
                                .foregroundColor(Theme.Colors.subtext)
                            
                            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Theme.Colors.cardBackground)
                                )
                        }
                    }
                    
                    // 睡眠時間表示
                    HStack {
                        Spacer()
                        Text(sleepDurationText)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .padding(.horizontal, 2)
                .padding(.bottom, 8) // 睡眠時間の下のスペースを調整
                
                // セクション区切り（空のスペース）
                // Spacerを削除（入力モードと日付の間にはSpacerがないため）
                
                // 睡眠の質
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("sleep_quality".localized)
                            .font(Theme.Typography.subheadingFont)
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                        
                        Text("\(Int(quality))" + "points".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top, 5)
                    
                    Slider(value: $quality, in: 1...5, step: 1)
                        .accentColor(Theme.Colors.primary)
                    
                    HStack {
                        Text("poor".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                        
                        Spacer()
                        
                        Text("excellent".localized)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.subtext)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                )
                .padding(.horizontal, 2)
            }
            .padding(.vertical, 8)
        }
    }
    
    // 睡眠時間テキスト
    private var sleepDurationText: String {
        let duration = wakeTime.timeIntervalSince(sleepTime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "sleep_duration".localized + " \(hours)" + "hours".localized + " \(minutes)" + "minutes".localized
    }
    
    // Apple Watchのデータ表示
    private var watchDataView: some View {
        VStack(spacing: 20) {
            if watchConnectivityManager.isWatchAvailable {
                if let healthData = watchConnectivityManager.lastReceivedHealthData {
                    // データ表示
                    watchDataResultView(data: healthData)
                } else {
                    // データ取得中
                    watchDataLoadingView
                }
            } else {
                // Watchが接続されていない
                watchNotConnectedView
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(12)
    }
    
    // Watchデータの表示
    private func watchDataResultView(data: WatchHealthData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("watch_data_received".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.success)
            
            Group {
                dataRow(title: "sleep_time".localized, value: data.sleepTime.formatted(date: Date.FormatStyle.DateStyle.omitted, time: Date.FormatStyle.TimeStyle.shortened))
                dataRow(title: "wake_time".localized, value: data.wakeTime.formatted(date: Date.FormatStyle.DateStyle.omitted, time: Date.FormatStyle.TimeStyle.shortened))
                dataRow(title: "total_duration".localized, value: data.durationFormatted)
                dataRow(title: "deep_sleep".localized, value: data.deepSleepFormatted)
                dataRow(title: "heart_rate".localized, value: "\(Int(data.avgHeartRate)) bpm")
            }
            
            Button(action: {
                // Watchデータを手動入力に反映
                sleepTime = data.sleepTime
                wakeTime = data.wakeTime
                quality = min(max(data.quality, 1), 5)
                sleepMode = .manual
            }) {
                HStack {
                    Spacer()
                    Text("use_this_data".localized)
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.primary)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // データ行の表示
    private func dataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.bodyFont.bold())
                .foregroundColor(Theme.Colors.primary)
        }
    }
    
    // データ取得中表示
    private var watchDataLoadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("requesting_watch_data".localized)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.text)
                .multilineTextAlignment(.center)
            
            Text("open_watch_app".localized)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // Watch未接続表示
    private var watchNotConnectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "applewatch.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.warning)
            
            Text("watch_not_paired".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)
            
            Text("use_manual_input".localized)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.subtext)
                .multilineTextAlignment(.center)
            
            Button(action: {
                sleepMode = .manual
            }) {
                Text("switch_to_manual".localized)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.primary)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 20)
    }
    
    // 睡眠記録の保存
    private func saveSleepRecord() {
        let sleepManager = SleepManager.shared
        let _ = sleepManager.addSleepRecord(
            context: viewContext,
            startAt: sleepTime,
            endAt: wakeTime,
            quality: Int16(quality),
            memo: nil
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SleepInputView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(LocalizationManager.shared)
} 