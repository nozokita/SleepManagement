import Foundation
import WatchConnectivity

// Apple Watchから受信する健康データの構造体
struct WatchHealthData {
    let sleepTime: Date
    let wakeTime: Date
    let deepSleepDuration: TimeInterval
    let avgHeartRate: Double
    let quality: Double
    
    // 総睡眠時間を計算
    var totalDuration: TimeInterval {
        return wakeTime.timeIntervalSince(sleepTime)
    }
    
    // フォーマット済みの睡眠時間
    var durationFormatted: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
    
    // フォーマット済みの深い睡眠時間
    var deepSleepFormatted: String {
        let hours = Int(deepSleepDuration / 3600)
        let minutes = Int((deepSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
}

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    private let session = WCSession.default
    @Published var isWatchAvailable = false
    @Published var isCheckingAvailability = true
    @Published var lastReceivedHealthData: WatchHealthData?
    
    private override init() {
        super.init()
        
        // WCSessionが利用可能かチェック
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        
        // 初期チェック後、チェック状態を解除
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isCheckingAvailability = false
            // Apple Watchの接続状態をチェック
            self.checkWatchAvailability()
        }
    }
    
    func checkWatchAvailability() {
        // WatchConnectivityが使えるかどうか
        guard WCSession.isSupported() else {
            self.isWatchAvailable = false
            return
        }
        
        // Watchがペアリングされているか
        guard session.isPaired else {
            self.isWatchAvailable = false
            return
        }
        
        // Watchにアプリがインストールされているか
        guard session.isWatchAppInstalled else {
            self.isWatchAvailable = false
            return
        }
        
        // すべての条件を満たしている場合
        self.isWatchAvailable = true
    }
    
    // メッセージ送信（将来的な実装用）
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        if session.isReachable {
            session.sendMessage(message, replyHandler: replyHandler) { error in
                print("Watch通信エラー: \(error.localizedDescription)")
            }
        }
    }
    
    // 睡眠データのリクエスト（デモ用にシミュレーションデータを作成）
    func requestSleepData() {
        // 実際のWatchアプリ連携では、Watchにメッセージを送信して睡眠データを要求
        // 現時点ではデモデータを生成
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // デモ用の睡眠データを作成
            let now = Date()
            let sleepTime = Calendar.current.date(byAdding: .hour, value: -8, to: now)!
            let deepSleepDuration: TimeInterval = 2 * 3600 // 2時間
            
            let demoData = WatchHealthData(
                sleepTime: sleepTime,
                wakeTime: now,
                deepSleepDuration: deepSleepDuration,
                avgHeartRate: 58.0,
                quality: 4.0
            )
            
            self.lastReceivedHealthData = demoData
        }
    }
}

// WatchConnectivityのデリゲート
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            self.isWatchAvailable = false
        } else {
            checkWatchAvailability()
        }
    }
    
    // iOS必須メソッド
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // セッションを再アクティベート
        session.activate()
    }
    
    // メッセージ受信（将来的な実装用）
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Watchからのメッセージ処理（将来実装）
            print("Received message from Watch: \(message)")
        }
    }
} 