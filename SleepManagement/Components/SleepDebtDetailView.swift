import SwiftUI
import CoreData

struct SleepDebtDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let windowStart: Date
    let windowEnd: Date

    private let manager = SleepManager.shared

    // 理想睡眠時間 (時間)
    private var idealHours: Double {
        manager.recommendedSleepHours
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

    var body: some View {
        NavigationView {
            List {
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
            .navigationTitle(localizationManager.currentLanguage == "ja" ? "計算過程" : "Calculation Detail")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.currentLanguage == "ja" ? "閉じる" : "Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SleepDebtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SleepDebtDetailView(windowStart: Date(), windowEnd: Date())
            .environmentObject(LocalizationManager.shared)
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
} 