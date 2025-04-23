import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    private let session = WCSession.default
    @Published var isWatchAvailable = false
    @Published var isCheckingAvailability = true
    
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