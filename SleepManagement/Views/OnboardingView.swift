import SwiftUI
import HealthKit
import WatchConnectivity
import UIKit

struct OnboardingView: View {
    @Environment(\.openURL) private var openURL
    private let healthStore = HKHealthStore()
    @State private var isHealthAuthorized = false
    @State private var isWatchConnected = false
    @State private var showHealthDeniedAlert = false
    @State private var hkSleepStatus: HKAuthorizationStatus = .notDetermined
    @State private var hkHeartRateStatus: HKAuthorizationStatus = .notDetermined
    @State private var isCheckingStatuses = false
    @State private var watchErrorMessage: String? = nil
    @State private var showWatchError = false
    var onComplete: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            if isCheckingStatuses {
                Text("ステータスを取得中...")
            }
            Text("ヘルスケア接続設定")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("アプリの機能を最大限に活用するため、HealthKitへのアクセスを許可してください。また、Apple Watchをお持ちの場合は接続設定も行えます。")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.secondary)
            
            Divider()
            
            Group {
                Text("必須設定")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text("HealthKit SleepAnalysis: \(statusText(for: hkSleepStatus))")
                Text("HealthKit HeartRate: \(statusText(for: hkHeartRateStatus))")
                
                Button("ステータス更新") {
                    isCheckingStatuses = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        updateStatuses()
                        isCheckingStatuses = false
                    }
                }
                
                Button(action: requestHealthKit) {
                    Text(isHealthAuthorized ? "HealthKit 許可済み" : "HealthKit を許可する")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isHealthAuthorized ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            Group {
                Text("オプション設定")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text("Apple Watch 接続: \(isCheckingStatuses ? "…" : (isWatchConnected ? "接続済み" : "未接続"))")
                
                if let errorMsg = watchErrorMessage {
                    Text(errorMsg)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: checkWatch) {
                    Text(isWatchConnected ? "Watch が接続されています" : "Watch を検出する")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isWatchConnected ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if isHealthAuthorized {
                Button(action: {
                    if let onComplete = onComplete {
                        onComplete()
                    }
                }) {
                    Text("次へ進む")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top)
            }
        }
        .padding()
        .navigationTitle("オンボーディング")
        .alert("HealthKit アクセスが拒否されました", isPresented: $showHealthDeniedAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("睡眠データの取得には HealthKit のアクセスが必要です。設定アプリで許可してください。")
        }
        .alert("Apple Watch 接続エラー", isPresented: $showWatchError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Watchとの接続に問題があります。iPhoneとWatchが正しくペアリングされていることを確認してください。シミュレータ環境ではWatchConnectivityは正常に動作しません。")
        }
    }

    private func updateStatuses() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        hkSleepStatus = healthStore.authorizationStatus(for: sleepType)
        hkHeartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        let manager = WatchConnectivityManager.shared
        manager.checkWatchAvailability()
        isWatchConnected = manager.isWatchAvailable
    }

    private func statusText(for status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "未確認"
        case .sharingAuthorized: return "許可済み"
        case .sharingDenied: return "拒否済み"
        @unknown default: return "不明"
        }
    }

    private func requestHealthKit() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let readTypes: Set<HKObjectType> = [sleepType, heartRateType, respiratoryType]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isHealthAuthorized = true
                    self.hkSleepStatus = self.healthStore.authorizationStatus(for: sleepType)
                    self.hkHeartRateStatus = self.healthStore.authorizationStatus(for: heartRateType)
                } else {
                    self.showHealthDeniedAlert = true
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