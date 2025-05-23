import SwiftUI
import HealthKit
import UIKit

struct OnboardingView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var localizationManager: LocalizationManager
    private static let healthStore = HKHealthStore()
    @State private var isHealthAuthorized = false
    @State private var showHealthDeniedAlert = false
    @State private var hkSleepStatus: HKAuthorizationStatus = .notDetermined
    @State private var hkHeartRateStatus: HKAuthorizationStatus = .notDetermined
    @State private var isCheckingStatuses = false
    @State private var healthKitError: String? = nil
    @State private var refreshView = false // 言語変更時の再描画用
    var onComplete: (() -> Void)? = nil

    private static let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private static let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private static let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    VStack(spacing: 16) {
                        // 言語切り替えボタン
                        HStack {
                            Spacer()
                            Button(action: {
                                localizationManager.toggleLanguage()
                                print("言語を切り替えました: \(localizationManager.currentLanguage)")
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "globe")
                                        .font(.body)
                                    Text(localizationManager.currentLanguage == "ja" ? "English" : "日本語")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Text("onboarding.welcomeTitle")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        
                        Text("onboarding.welcomeMessage")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // HealthKit設定カード
                    VStack(alignment: .leading, spacing: 20) {
                        Text("onboarding.requiredSettingsTitle")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Label("onboarding.sleepDataLabel", systemImage: "moon.zzz.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(statusText(for: hkSleepStatus))
                                    .foregroundColor(statusColor(for: hkSleepStatus))
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Label("onboarding.heartRateLabel", systemImage: "heart.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(statusText(for: hkHeartRateStatus))
                                    .foregroundColor(statusColor(for: hkHeartRateStatus))
                                    .fontWeight(.bold)
                            }
                        }
                        
                        HStack {
                            Button(LocalizedStringKey("onboarding.updateStatusButton")) { 
                                updateStatuses() 
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button(isHealthAuthorized ? LocalizedStringKey("onboarding.healthKitButton.authorized") : LocalizedStringKey("onboarding.healthKitButton.request")) {
                                requestHealthKit()
                            }
                            .buttonStyle(.borderedProminent)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // 睡眠記録の説明
                    VStack(alignment: .leading, spacing: 16) {
                        Text("onboarding.usage.title")
                            .font(.headline)
                            .padding(.bottom, 4)
                            
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("onboarding.usage.healthkit.title")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("onboarding.usage.healthkit.description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("onboarding.usage.manual.title")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("onboarding.usage.manual.description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // アクションボタン
                    VStack {
                        Button(LocalizedStringKey("onboarding.nextButton")) { 
                            onComplete?() 
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        
                        Button(LocalizedStringKey("onboarding.skipButton")) { 
                            onComplete?() 
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle(LocalizedStringKey("onboarding.navigationTitle"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("onboarding.skipButton")) { onComplete?() }
                }
            }
        }
        .alert(LocalizedStringKey("onboarding.alert.healthDenied.title"), isPresented: $showHealthDeniedAlert) {
            Button(LocalizedStringKey("onboarding.alert.openSettingsButton")) {
                if let healthURL = URL(string: UIApplication.openSettingsURLString + "Privacy&path=HEALTH") {
                    openURL(healthURL)
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button(LocalizedStringKey("common.cancelButton"), role: .cancel) {}
        } message: {
            Text("onboarding.alert.healthDenied.message")
        }
        .onAppear {
            print("OnboardingView表示 - HealthKit状態を更新")
            print("OnboardingView表示 - 現在の言語: \(localizationManager.currentLanguage)")
            updateStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("アプリがアクティブになりました - HealthKit状態を更新")
            updateStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
            print("OnboardingView - 言語変更通知を受信: \(localizationManager.currentLanguage)")
            refreshView.toggle() // 強制的に再描画
        }
        .id(refreshView) // 言語変更時に強制的に再描画
    }

    private func updateStatuses() {
        healthKitError = nil
        print("HealthKit ステータス更新開始")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKitが利用できません")
            healthKitError = NSLocalizedString("onboarding.error.healthKitUnavailable", comment: "Error message when HealthKit is not available")
            return
        }
        
        hkSleepStatus = OnboardingView.healthStore.authorizationStatus(for: OnboardingView.sleepType)
        hkHeartRateStatus = OnboardingView.healthStore.authorizationStatus(for: OnboardingView.heartRateType)
        print("HealthKit Sleep状態: \(hkSleepStatus.rawValue) - \(statusText(for: hkSleepStatus))")
        print("HealthKit HeartRate状態: \(hkHeartRateStatus.rawValue) - \(statusText(for: hkHeartRateStatus))")
        
        print("HealthKit Sleep状態 Raw: \(hkSleepStatus)")
        print("HealthKit HeartRate状態 Raw: \(hkHeartRateStatus)")
        
        isHealthAuthorized = (hkSleepStatus == .sharingAuthorized && hkHeartRateStatus == .sharingAuthorized)
        print("HealthKit 許可状態: \(isHealthAuthorized)")
        
        #if targetEnvironment(simulator)
        if hkSleepStatus == .notDetermined && hkHeartRateStatus == .notDetermined {
            healthKitError = NSLocalizedString("onboarding.error.simulatorLimitation", comment: "Error message for simulator limitations")
        }
        #endif
    }

    private func statusText(for status: HKAuthorizationStatus) -> LocalizedStringKey {
        #if targetEnvironment(simulator)
            if status == .notDetermined {
                return "onboarding.status.simulatorNotDetermined"
            }
        #endif

        switch status {
        case .notDetermined: return "onboarding.status.notDetermined"
        case .sharingAuthorized: return "onboarding.status.authorized"
        case .sharingDenied: return "onboarding.status.denied"
        @unknown default: return "onboarding.status.unknown"
        }
    }

    private func statusColor(for status: HKAuthorizationStatus) -> Color {
        switch status {
        case .notDetermined: return .gray
        case .sharingAuthorized: return .green
        case .sharingDenied: return .red
        @unknown default: return .orange
        }
    }

    private func requestHealthKit() {
        healthKitError = nil
        print("HealthKit 許可リクエスト開始")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKitが利用できません")
            healthKitError = NSLocalizedString("onboarding.error.healthKitUnavailable", comment: "Error message when HealthKit is not available")
            return
        }
        
        let sleepStatus = OnboardingView.healthStore.authorizationStatus(for: OnboardingView.sleepType)
        let heartRateStatus = OnboardingView.healthStore.authorizationStatus(for: OnboardingView.heartRateType)
        print("リクエスト前の状態 - Sleep: \(sleepStatus.rawValue), HeartRate: \(heartRateStatus.rawValue)")
        
        if sleepStatus == .sharingDenied || heartRateStatus == .sharingDenied {
            print("HealthKit 拒否済み - 設定アプリへ誘導")
            self.showHealthDeniedAlert = true
            return
        }
        
        if (sleepStatus == .sharingAuthorized && heartRateStatus == .sharingAuthorized) {
            print("HealthKit 既に許可済み")
            self.isHealthAuthorized = true
            updateStatuses()
            return
        }
        
        let shareTypes: Set<HKSampleType> = [OnboardingView.sleepType]
        let readTypes: Set<HKObjectType> = [
            OnboardingView.sleepType,
            OnboardingView.heartRateType,
            OnboardingView.respiratoryType
        ]
        
        print("HealthKit 許可リクエスト実行: 読み取り:\(readTypes.count)項目, 書き込み:\(shareTypes.count)項目")
        
        DispatchQueue.main.async {
            OnboardingView.healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                print("HealthKit authorization result: success=\(success), error=\(String(describing: error))")
                DispatchQueue.main.async {
                    if success {
                        print("HealthKit 許可成功")
                        self.isHealthAuthorized = true
                        self.hkSleepStatus = OnboardingView.healthStore.authorizationStatus(for: OnboardingView.sleepType)
                        self.hkHeartRateStatus = OnboardingView.healthStore.authorizationStatus(for: OnboardingView.heartRateType)
                        print("許可後の状態 - Sleep: \(self.hkSleepStatus.rawValue), HeartRate: \(self.hkHeartRateStatus.rawValue)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("遅延後の状態更新実行")
                            self.updateStatuses()
                        }
                    } else {
                        print("HealthKit 許可失敗: \(String(describing: error))")
                        if let error = error {
                            self.healthKitError = String(format: NSLocalizedString("common.error.format", comment: "Generic error format"), error.localizedDescription)
                        }
                        self.showHealthDeniedAlert = true
                    }
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(LocalizationManager.shared) // Add LocalizationManager for preview
            .previewLayout(.sizeThatFits)
    }
} 