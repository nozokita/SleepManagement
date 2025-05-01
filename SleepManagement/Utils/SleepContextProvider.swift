import Foundation
import CoreData

/// SleepContextProvider: 文脈ベクトル（予測睡眠負債、自由時間、クロノタイプ）を提供します
struct SleepContextProvider {
    /// - Parameters:
    ///   - viewContext: Core Data のコンテキスト
    ///   - predictedDebtSec: 予測睡眠負債（秒）
    /// - Returns: [予測睡眠負債（時間単位）, 自由時間（時間単位）, クロノタイプ値]
    static func getContext(viewContext: NSManagedObjectContext, predictedDebtSec: Double?) -> [Double] {
        // 予測睡眠負債（時間単位）
        let predictedDebtHours: Double = {
            guard let sec = predictedDebtSec else { return 0.0 }
            return sec / 3600.0
        }()
        // 自由時間（時間単位）：予定情報取得ロジック未実装のため仮置き値
        let freeTimeHours: Double = 2.0
        // ユーザーのクロノタイプ値
        let chronoValue = SettingsManager.shared.chronotypeValue
        return [predictedDebtHours, freeTimeHours, chronoValue]
    }
} 