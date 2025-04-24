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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("ようこそ")
                    .font(.largeTitle)
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

    private func requestHealthKit() {
        // HealthKit 認可リクエスト
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let readTypes: Set<HKObjectType> = [sleepType, heartRateType, respiratoryType]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isHealthAuthorized = true
                } else {
                    self.showHealthDeniedAlert = true
                }
            }
        }
    }

    private func checkWatch() {
        // WatchConnectivityManager で接続確認
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