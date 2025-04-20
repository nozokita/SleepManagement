import Foundation
import CoreData
import UserNotifications

class SleepManager: ObservableObject {
    static let shared = SleepManager()
    
    // 推奨睡眠時間（デフォルト7時間）
    var recommendedSleepHours: Double = 7.0
    
    // スライディングウィンドウの日数
    let debtWindowDays = 10
    
    // 睡眠スコアの計算
    func calculateSleepScore(startAt: Date, endAt: Date, quality: Int16) -> Double {
        let durationH = endAt.timeIntervalSince(startAt) / 3600
        let baseScore = min(durationH / recommendedSleepHours, 1.0) * 100
        let qualityFactor = Double(quality) / 5.0
        
        return baseScore * qualityFactor
    }
    
    // 日次睡眠負債の計算
    func calculateDailyDebt(sleepHours: Double) -> Double {
        return max(recommendedSleepHours - sleepHours, 0)
    }
    
    // 過去N日間の睡眠負債を計算
    func calculateTotalDebt(context: NSManagedObjectContext, days: Int = 10) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now)!
        
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startAt >= %@", startDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: true)]
        
        do {
            let records = try context.fetch(fetchRequest)
            
            var dailyRecords: [Date: [SleepRecord]] = [:]
            var totalDebt: Double = 0
            
            // 各日ごとに睡眠記録をグループ化
            for record in records {
                guard let startAt = record.startAt, let _ = record.endAt else { continue }
                
                let dateKey = calendar.startOfDay(for: startAt)
                if dailyRecords[dateKey] == nil {
                    dailyRecords[dateKey] = []
                }
                dailyRecords[dateKey]?.append(record)
            }
            
            // 日ごとの睡眠負債を計算
            for day in 0..<days {
                if let date = calendar.date(byAdding: .day, value: -day, to: calendar.startOfDay(for: now)) {
                    let dailySleepHours = dailyRecords[date]?.reduce(0.0) { sum, record in
                        guard let startAt = record.startAt, let endAt = record.endAt else { return sum }
                        return sum + (endAt.timeIntervalSince(startAt) / 3600)
                    } ?? 0.0
                    
                    let dailyDebt = calculateDailyDebt(sleepHours: dailySleepHours)
                    totalDebt += dailyDebt
                }
            }
            
            return totalDebt
            
        } catch {
            print("睡眠負債の計算に失敗しました: \(error)")
            return 0
        }
    }
    
    // 仮眠が必要かどうかの判断
    func needsNap(debt: Double) -> Bool {
        // 睡眠負債が5.25時間（推奨睡眠時間の75%）を超えたら仮眠を推奨
        return debt > (recommendedSleepHours * 0.75)
    }
    
    // ローカル通知のスケジュール
    func scheduleNapNotification() {
        let content = UNMutableNotificationContent()
        content.title = "睡眠負債が蓄積されています"
        content.body = "今から15分のパワーナップをどうぞ"
        content.sound = .default
        
        // 現在の時刻から30分後に通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知の登録に失敗しました: \(error)")
            }
        }
    }
    
    // 新しい睡眠記録を追加
    func addSleepRecord(context: NSManagedObjectContext, startAt: Date, endAt: Date, quality: Int16, memo: String? = nil) -> SleepRecord {
        let record = SleepRecord(context: context)
        record.id = UUID()
        record.startAt = startAt
        record.endAt = endAt
        record.quality = quality
        record.memo = memo
        record.createdAt = Date()
        
        // スコアと負債の計算
        let durationHours = endAt.timeIntervalSince(startAt) / 3600
        record.score = calculateSleepScore(startAt: startAt, endAt: endAt, quality: quality)
        record.debt = calculateDailyDebt(sleepHours: durationHours)
        
        // 保存
        do {
            try context.save()
            
            // 睡眠負債が一定以上なら通知をスケジュール
            let totalDebt = calculateTotalDebt(context: context)
            if needsNap(debt: totalDebt) {
                scheduleNapNotification()
            }
            
            return record
        } catch {
            print("睡眠記録の保存に失敗しました: \(error)")
            context.rollback()
            
            // エラー時は空のレコードを返す
            return SleepRecord(context: context)
        }
    }
    
    // 通知許可をリクエスト
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可が承認されました")
            } else if let error = error {
                print("通知許可エラー: \(error)")
            }
        }
    }
} 