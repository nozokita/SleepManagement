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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isCheckingStatuses {
                    Text("ステータスを取得中...")
                }
                Text("HealthKit SleepAnalysis: \(statusText(for: hkSleepStatus))")
                Text("HealthKit HeartRate: \(statusText(for: hkHeartRateStatus))")
                Text("Apple Watch 接続: \(isCheckingStatuses ? "…" : (isWatchConnected ? "接続済み" : "未接続"))")
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
                Button(action: checkWatch) {
                    Text(isWatchConnected ? "Watch が接続されています" : "Watch を検出する")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isWatchConnected ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                if isHealthAuthorized && isWatchConnected {
                    NavigationLink(destination: SettingsView()) {
                        Text("理想睡眠時間を設定する")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("オンボーディング")
        }
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
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 