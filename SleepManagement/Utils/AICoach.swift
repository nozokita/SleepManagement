import Foundation
import CoreML

class AICoach {
    static let shared = AICoach()
    private let model: SleepDebtLSTM

    private init() {
        do {
            let config = MLModelConfiguration()
            model = try SleepDebtLSTM(configuration: config)
        } catch {
            fatalError("Failed to load SleepDebtLSTM model: \(error)")
        }
    }

    /// 過去の睡眠スコア配列から睡眠負債を予測（秒単位）
    func predictDebt(from scores: [Double]) -> Double? {
        // モデル入力用MLMultiArrayの生成（shapeはモデル仕様に合わせる）
        guard let mlArray = try? MLMultiArray(shape: [NSNumber(value: scores.count)], dataType: .double) else {
            return nil
        }
        for (i, score) in scores.enumerated() {
            mlArray[i] = NSNumber(value: score)
        }
        do {
            let input = SleepDebtLSTMInput(input: mlArray)
            let result = try model.prediction(input: input)
            // モデルの出力は1つだけの想定なので、featureNamesの最初のキーから取得
            let provider = result as MLFeatureProvider
            if let name = provider.featureNames.first,
               let val = provider.featureValue(for: name) {
                return val.doubleValue
            }
            return nil
        } catch {
            print("AICoach prediction error: \(error)")
            return nil
        }
    }
} 