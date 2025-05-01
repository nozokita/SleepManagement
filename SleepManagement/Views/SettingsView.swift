import SwiftUI
import CoreData
import HealthKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var settings = SettingsManager.shared
    @State private var navigateHome = false
    @State private var navigateToHomeFromOnboarding = false
    @State private var showResetConfirmation = false
    var onComplete: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 言語切り替えカード
                        SettingsSectionCard(title: "settings.language.title".localized, icon: "globe") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("settings.language.current".localized)
                                        .font(Theme.Typography.bodyFont)
                                        .foregroundColor(Theme.Colors.text)
                                    Spacer()
                                    
                                    // 言語選択ボタン
                                    Button(action: {
                                        localizationManager.toggleLanguage()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "globe")
                                                .font(.body)
                                            Text(localizationManager.currentLanguage == "ja" ? "English" : "日本語")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Theme.Colors.primary)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        
                        // ユーザー情報セクション
                        userInfoSection
                        
                        // 睡眠設定セクション
                        sleepSettingsSection
                        
                        // 通知設定セクション
                        notificationSettingsSection
                        
                        // アプリ表示設定セクション
                        appDisplaySettingsSection
                        
                        // ヘルスケア連携セクション
                        healthKitIntegrationSection
                        
                        // アプリ情報セクション
                        appInfoSection
                        
                        // リセットとデータ管理セクション
                        dataManagementSection
                        
                        // 保存ボタン
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if onComplete == nil {
                        // オンボーディングではない場合は閉じるボタンを表示
                        Button("settings.close".localized) {
                            dismiss()
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateHome) {
                HomeView()
            }
            .navigationDestination(isPresented: $navigateToHomeFromOnboarding) {
                HomeView()
                    .navigationBarHidden(true)
            }
            .alert("settings.data.reset.title".localized, isPresented: $showResetConfirmation) {
                Button("settings.data.reset.cancel".localized, role: .cancel) {}
                Button("settings.data.reset.confirm.button".localized, role: .destructive) {
                    resetSettings()
                }
            } message: {
                Text("settings.data.reset.confirm".localized)
            }
            // 初期表示時に自動同期設定が有効なら権限確認・同期を実行
            .onAppear {
                if settings.autoSyncHealthKit {
                    let store = HKHealthStore()
                    let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
                    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
                    let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
                    let readTypes: Set<HKObjectType> = [sleepType, heartRateType, respiratoryType]
                    let shareTypes: Set<HKSampleType> = [sleepType, heartRateType, respiratoryType]
                    // ヘルスケア権限リクエスト
                    store.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                // 同期実行
                                SleepManager.shared.syncSleepDataFromHealthKit(context: viewContext) { error in
                                    if let error = error {
                                        print("HealthKit sync error onAppear: \(error)")
                                    }
                                }
                            } else if let error = error {
                                print("HealthKit auth error onAppear: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ユーザー情報セクション
    private var userInfoSection: some View {
        // 年齢からガイドラインを計算
        let age = Calendar.current.component(.year, from: Date()) - settings.birthYear
        let guideline = SleepManager.shared.guidelineHours(age: age)
        return SettingsSectionCard(title: "settings.user.title".localized, icon: "person.circle") {
            VStack(spacing: 16) {
                // 年代選択
                SettingsRow(icon: "calendar", title: "settings.user.age".localized) {
                    Picker("", selection: $settings.birthYear) {
                        Text(localizationManager.currentLanguage == "ja" ? "10代" : "10s").tag(2005)
                        Text(localizationManager.currentLanguage == "ja" ? "20代" : "20s").tag(1995)
                        Text(localizationManager.currentLanguage == "ja" ? "30代" : "30s").tag(1985)
                        Text(localizationManager.currentLanguage == "ja" ? "40代" : "40s").tag(1975)
                        Text(localizationManager.currentLanguage == "ja" ? "50代" : "50s").tag(1965)
                        Text(localizationManager.currentLanguage == "ja" ? "60代以上" : "60s+").tag(1955)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                // 年齢別推奨睡眠時間の表示
                HStack {
                    Text("settings.user.guideline".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                    Spacer()
                    Text(String(format: "%.1f", guideline) + " " + "hours".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                }
            }
        }
    }
    
    // 睡眠設定セクション
    private var sleepSettingsSection: some View {
        SettingsSectionCard(title: "settings.sleep.title".localized, icon: "bed.double.circle") {
            VStack(spacing: 16) {
                // 理想睡眠時間
                SettingsRow(icon: "moon.stars", title: "settings.sleep.ideal".localized) {
                    Picker("", selection: $settings.idealSleepDuration) {
                        // 30分単位で 5.0h から 10.0h まで
                        ForEach(Array(stride(from: 5.0, through: 10.0, by: 0.5)), id: \.self) { value in
                            // 整数時間と30分フラグ
                            let hour = Int(value)
                            let isHalf = value.truncatingRemainder(dividingBy: 1.0) > 0
                            let label = localizationManager.currentLanguage == "ja"
                                ? "\(hour)" + "hours".localized + (isHalf ? "30" + "minutes".localized : "")
                                : "\(hour) " + "hours".localized + (isHalf ? " 30 " + "minutes".localized : "")
                            Text(label)
                                .tag(TimeInterval(value * 3600))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }
    
    // 通知設定セクション
    private var notificationSettingsSection: some View {
        SettingsSectionCard(title: "settings.notification.title".localized, icon: "bell.circle") {
            VStack(spacing: 16) {
                // 就寝リマインダー
                SettingsRow(icon: "bed.double", title: "settings.notification.bedtime".localized) {
                    Toggle("", isOn: $settings.enableSleepReminder)
                        .labelsHidden()
                }
                
                if settings.enableSleepReminder {
                    SettingsRow(icon: "clock", title: "settings.notification.bedtime.time".localized) {
                        DatePicker("", selection: $settings.sleepReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                
                // 朝のサマリー
                SettingsRow(icon: "sun.max", title: "settings.notification.morning".localized) {
                    Toggle("", isOn: $settings.enableMorningSummary)
                        .labelsHidden()
                }
                
                if settings.enableMorningSummary {
                    SettingsRow(icon: "clock", title: "settings.notification.morning.time".localized) {
                        DatePicker("", selection: $settings.morningSummaryTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }
        }
    }
    
    // アプリ表示設定
    private var appDisplaySettingsSection: some View {
        SettingsSectionCard(title: "settings.display.title".localized, icon: "paintbrush.circle") {
            VStack(spacing: 16) {
                // テーマの設定
                SettingsRow(icon: "circle.lefthalf.filled", title: "settings.display.system".localized) {
                    Toggle("", isOn: $settings.useSystemTheme)
                        .labelsHidden()
                }
                
                if !settings.useSystemTheme {
                    SettingsRow(icon: "moon.circle", title: "settings.display.dark".localized) {
                        Toggle("", isOn: $settings.darkModeEnabled)
                            .labelsHidden()
                    }
                }
                
                // 睡眠負債の表示
                SettingsRow(icon: "chart.bar", title: "settings.display.debt".localized) {
                    Toggle("", isOn: $settings.showSleepDebt)
                        .labelsHidden()
                }
                
                // 睡眠スコアの表示
                SettingsRow(icon: "chart.bar.fill", title: "settings.display.score".localized) {
                    Toggle("", isOn: $settings.showSleepScore)
                        .labelsHidden()
                }
            }
        }
    }
    
    // ヘルスケア連携
    private var healthKitIntegrationSection: some View {
        SettingsSectionCard(title: "settings.healthkit.title".localized, icon: "heart.circle") {
            VStack(spacing: 16) {
                // HealthKit自動同期
                SettingsRow(icon: "arrow.clockwise", title: "settings.healthkit.sync".localized) {
                    Toggle("", isOn: $settings.autoSyncHealthKit)
                        .labelsHidden()
                        .onChange(of: settings.autoSyncHealthKit) { oldValue, newValue in
                            if newValue {
                                // 設定を保存
                                settings.save()
                                // HealthKit権限をリクエストしてから同期を開始
                                let store = HKHealthStore()
                                let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
                                let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
                                let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
                                let readTypes: Set<HKObjectType> = [sleepType, heartRateType, respiratoryType]
                                let shareTypes: Set<HKSampleType> = [sleepType, heartRateType, respiratoryType]
                                store.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("HealthKit authorization error: \(error)")
                                        } else if success {
                                            // 権限取得後に同期開始
                                            SleepManager.shared.syncSleepDataFromHealthKit(context: viewContext) { error in
                                                if let error = error {
                                                    print("HealthKit sync error: \(error)")
                                                } else {
                                                    NotificationCenter.default.post(name: Notification.Name("HealthKitDataSynced"), object: nil)
                                                }
                                            }
                                        } else {
                                            print("HealthKit authorization denied")
                                        }
                                    }
                                }
                            }
                        }
                }
                
                // 短い睡眠を仮眠扱いにする
                SettingsRow(icon: "bed.double", title: "settings.healthkit.treatShortSleepAsNap".localized) {
                    Toggle("", isOn: $settings.treatShortSleepAsNap)
                        .labelsHidden()
                }
                
                // 閾値設定
                if settings.treatShortSleepAsNap {
                    SettingsRow(icon: "timer", title: "settings.healthkit.shortSleepThreshold".localized) {
                        Picker("", selection: $settings.shortSleepThreshold) {
                            ForEach([30, 60, 90, 120], id: \.self) { minutes in
                                Text(localizationManager.currentLanguage == "ja" ? "\(minutes)分" : "\(minutes) min")
                                    .tag(TimeInterval(minutes * 60))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                }
                
                // 睡眠セッションの区切り時間
                SettingsRow(icon: "clock", title: "settings.healthkit.sleepGapThreshold".localized) {
                    Picker("", selection: $settings.sleepGapThreshold) {
                        ForEach([15, 30, 45, 60], id: \.self) { minutes in
                            Text(localizationManager.currentLanguage == "ja" ? "\(minutes)分" : "\(minutes) min")
                                .tag(TimeInterval(minutes * 60))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                }
            }
        }
    }
    
    // アプリ情報
    private var appInfoSection: some View {
        SettingsSectionCard(title: "settings.info.title".localized, icon: "info.circle") {
            VStack(spacing: 16) {
                // アプリバージョン
                SettingsRow(icon: "tag", title: "settings.info.version".localized) {
                    Text("\(settings.appVersion) (\(settings.buildNumber))")
                        .foregroundColor(Theme.Colors.subtext)
                }
            }
        }
    }
    
    // リセットとデータ管理
    private var dataManagementSection: some View {
        SettingsSectionCard(title: "settings.data.title".localized, icon: "tray.circle") {
            VStack(spacing: 16) {
                // 設定リセット
                Button(action: {
                    showResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(Theme.Colors.danger)
                        Text("settings.data.reset".localized)
                            .foregroundColor(Theme.Colors.danger)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // 保存ボタン
    private var saveButton: some View {
        Button(action: {
            print("設定を保存しました")
            settings.save()
            
            if let onComplete = onComplete {
                // オンボーディングからの場合はHomeViewに遷移
                print("オンボーディングからの遷移を開始")
                // まず遷移フラグをセット
                navigateToHomeFromOnboarding = true
                
                // 少し遅延させてからonCompleteを呼び出す
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                    print("onComplete実行完了")
                }
            } else {
                // 通常の設定画面の場合は画面を閉じる
                dismiss()
            }
        }) {
            Text(onComplete != nil ? "settings.save.home".localized : "settings.save".localized)
                .font(Theme.Typography.bodyFont.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.primary)
                .cornerRadius(12)
                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 10)
    }
    
    // 設定をリセット
    private func resetSettings() {
        // 設定をデフォルト値にリセット
        settings.birthYear = 1985 // 30代相当
        settings.idealSleepDuration = 8 * 3600
        settings.enableSleepReminder = false
        settings.enableMorningSummary = false
        settings.useSystemTheme = true
        settings.darkModeEnabled = false
        settings.showSleepDebt = true
        settings.showSleepScore = true
        settings.autoSyncHealthKit = false
        settings.treatShortSleepAsNap = false
        settings.shortSleepThreshold = 30 * 60
        
        settings.save()
    }
}

// 設定セクションカード
struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // セクションヘッダー
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 22))
                Text(title)
                    .font(Theme.Typography.subheadingFont)
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(.bottom, 5)
            
            // セクションコンテンツ
            content
                .padding(.leading, 8)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 設定行
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.text)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            content
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(LocalizationManager.shared)
            .previewLayout(.sizeThatFits)
    }
} 