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
        // モデルの入力MultiArray形状を取得し、ゼロパディング
        guard let desc = model.modelDescription.inputDescriptionsByName[inputName],
              let constraint = desc.multiArrayConstraint else {
            print("AICoach: Invalid input descriptor or not MultiArray")
            return nil
        }
        let shape = constraint.shape
        let totalCount = shape.map { $0.intValue }.reduce(1, *)
        guard let mlArray = try? MLMultiArray(shape: shape, dataType: constraint.dataType) else {
            return nil
        }
        for idx in 0..<totalCount {
            let value = idx < scores.count ? scores[idx] : 0.0
            mlArray[idx] = NSNumber(value: value)
        }
        // 入力プロバイダ生成
        guard let inputProvider = try? MLDictionaryFeatureProvider(dictionary: [inputName: mlArray]) else {
            return nil
        }
        do {
            let outputProvider = try model.prediction(from: inputProvider)
            // 出力フィーチャーを取得
            guard let feature = outputProvider.featureValue(for: outputName) else { return nil }
            // MultiArrayなら先頭要素を取得、そうでなければスカラー値を取得
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

    /// 予測された睡眠負債のパーセントを取得
    func getPredictedDebtPercent(from scores: [Double]) -> Double? {
        guard let debt = predictDebt(from: scores) else { return nil }
        let totalSecondsInDay = 24 * 60 * 60
        let percent = (debt / Double(totalSecondsInDay)) * 100
        return percent
    }

    /// 予測された睡眠負債のパーセントを四捨五入して取得
    func getPredictedDebtPercentRounded(from scores: [Double]) -> Int? {
        guard let percent = getPredictedDebtPercent(from: scores) else { return nil }
        return Int(round(percent))
    }

    /// 予測された睡眠負債のパーセントをユーザーに通知するメッセージを取得
    func getPredictedDebtMessage(from scores: [Double]) -> String? {
        guard let percentRounded = getPredictedDebtPercentRounded(from: scores) else { return nil }
        let ja = "予測睡眠負債の\(percentRounded)%は入眠に時間がかかっていることが要因です。就寝前の30分は画面をオフにして、深呼吸を取り入れましょう"
        let en = "About \(percentRounded)% of your predicted sleep debt is because it takes you a long time to fall asleep. Try turning off screens and doing deep breathing for the 30 minutes before bed."
        return ja
    }

    /// 睡眠負債の要因可視化と改善ポイントを生成 (日本語・英語)
    func generateDebtFactorAdvice(sleepData: SleepQualityData, predictedDebtSeconds: Double) -> (ja: String, en: String) {
        guard predictedDebtSeconds > 0, let latency = sleepData.sleepLatency else {
            return ("", "")
        }
        let percent = latency / predictedDebtSeconds * 100
        let percentRounded = Int(percent.rounded())
        let ja = "予測睡眠負債の\(percentRounded)%は就寝までの覚醒時間（入眠潜時）が長いことが要因です。就寝前30分は画面をオフにして、深呼吸を取り入れましょう"
        let en = "About \(percentRounded)% of your predicted sleep debt is due to long sleep latency. Try turning off screens and practicing deep breathing for 30 minutes before bed."
        return (ja, en)
    }

    /// 睡眠習慣の規則性改善アドバイスを生成 (日本語・英語)
    func generateRegularityAdvice(sleepData: SleepQualityData) -> (ja: String, en: String) {
        guard let sleepVar = sleepData.sleepTimeVariability else {
            return ("", "")
        }
        let varianceMinutes = Int((sleepVar / 60).rounded())
        let ja = "先週の就寝時間は平均±\(varianceMinutes)分のばらつきがありました。毎晩30分以内に揃えると睡眠効率が10%改善します"
        let en = "Your bedtime varied by ±\(varianceMinutes) minutes on average last week. Aligning your bedtime within 30 minutes each night can improve your sleep efficiency by 10%."
        return (ja, en)
    }
} 