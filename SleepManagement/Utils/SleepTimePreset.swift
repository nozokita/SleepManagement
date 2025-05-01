import Foundation

/// 手動入力のクイックプリセットを表す構造体
struct SleepTimePreset: Identifiable, Codable {
    let id: UUID
    /// ローカライズキー
    let nameKey: String
    /// 就寝時刻の時(hour)
    let hour: Int
    /// 就寝時刻の分(minute)
    let minute: Int
    /// 睡眠継続時間(時間単位)
    let durationHours: Double

    init(id: UUID = UUID(), nameKey: String, hour: Int, minute: Int, durationHours: Double) {
        self.id = id
        self.nameKey = nameKey
        self.hour = hour
        self.minute = minute
        self.durationHours = durationHours
    }

    /// 表示用の名称を返す
    var displayName: String {
        nameKey.localized
    }

    /// プリセットの就寝時刻を返す
    func startDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        if let date = calendar.date(from: components) {
            // 就寝時刻が未来の場合は前日に設定
            if date > Date() {
                return calendar.date(byAdding: .day, value: -1, to: date)! 
            }
            return date
        }
        return Date()
    }

    /// プリセットの起床時刻を返す
    func endDate() -> Date {
        let start = startDate()
        let minutesToAdd = Int(durationHours * 60)
        return Calendar.current.date(byAdding: .minute, value: minutesToAdd, to: start) ?? start
    }
} 