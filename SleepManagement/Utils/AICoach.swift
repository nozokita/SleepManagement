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

    /// 睡眠負債要因の構造体
    struct DebtFactor {
        let id: String
        let factorNameKey: String
        let suggestionKey: String
        let percentage: Double
    }
    
    /// 睡眠データから負債要因とその割合を解析する
    func analyzeDebtFactors(sleepData: SleepQualityData) -> [DebtFactor] {
        // 各要因の閾値設定
        let latency = sleepData.sleepLatency ?? 0
        let variability = sleepData.sleepTimeVariability ?? 0
        let efficiency = sleepData.sleepEfficiency ?? 1
        let waso = sleepData.waso ?? 0
        let shortfall = max((sleepData.idealSleepTime - sleepData.totalSleepTime), 0)
        
        let thresholdLatency = 30 * 60.0
        let thresholdVariability = 3600.0
        let thresholdInefficiency = 1 - 0.85
        let thresholdWaso = 30 * 60.0
        let thresholdShortfall = 3600.0
        
        // 正規化
        let normLatency = min(latency / thresholdLatency, 1.0)
        let normVariability = min(variability / thresholdVariability, 1.0)
        let normInefficiency = min((1 - efficiency) / thresholdInefficiency, 1.0)
        let normWaso = min(waso / thresholdWaso, 1.0)
        let normShortfall = min(shortfall / thresholdShortfall, 1.0)
        
        let sumNorm = normLatency + normVariability + normInefficiency + normWaso + normShortfall
        guard sumNorm > 0 else { return [] }
        
        var factors: [DebtFactor] = []
        factors.append(DebtFactor(id: "sleep_latency", factorNameKey: "debt_factor_sleep_latency", suggestionKey: "debt_suggestion_sleep_latency", percentage: normLatency / sumNorm * 100))
        factors.append(DebtFactor(id: "sleep_variability", factorNameKey: "debt_factor_variability", suggestionKey: "debt_suggestion_variability", percentage: normVariability / sumNorm * 100))
        factors.append(DebtFactor(id: "low_sleep_efficiency", factorNameKey: "debt_factor_low_efficiency", suggestionKey: "debt_suggestion_low_efficiency", percentage: normInefficiency / sumNorm * 100))
        factors.append(DebtFactor(id: "frequent_wakeups", factorNameKey: "debt_factor_waso", suggestionKey: "debt_suggestion_waso", percentage: normWaso / sumNorm * 100))
        factors.append(DebtFactor(id: "sleep_debt", factorNameKey: "debt_factor_sleep_debt", suggestionKey: "debt_suggestion_sleep_debt", percentage: normShortfall / sumNorm * 100))
        
        return factors.sorted { $0.percentage > $1.percentage }
    }
} 