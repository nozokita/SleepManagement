import Foundation
import CoreData

extension SleepRecord {
    // fetchRequestが重複しているので、カスタム名に変更
    static func createFetchRequest() -> NSFetchRequest<SleepRecord> {
        return NSFetchRequest<SleepRecord>(entityName: "SleepRecord")
    }
    
    // 全ての睡眠記録を取得（新しい順）
    static func allRecordsFetchRequest() -> NSFetchRequest<SleepRecord> {
        let request: NSFetchRequest<SleepRecord> = createFetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: false)
        ]
        return request
    }
    
    // 期間を指定して睡眠記録を取得
    static func recordsInRange(from: Date, to: Date) -> NSFetchRequest<SleepRecord> {
        let request: NSFetchRequest<SleepRecord> = createFetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@ AND endAt <= %@", from as NSDate, to as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: false)
        ]
        return request
    }
    
    // 睡眠時間（時間単位）
    var durationInHours: Double {
        guard let startAt = startAt, let endAt = endAt else { return 0 }
        return endAt.timeIntervalSince(startAt) / 3600
    }
    
    // 睡眠時間（文字列表示用）
    var durationText: String {
        let hours = Int(durationInHours)
        let minutes = Int((durationInHours - Double(hours)) * 60)
        return "\(hours)時間\(minutes)分"
    }
    
    // 睡眠の日付（表示用）
    var sleepDateText: String {
        guard let startAt = startAt else { return "不明な日付" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startAt)
    }
    
    // 睡眠の開始時刻（表示用）
    var startTimeText: String {
        guard let startAt = startAt else { return "不明" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startAt)
    }
    
    // 睡眠の終了時刻（表示用）
    var endTimeText: String {
        guard let endAt = endAt else { return "不明" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: endAt)
    }
} 