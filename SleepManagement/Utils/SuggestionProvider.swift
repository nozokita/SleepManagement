import Foundation

struct Suggestion {
    let title: String
    let message: String
}

struct SleepSuggestionContext {
    let debtMinutes: Int
    let freeMinutes: Int
    let chronoNormalized: Double
    let weekendShiftMinutes: Int
    let futureDebtMinutes: [Date: Int]
    let usualBedHour: Int
    let usualWakeHour: Int
}

// Removed duplicate SleepActionArm enum; using the one defined in LinUCB.swift

class SuggestionProvider {
    static func generate(context: SleepSuggestionContext, arm: SleepActionArm) -> Suggestion {
        // 大きな負債 (>120分)
        if context.debtMinutes >= 120 {
            let hours = context.debtMinutes / 60
            // 1時間早く寝ることで1時間返済できる想定
            let repayHours = 1
            let suggestionLimitHour = context.usualBedHour - repayHours
            return Suggestion(
                title: "suggest_highDebt_title".localized,
                message: String(
                    format: "suggest_highDebt_message".localized,
                    hours, context.usualBedHour, suggestionLimitHour, repayHours
                )
            )
        }
        // 中度負債 (30〜119) & 空き時間
        if (30..<120).contains(context.debtMinutes), context.freeMinutes >= 20 {
            let nap = 20
            return Suggestion(
                title: "suggest_moderateDebt_title".localized,
                message: String(
                    format: "suggest_moderateDebt_message".localized,
                    nap
                )
            )
        }
        // リズム乱れ (週末ズレ >=120)
        if context.weekendShiftMinutes >= 120 {
            let shiftHours = context.weekendShiftMinutes / 60
            let wakeHour = context.usualWakeHour
            return Suggestion(
                title: "suggest_rhythm_title".localized,
                message: String(
                    format: "suggest_rhythm_message".localized,
                    shiftHours, wakeHour
                )
            )
        }
        // 将来負債予測 (>=180)
        if let (date, debt) = context.futureDebtMinutes.first(where: { $0.value >= 180 }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            let strDate = formatter.string(from: date)
            return Suggestion(
                title: "suggest_futureHigh_title".localized,
                message: String(
                    format: "suggest_futureHigh_message".localized,
                    strDate, debt / 60
                )
            )
        }
        // デフォルト
        return Suggestion(
            title: "suggest_default_title".localized,
            message: "suggest_default_message".localized
        )
    }
}
