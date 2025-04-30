import Foundation
import CoreML

class AICoach {
    static let shared = AICoach()

    private let model: MLModel
    private let inputName: String
    private let outputName: String

    private init() {
        // バンドル内のコンパイル済モデル(.mlmodelc)を優先読み込み
        let bundle = Bundle.main
        let modelURL: URL
        if let mlcURL = bundle.url(forResource: "SleepDebtLSTM", withExtension: "mlmodelc") {
            modelURL = mlcURL
        } else if let mlURL = bundle.url(forResource: "SleepDebtLSTM", withExtension: "mlmodel") {
            // 生モデルを動的にコンパイル
            do {
                modelURL = try MLModel.compileModel(at: mlURL)
            } catch {
                fatalError("SleepDebtLSTMモデルのコンパイルに失敗: \(error)")
            }
        } else {
            fatalError("SleepDebtLSTMモデルがバンドルに見つかりません")
        }
        // MLModelの読み込み
        do {
            model = try MLModel(contentsOf: modelURL)
        } catch {
            fatalError("モデルの読み込みに失敗: \(error)")
        }
        // 入出力フィーチャー名の取得
        guard let inName = model.modelDescription.inputDescriptionsByName.keys.first,
              let outName = model.modelDescription.outputDescriptionsByName.keys.first else {
            fatalError("モデルの入出力記述が予期しない形式です")
        }
        inputName = inName
        outputName = outName
    }

    /// 過去の睡眠スコア配列から睡眠負債を予測（秒単位）
    func predictDebt(from scores: [Double]) -> Double? {
        // 入力のMultiArray制約から固定長を取得
        guard let constraint = model.modelDescription.inputDescriptionsByName[inputName]?.multiArrayConstraint,
              constraint.shape.count > 0,
              let length = constraint.shape.first?.intValue,
              let mlArray = try? MLMultiArray(shape: [NSNumber(value: length)], dataType: .double)
        else {
            return nil
        }
        // スコアを先頭に詰め、残りは0埋め
        for i in 0..<length {
            let val = i < scores.count ? scores[i] : 0.0
            mlArray[i] = NSNumber(value: val)
        }
        // 入力プロバイダ
        guard let inputProvider = try? MLDictionaryFeatureProvider(dictionary: [inputName: mlArray]) else {
            return nil
        }
        do {
            let output = try model.prediction(from: inputProvider)
            guard let feature = output.featureValue(for: outputName) else { return nil }
            // 出力がMultiArrayかスカラーか判定
            if let arr = feature.multiArrayValue {
                return arr[0].doubleValue
            } else {
                return feature.doubleValue
            }
        } catch {
            print("AICoach prediction error: \(error)")
            return nil
        }
    }
} 