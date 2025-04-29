import SwiftUI
import CoreData

struct SleepDebtDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let windowStart: Date
    let windowEnd: Date
    // 詳細画面のタイトル
    let detailTitle: String

    private let manager = SleepManager.shared

    // 理想睡眠時間の合計 (時間): 期間に応じて日数分乗算
    private var idealHours: Double {
        let idealDaily = SettingsManager.shared.idealSleepDuration / 3600
        let durationDays = windowEnd.timeIntervalSince(windowStart) / (3600 * 24)
        return idealDaily * durationDays
    }
    // 実睡眠時間 (時間): 単純合計
    private var actualHours: Double {
        let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@ AND endAt <= %@", windowStart as NSDate, windowEnd as NSDate)
        let records = (try? context.fetch(request)) ?? []
        return records.reduce(0.0) { sum, record in
            guard let start = record.startAt, let end = record.endAt else { return sum }
            return sum + end.timeIntervalSince(start) / 3600
        }
    }
    // 有効睡眠時間 (時間): 重み付け考慮
    private var weightedHours: Double {
        let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@ AND endAt <= %@", windowStart as NSDate, windowEnd as NSDate)
        let records = (try? context.fetch(request)) ?? []
        return records.reduce(0.0) { sum, record in
            guard let start = record.startAt, let end = record.endAt else { return sum }
            let durationMin = Int(end.timeIntervalSince(start) / 60)
            return sum + manager.weight(for: durationMin) * (Double(durationMin) / 60)
        }
    }
    // 負債 (時間)
    private var debt: Double {
        max(idealHours - weightedHours, 0)
    }
    // 使用した重み係数の合計
    private var weightSum: Double {
        let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@ AND endAt <= %@", windowStart as NSDate, windowEnd as NSDate)
        let records = (try? context.fetch(request)) ?? []
        return records.reduce(0.0) { sum, record in
            guard let start = record.startAt, let end = record.endAt else { return sum }
            let durationMin = Int(end.timeIntervalSince(start) / 60)
            return sum + manager.weight(for: durationMin)
        }
    }
    // 期間内の睡眠記録
    private var recordsInWindow: [SleepRecord] {
        let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
        request.predicate = NSPredicate(format: "startAt >= %@ AND endAt <= %@", windowStart as NSDate, windowEnd as NSDate)
        return (try? context.fetch(request)) ?? []
    }
    // 係数ごとの記録数
    private var weightBreakdown: [Double: Int] {
        var dict: [Double: Int] = [:]
        for record in recordsInWindow {
            guard let start = record.startAt, let end = record.endAt else { continue }
            let durationMin = Int(end.timeIntervalSince(start) / 60)
            let w = manager.weight(for: durationMin)
            dict[w] = (dict[w] ?? 0) + 1
        }
        return dict
    }
    // 重み付けカテゴリ用データ構造
    private struct CoefficientCategory: Identifiable, Hashable {
        let id: Double
        let ja: String
        let en: String
        let weight: Double
        init(ja: String, en: String, weight: Double) {
            self.id = weight
            self.ja = ja
            self.en = en
            self.weight = weight
        }
    }
    // 係数カテゴリとラベル
    private var coefficientCategories: [CoefficientCategory] {
        [
            CoefficientCategory(ja: "<10分", en: "<10 min", weight: 0.0),
            CoefficientCategory(ja: "10–29分", en: "10–29 min", weight: 0.3),
            CoefficientCategory(ja: "30–59分", en: "30–59 min", weight: 0.6),
            CoefficientCategory(ja: "60–89分", en: "60–89 min", weight: 0.9),
            CoefficientCategory(ja: "≥90分", en: "≥90 min", weight: 1.0)
        ]
    }

    // 時間フォーマット
    private func formatHours(_ hours: Double) -> String {
        if localizationManager.currentLanguage == "ja" {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)時間\(m)分"
        } else {
            return String(format: "%.1fh", hours)
        }
    }

    // 週次モード判定
    private var isWeekly: Bool {
        detailTitle == (localizationManager.currentLanguage == "ja" ? "7日間の計算過程" : "7-Day Calculation Detail")
    }
    // 日付フォーマット（MM/dd）
    private var dayFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: localizationManager.currentLanguage == "ja" ? "ja_JP" : "en_US")
        df.dateFormat = "MM/dd"
        return df
    }

    // 日別負債エントリ
    private var dailyDebtEntries: [(date: Date, debt: Double)] {
        // 期間内の日別負債をまとめて算出
        var entries: [(Date, Double)] = []
        for offset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: windowEnd)!
            let start = manager.anchor(for: date, context: context)
            let end = Calendar.current.date(byAdding: .hour, value: 24, to: start)!
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.predicate = NSPredicate(format: "startAt < %@ AND endAt > %@", end as NSDate, start as NSDate)
            let records = (try? context.fetch(request)) ?? []
            let dailyHours = records.reduce(0.0) { sum, record in
                guard let st = record.startAt, let ed = record.endAt else { return sum }
                return sum + ed.timeIntervalSince(st) / 3600
            }
            let dailyDebt = manager.calculateDailyDebt(sleepHours: dailyHours)
            entries.append((date, dailyDebt))
        }
        return entries
    }

    var body: some View {
        NavigationView {
            List {
                if isWeekly {
                    // 日別負債ブレークダウン
                    Section(header: Text(localizationManager.currentLanguage == "ja" ? "日別負債" : "Daily Debt Breakdown")) {
                        ForEach(dailyDebtEntries, id: \.date) { entry in
                            HStack {
                                Text(dayFormatter.string(from: entry.date))
                                Spacer()
                                Text(formatHours(entry.debt))
                            }
                        }
                    }
                    // 合計負債
                    Section(header: Text(localizationManager.currentLanguage == "ja" ? "合計睡眠負債" : "Total Sleep Debt")) {
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "合計睡眠負債" : "Total Sleep Debt")
                            Spacer()
                            // 7日間固定集計の合計負債を計算
                            Text(formatHours(manager.calculateTotalDebt(context: context)))
                        }
                    }
                } else {
                    // 24時間モード時の重み付け係数とステップ
                    // 重み付け係数テーブル
                    Section(header: Text(localizationManager.currentLanguage == "ja" ? "重み付け係数 w(d) — 「質×時間」の重み付け" : "Coefficient w(d) — weighting of 'quality × time'")) {
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "<10分" : "<10 min")
                            Spacer()
                            Text("St-1")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "覚醒期" : "Vigilance lab")
                            Spacer()
                            Text("0.0")
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "10–29分" : "10–29 min")
                            Spacer()
                            Text("St-2")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "NASA 26分のナップ：性能+34%" : "NASA 26 min nap: +34% performance")
                            Spacer()
                            Text("0.3")
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "30–59分" : "30–59 min")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "早期SWS" : "Early SWS")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "記憶保全↑" : "Memory consolidation ↑")
                            Spacer()
                            Text("0.6")
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "60–89分" : "60–89 min")
                            Spacer()
                            Text("SWS+REM")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "慣性少" : "Less inertia")
                            Spacer()
                            Text("0.9")
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "≥90分" : "≥90 min")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "1–2サイクル" : "1–2 cycle")
                            Spacer()
                            Text(localizationManager.currentLanguage == "ja" ? "フィールドデータ" : "Field data")
                            Spacer()
                            Text("1.0")
                        }
                    }
                    // 計算ステップを表示
                    Section(header: Text(localizationManager.currentLanguage == "ja" ? "計算ステップ" : "Calculation Steps")) {
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "1. 設定画面から理想睡眠時間を読み込む" : "1. Load ideal sleep time from settings")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "2. 期間内の睡眠記録を取得" : "2. Fetch sleep records within period")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "3. 記録ごとの開始・終了時刻を取得" : "3. Retrieve start and end time for each record")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "4. 各記録の持続時間を分単位で計算 (終了-開始)" : "4. Calculate duration in minutes (end - start) for each record")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "5. 持続時間に応じた係数 w(d) をテーブルから取得" : "5. Get coefficient w(d) from table based on duration")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "6. w(d) × (分/60) で重み付き時間を計算" : "6. Calculate weighted time: w(d) × (minutes/60)")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "7. すべての重み付き時間を合計し、有効睡眠時間を算出" : "7. Sum all weighted times to get Effective Sleep")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "8. すべての係数 w(d) を合計し、係数合計を算出" : "8. Sum all coefficients w(d) to get total coefficient")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "9. 理想睡眠時間から有効睡眠時間を引いて負債を算出" : "9. Calculate debt by subtracting Effective Sleep from Ideal Sleep")
                            Spacer()
                        }
                        HStack {
                            Text(localizationManager.currentLanguage == "ja" ? "10. 負債と計算結果を画面に表示" : "10. Display debt and calculation results on screen")
                            Spacer()
                        }
                    }
                    // --- 計算結果 ---
                    HStack {
                        Text(localizationManager.currentLanguage == "ja" ? "理想睡眠時間" : "Ideal Sleep")
                        Spacer()
                        Text(formatHours(idealHours))
                    }
                    HStack {
                        Text(localizationManager.currentLanguage == "ja" ? "実睡眠時間" : "Actual Sleep")
                        Spacer()
                        Text(formatHours(actualHours))
                    }
                    HStack {
                        Text(localizationManager.currentLanguage == "ja" ? "使用した係数合計" : "Weights Sum")
                        Spacer()
                        Text(String(format: "%.2f", weightSum))
                    }
                    // 係数内訳を表示
                    Section(header: Text(localizationManager.currentLanguage == "ja" ? "係数内訳" : "Coefficient Breakdown")) {
                        ForEach(coefficientCategories) { category in
                            HStack {
                                Text(localizationManager.currentLanguage == "ja" ? category.ja : category.en)
                                Spacer()
                                Text("\(weightBreakdown[category.weight] ?? 0)")
                            }
                        }
                    }
                    HStack {
                        Text(localizationManager.currentLanguage == "ja" ? "有効睡眠時間" : "Effective Sleep")
                        Spacer()
                        Text(formatHours(weightedHours))
                    }
                    HStack {
                        Text(localizationManager.currentLanguage == "ja" ? "算出式" : "Calculation")
                        Spacer()
                        Text(String(format: "%@ - %@ = %@", formatHours(idealHours), formatHours(weightedHours), formatHours(debt)))
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .navigationBarTitle(detailTitle, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(localizationManager.currentLanguage == "ja" ? "閉じる" : "Close") {
                dismiss()
            }
        )
    }
}

struct SleepDebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SleepDebtDetailView(
            windowStart: Date(),
            windowEnd: Date(),
            detailTitle: LocalizationManager.shared.currentLanguage == "ja" ? "計算過程" : "Calculation Detail"
        )
            .environmentObject(LocalizationManager.shared)
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
} 