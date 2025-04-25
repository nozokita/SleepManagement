import Foundation
import SwiftUI

/// 睡眠チャートデータを表す構造体
struct SleepChartData: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var duration: TimeInterval  // 秒単位の睡眠時間
    var score: Double  // 睡眠スコア
    
    // 睡眠時間をフォーマットした文字列
    var durationFormatted: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        // 現在の言語設定を確認
        if SleepChartData.isJapaneseLocale() {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // 日付を「MM/dd」形式でフォーマット
    var dayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    // 曜日を取得（ロケールに応じて表示）
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = SleepChartData.isJapaneseLocale() ? Locale(identifier: "ja_JP") : Locale(identifier: "en_US")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    // デュレーションをフォーマット（引数でロケールを指定可能）
    func formattedDuration(isJapanese: Bool) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if isJapanese {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // 曜日をフォーマット（引数でロケールを指定可能）
    func formattedWeekday(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    // 静的なヘルパーメソッド：現在のロケールが日本語かどうかを判定
    static func isJapaneseLocale() -> Bool {
        // UserDefaultsから言語設定を取得
        let appLanguage = UserDefaults.standard.string(forKey: "app_language")
        if let language = appLanguage {
            return language == "ja"
        }
        
        // アプリの言語設定がない場合はシステム言語を使用
        return Locale.current.identifier.starts(with: "ja")
    }
}

// 睡眠チャートデータの配列に関する拡張機能
extension Array where Element == SleepChartData {
    // 平均睡眠時間を計算
    var averageDuration: TimeInterval {
        guard !isEmpty else { return 0 }
        return self.reduce(0) { $0 + $1.duration } / Double(count)
    }
    
    // 平均睡眠スコアを計算
    var averageScore: Double {
        guard !isEmpty else { return 0 }
        return self.reduce(0) { $0 + $1.score } / Double(count)
    }
    
    // 睡眠時間が最大の日を取得
    var maxDurationDay: SleepChartData? {
        return self.max(by: { $0.duration < $1.duration })
    }
    
    // 睡眠時間が最小の日を取得
    var minDurationDay: SleepChartData? {
        return self.min(by: { $0.duration < $1.duration })
    }
} 