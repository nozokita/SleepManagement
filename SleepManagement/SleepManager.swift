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
            
            // 記録が一件もない場合は負債0を返す
            if records.isEmpty {
                return 0
            }
            
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
            
            // 日ごとの睡眠負債を計算（記録がある日のみ）
            for day in 0..<days {
                if let date = calendar.date(byAdding: .day, value: -day, to: calendar.startOfDay(for: now)) {
                    // 記録がある日のみ負債を計算
                    if let dailyRecords = dailyRecords[date], !dailyRecords.isEmpty {
                        let dailySleepHours = dailyRecords.reduce(0.0) { sum, record in
                            guard let startAt = record.startAt, let endAt = record.endAt else { return sum }
                            return sum + (endAt.timeIntervalSince(startAt) / 3600)
                        }
                        
                        let dailyDebt = calculateDailyDebt(sleepHours: dailySleepHours)
                        totalDebt += dailyDebt
                    }
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
        content.body = "健康を維持するために20〜30分の仮眠をおすすめします。"
        content.sound = UNNotificationSound.default
        
        // 現在の時間から1時間後に通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "napReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("仮眠通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    func scheduleSleepReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "就寝時間です"
        content.body = "質の良い睡眠のために、そろそろ就寝準備を始めましょう。"
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "sleepReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("就寝通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    func scheduleMorningSummary(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "睡眠サマリー"
        content.body = "昨夜の睡眠状態を確認しましょう。アプリを開いて詳細をご覧ください。"
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morningSummary", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("朝のサマリー通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    // 新しい睡眠記録を追加
    func addSleepRecord(context: NSManagedObjectContext, startAt: Date, endAt: Date, quality: Int16, sleepType: SleepRecordType = .normalSleep, memo: String? = nil) -> SleepRecord {
        let record = SleepRecord(context: context)
        record.id = UUID()
        record.startAt = startAt
        record.endAt = endAt
        record.quality = quality
        record.memo = memo
        record.createdAt = Date()
        record.sleepType = sleepType.rawValue
        
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
    
    // MARK: - チャートデータ取得
    
    /// 過去7日間の睡眠データを取得
    func getWeeklyChartData(context: NSManagedObjectContext) -> [SleepManagement.SleepChartData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        return getChartData(context: context, from: sevenDaysAgo, to: calendar.date(byAdding: .day, value: 1, to: today)!)
    }
    
    /// 過去30日間の睡眠データを取得
    func getMonthlyChartData(context: NSManagedObjectContext) -> [SleepManagement.SleepChartData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today)!
        
        return getChartData(context: context, from: thirtyDaysAgo, to: calendar.date(byAdding: .day, value: 1, to: today)!)
    }
    
    /// 指定期間の睡眠チャートデータを取得
    private func getChartData(context: NSManagedObjectContext, from: Date, to: Date) -> [SleepManagement.SleepChartData] {
        let calendar = Calendar.current
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startAt >= %@ AND startAt < %@", from as NSDate, to as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: true)]
        
        do {
            let records = try context.fetch(fetchRequest)
            
            // 日ごとにレコードをグループ化
            var dailyRecords: [Date: [SleepRecord]] = [:]
            for record in records {
                guard let startAt = record.startAt else { continue }
                let dateKey = calendar.startOfDay(for: startAt)
                if dailyRecords[dateKey] == nil {
                    dailyRecords[dateKey] = []
                }
                dailyRecords[dateKey]?.append(record)
            }
            
            // 各日のデータを集計
            var chartData: [SleepManagement.SleepChartData] = []
            
            // 日付の範囲内の各日を処理
            var currentDate = from
            while currentDate < to {
                if let dayRecords = dailyRecords[currentDate], !dayRecords.isEmpty {
                    // その日の合計睡眠時間を計算
                    let totalDuration = dayRecords.reduce(0.0) { sum, record in
                        guard let startAt = record.startAt, let endAt = record.endAt else { return sum }
                        return sum + endAt.timeIntervalSince(startAt)
                    }
                    
                    // その日の平均スコアを計算
                    let averageScore = dayRecords.reduce(0.0) { sum, record in
                        return sum + record.score
                    } / Double(dayRecords.count)
                    
                    let data = SleepManagement.SleepChartData(
                        date: currentDate,
                        duration: totalDuration,
                        score: averageScore
                    )
                    chartData.append(data)
                } else {
                    // データがない日はゼロデータを追加
                    let data = SleepManagement.SleepChartData(
                        date: currentDate,
                        duration: 0,
                        score: 0
                    )
                    chartData.append(data)
                }
                
                // 次の日に進む
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            return chartData
            
        } catch {
            print("チャートデータの取得に失敗しました: \(error)")
            return []
        }
    }
    
    /// 睡眠負債の推移データを取得
    func getSleepDebtTrend(context: NSManagedObjectContext, days: Int = 30) -> [Date: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days-1), to: today)!
        
        let fetchRequest: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startAt >= %@", startDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepRecord.startAt, ascending: true)]
        
        do {
            let records = try context.fetch(fetchRequest)
            var debtTrend: [Date: Double] = [:]
            
            // 各日のベースとなる0データを設定
            var currentDate = startDate
            while currentDate <= today {
                debtTrend[currentDate] = 0.0
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            // 記録がある日の負債を計算
            for record in records {
                guard let startAt = record.startAt else { continue }
                let dateKey = calendar.startOfDay(for: startAt)
                
                if let existingDebt = debtTrend[dateKey] {
                    debtTrend[dateKey] = existingDebt + (record.debt > 0 ? record.debt : 0)
                }
            }
            
            return debtTrend
            
        } catch {
            print("睡眠負債トレンドの取得に失敗しました: \(error)")
            return [:]
        }
    }
} 