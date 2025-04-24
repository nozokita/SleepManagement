import SwiftUI
import HealthKit
import WatchConnectivity
import UIKit

struct OnboardingView: View {
    @Environment(\.openURL) private var openURL
    private static let healthStore = HKHealthStore()
    @State private var isHealthAuthorized = false
    @State private var isWatchConnected = false
    @State private var showHealthDeniedAlert = false
    @State private var hkSleepStatus: HKAuthorizationStatus = .notDetermined
    @State private var hkHeartRateStatus: HKAuthorizationStatus = .notDetermined
    @State private var isCheckingStatuses = false
    @State private var watchErrorMessage: String? = nil
    @State private var showWatchError = false
    @State private var healthKitError: String? = nil
    var onComplete: (() -> Void)? = nil

    private static let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private static let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private static let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    Text("ようこそ！")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .padding(.top)
                    Text("設定はあとで変更できます。まずはアプリを始めましょう！")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // 必須設定カード
                    VStack(alignment: .leading, spacing: 16) {
                        Text("必須設定")
                            .font(.headline)
                        HStack {
                            Label("睡眠データ", systemImage: "moon.zzz.fill")
                            Spacer()
                            Text(statusText(for: hkSleepStatus))
                                .foregroundColor(statusColor(for: hkSleepStatus))
                                .fontWeight(.bold)
                        }
                        HStack {
                            Label("心拍数", systemImage: "heart.fill")
                            Spacer()
                            Text(statusText(for: hkHeartRateStatus))
                                .foregroundColor(statusColor(for: hkHeartRateStatus))
                                .fontWeight(.bold)
                        }
                        HStack(spacing: 12) {
                            Button("ステータス更新") { updateStatuses() }
                                .font(.caption)
                            Button(isHealthAuthorized ? "許可済み" : "HealthKit を許可する") {
                                requestHealthKit()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))

                    // オプション設定カード
                    VStack(alignment: .leading, spacing: 16) {
                        Text("オプション設定")
                            .font(.headline)
                        HStack {
                            Label("Apple Watch 接続", systemImage: "applewatch")
                            Spacer()
                            Text(isWatchConnected ? "接続済み" : "未接続")
                                .foregroundColor(isWatchConnected ? .green : .primary)
                        }
                        Button(isWatchConnected ? "Watch 接続済み" : "Watch を検出する") {
                            checkWatch()
                        }
                        .buttonStyle(.bordered)
                        .tint(isWatchConnected ? .green : .blue)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))

                    // アクションボタン
                    HStack(spacing: 16) {
                        Button("スキップ") { onComplete?() }
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("次へ進む") { onComplete?() }
                            .disabled(false)
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("オンボーディング")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("スキップ") { onComplete?() }
                }
            }
        }
        .alert("HealthKit アクセスが拒否されました", isPresented: $showHealthDeniedAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("睡眠データの取得には HealthKit のアクセスが必要です。\n\n設定アプリを開き、「プライバシーとセキュリティ」→「健康」で、このアプリに対して「睡眠」と「心拍数」の項目を「許可」に設定してください。")
        }
        .alert("Apple Watch 接続エラー", isPresented: $showWatchError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Watchとの接続に問題があります。iPhoneとWatchが正しくペアリングされていることを確認してください。シミュレータ環境ではWatchConnectivityは正常に動作しません。")
        }
        .onAppear {
            print("OnboardingView表示 - HealthKit状態を更新")
            updateStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("アプリがアクティブになりました - HealthKit状態を更新")
            updateStatuses()
        }
    }

    private func updateStatuses() {
        healthKitError = nil
        print("HealthKit ステータス更新開始")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKitが利用できません")
            healthKitError = "このデバイスではHealthKitが利用できません"
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
            healthKitError = "シミュレータ環境では完全な動作保証ができません"
        }
        #endif
        
        let manager = WatchConnectivityManager.shared
        manager.checkWatchAvailability()
        isWatchConnected = manager.isWatchAvailable
    }

    private func statusText(for status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "未確認"
        case .sharingAuthorized: return "許可済み"
        case .sharingDenied: return "拒否済み"
        #if targetEnvironment(simulator)
            if status == .notDetermined {
                return "シミュレータ環境・未確認"
            }
        #endif
        @unknown default: return "不明"
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
            healthKitError = "このデバイスではHealthKitが利用できません"
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
                            self.healthKitError = "エラー: \(error.localizedDescription)"
                        }
                        self.showHealthDeniedAlert = true
                    }
                }
            }
        }
    }

    private func checkWatch() {
        let manager = WatchConnectivityManager.shared
        manager.checkWatchAvailability()
        DispatchQueue.main.async {
            self.isWatchConnected = manager.isWatchAvailable
           
            if !manager.isWatchAvailable {
                if !WCSession.isSupported() {
                    self.watchErrorMessage = "このデバイスはWatchConnectivityをサポートしていません。"
                } else if !WCSession.default.isPaired {
                    self.watchErrorMessage = "Apple Watchがペアリングされていません。"
                    self.showWatchError = true
                } else if !WCSession.default.isWatchAppInstalled {
                    self.watchErrorMessage = "Watchアプリがインストールされていません。"
                } else {
                    self.watchErrorMessage = "不明なエラーが発生しました。"
                }
            } else {
                self.watchErrorMessage = nil
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .previewLayout(.sizeThatFits)
    }
} 