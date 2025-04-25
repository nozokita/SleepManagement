import Foundation

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
        return "\(hours)時間\(minutes)分"
    }
    
    // 日付を「MM/dd」形式でフォーマット
    var dayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    // 曜日を取得
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
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