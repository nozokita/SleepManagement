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
                
                HStack {
                    Text("睡眠データ:")
                    Spacer()
                    Text(statusText(for: hkSleepStatus))
                        .foregroundColor(statusColor(for: hkSleepStatus))
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                
                HStack {
                    Text("心拍数データ:")
                    Spacer()
                    Text(statusText(for: hkHeartRateStatus))
                        .foregroundColor(statusColor(for: hkHeartRateStatus))
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                
                Button("ステータス更新") {
                    isCheckingStatuses = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        updateStatuses()
                        isCheckingStatuses = false
                    }
                }
                .font(.footnote)
                .padding(.vertical, 8)
                .foregroundColor(.blue)
                
                if hkSleepStatus == .sharingDenied || hkHeartRateStatus == .sharingDenied {
                    Button("設定アプリでHealthKitを許可する") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
                }
                
                Button(action: requestHealthKit) {
                    Text(isHealthAuthorized ? "HealthKit 許可済み" : "HealthKit を許可する")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isHealthAuthorized ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(hkSleepStatus == .sharingDenied || hkHeartRateStatus == .sharingDenied)
                .opacity(hkSleepStatus == .sharingDenied || hkHeartRateStatus == .sharingDenied ? 0.6 : 1.0)
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
            Text("睡眠データの取得には HealthKit のアクセスが必要です。\n\n設定アプリを開き、「プライバシーとセキュリティ」→「健康」で、このアプリに対して「睡眠」と「心拍数」の項目を「許可」に設定してください。")
        }
        .alert("Apple Watch 接続エラー", isPresented: $showWatchError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Watchとの接続に問題があります。iPhoneとWatchが正しくペアリングされていることを確認してください。シミュレータ環境ではWatchConnectivityは正常に動作しません。")
        }
        .onAppear {
            updateStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("アプリがアクティブになりました - HealthKit状態を更新")
            updateStatuses()
        }
    }

    private func updateStatuses() {
        print("HealthKit ステータス更新開始")
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        hkSleepStatus = healthStore.authorizationStatus(for: sleepType)
        hkHeartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        print("HealthKit Sleep状態: \(hkSleepStatus.rawValue) - \(statusText(for: hkSleepStatus))")
        print("HealthKit HeartRate状態: \(hkHeartRateStatus.rawValue) - \(statusText(for: hkHeartRateStatus))")
        
        isHealthAuthorized = (hkSleepStatus == .sharingAuthorized && hkHeartRateStatus == .sharingAuthorized)
        print("HealthKit 許可状態: \(isHealthAuthorized)")
        
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
        print("HealthKit 許可リクエスト開始")
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        
        let sleepStatus = healthStore.authorizationStatus(for: sleepType)
        let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)
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
        
        let shareTypes: Set<HKSampleType> = [sleepType]
        let readTypes: Set<HKObjectType> = [sleepType, heartRateType, respiratoryType]
        
        print("HealthKit 許可リクエスト実行: 読み取り:\(readTypes.count)項目, 書き込み:\(shareTypes.count)項目")
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            print("HealthKit authorization result: success=\(success), error=\(String(describing: error))")
            DispatchQueue.main.async {
                if success {
                    print("HealthKit 許可成功")
                    self.isHealthAuthorized = true
                    self.hkSleepStatus = self.healthStore.authorizationStatus(for: sleepType)
                    self.hkHeartRateStatus = self.healthStore.authorizationStatus(for: heartRateType)
                    print("許可後の状態 - Sleep: \(self.hkSleepStatus.rawValue), HeartRate: \(self.hkHeartRateStatus.rawValue)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("遅延後の状態更新実行")
                        self.updateStatuses()
                    }
                } else {
                    print("HealthKit 許可失敗: \(String(describing: error))")
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