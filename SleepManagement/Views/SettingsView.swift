import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
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
        }
    }
    
    // ユーザー情報セクション
    private var userInfoSection: some View {
        SettingsSectionCard(title: "settings.user.title".localized, icon: "person.circle") {
            VStack(spacing: 16) {
                // 年代選択
                SettingsRow(icon: "calendar", title: "settings.user.age".localized) {
                    Picker("", selection: $settings.birthYear) {
                        Text("10代").tag(2005)
                        Text("20代").tag(1995)
                        Text("30代").tag(1985)
                        Text("40代").tag(1975)
                        Text("50代").tag(1965)
                        Text("60代以上").tag(1955)
                    }
                    .pickerStyle(MenuPickerStyle())
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
                        ForEach([5, 6, 7, 8, 9, 10], id: \.self) { hour in
                            Text("\(hour)時間").tag(TimeInterval(hour * 3600))
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
                }
                
                // 説明文を追加
                if settings.autoSyncHealthKit {
                    HStack {
                        Text("settings.healthkit.description".localized)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.subtext)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.leading, 32)
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