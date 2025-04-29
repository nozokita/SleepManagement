import Foundation
import CoreData
import SwiftUI

// 睡眠タイプの列挙型
enum SleepRecordType: Int16, CaseIterable {
    case normalSleep = 0
    case nap = 1
    
    var displayName: String {
        switch self {
        case .normalSleep:
            return "normal_sleep".localized
        case .nap:
            return "nap".localized
        }
    }
    
    var iconName: String {
        switch self {
        case .normalSleep:
            return "moon.stars"
        case .nap:
            return "cup.and.saucer"
        }
    }
}

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
    
    // 特定の睡眠タイプの記録を取得
    static func recordsWithType(_ type: SleepRecordType) -> NSFetchRequest<SleepRecord> {
        let request: NSFetchRequest<SleepRecord> = createFetchRequest()
        request.predicate = NSPredicate(format: "sleepType == %d", type.rawValue)
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
        if LocalizationManager.shared.currentLanguage == "ja" {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // 睡眠の日付（表示用）
    var sleepDateText: String {
        guard let startAt = startAt else {
            return LocalizationManager.shared.currentLanguage == "ja" ? "不明な日付" : "Unknown Date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "ja" ? "ja_JP" : "en_US")
        return formatter.string(from: startAt)
    }
    
    // 睡眠の開始時刻（表示用）
    var startTimeText: String {
        guard let startAt = startAt else {
            return LocalizationManager.shared.currentLanguage == "ja" ? "不明" : "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "ja" ? "ja_JP" : "en_US")
        return formatter.string(from: startAt)
    }
    
    // 睡眠の終了時刻（表示用）
    var endTimeText: String {
        guard let endAt = endAt else {
            return LocalizationManager.shared.currentLanguage == "ja" ? "不明" : "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage == "ja" ? "ja_JP" : "en_US")
        return formatter.string(from: endAt)
    }
    
    // 睡眠タイプ（表示用）
    var sleepTypeText: String {
        let type = SleepRecordType(rawValue: sleepType) ?? .normalSleep
        return type.displayName
    }
    
    // 睡眠タイプのアイコン名
    var sleepTypeIconName: String {
        let type = SleepRecordType(rawValue: sleepType) ?? .normalSleep
        return type.iconName
    }
    
    // MARK: - SleepEntry 互換プロパティ
    /// 睡眠エントリの日付
    var date: Date? { startAt }
    /// 就寝時刻
    var bedTime: Date? { startAt }
    /// 起床時刻
    var wakeTime: Date? { endAt }
    /// 睡眠時間（秒）
    var duration: Double? {
        guard let start = startAt, let end = endAt else { return nil }
        return end.timeIntervalSince(start)
    }
    /// 主観的な睡眠の質
    var sleepQuality: Int16? { quality }
    /// 入眠のしやすさ（未実装）
    var fallAsleepEase: Int16? { nil }
    /// 睡眠の連続性（未実装）
    var sleepContinuity: Int16? { nil }
    /// 目覚め時の気分（未実装）
    var morningFeeling: Int16? { nil }
    
    /// 睡眠負債の表示用テキスト
    var debtText: String {
        let hours = Int(debt)
        let minutes = Int((debt - Double(hours)) * 60)
        if LocalizationManager.shared.currentLanguage == "ja" {
            return "\(hours)時間\(minutes)分"
        } else {
            return String(format: "%.1fh", debt)
        }
    }
} 