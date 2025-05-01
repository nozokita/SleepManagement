import Foundation

/// アクション（アーム）定義
/// 早寝／パワーナップ／睡眠ルーチン強化アクションを列挙
enum SleepActionArm: Int, CaseIterable {
    case earlyBedtime      // 早寝アクション
    case powerNap          // パワーナップアクション
    case reinforceRoutine  // 睡眠ルーチン強化アクション

    /// ユーザー向け説明文（ローカライズキーを利用）
    var description: String {
        switch self {
        case .earlyBedtime:     return "early_bedtime_action".localized
        case .powerNap:         return "power_nap_action".localized
        case .reinforceRoutine: return "reinforce_routine_action".localized
        }
    }
}

/// LinUCBアルゴリズムによるコンテキスト付きマルチアームバンディット
class LinUCBBandit {
    private let alpha: Double
    private let arms: [SleepActionArm]
    private let dimension: Int
    private var Ainv: [SleepActionArm: [[Double]]]
    private var b: [SleepActionArm: [Double]]

    /// - Parameters:
    ///   - arms: 使用するアーム一覧
    ///   - dimension: 文脈ベクトルの次元数
    ///   - alpha: 探索係数 (デフォルト1.0)
    init(arms: [SleepActionArm] = SleepActionArm.allCases, dimension: Int, alpha: Double = 1.0) {
        self.alpha = alpha
        self.arms = arms
        self.dimension = dimension
        self.Ainv = [:]
        self.b = [:]
        // 各アームごとに Ainv=I, b=0ベクトルで初期化
        arms.forEach { arm in
            self.Ainv[arm] = identityMatrix(dimension)
            self.b[arm] = Array(repeating: 0.0, count: dimension)
        }
    }

    /// コンテキストベクトルから最適と推定されるアームを選択
    /// - Parameter context: [予測睡眠負債, 自由時間, クロノタイプなど]
    func chooseArm(context: [Double]) -> SleepActionArm {
        guard context.count == dimension else { return arms.first! }
        var pValues: [SleepActionArm: Double] = [:]
        arms.forEach { arm in
            guard let AinvArm = Ainv[arm], let bArm = b[arm] else { return }
            // θ = Ainv * b
            let theta = multMatrixVector(AinvArm, bArm)
            let mean = dot(theta, context)
            // 分散成分
            let Ainv_x = multMatrixVector(AinvArm, context)
            let variance = dot(context, Ainv_x)
            pValues[arm] = mean + alpha * sqrt(variance)
        }
        // pが最大のアームを返却
        return pValues.max { $0.value < $1.value }!.key
    }

    /// 選択アームに対して報酬を受け取り、内部パラメータを更新
    func update(arm: SleepActionArm, reward: Double, context: [Double]) {
        guard context.count == dimension,
              let AinvArmOrig = Ainv[arm],
              let bArmOrig = b[arm]
        else { return }
        // Sherman-MorrisonでAinv更新
        let Ainv_x = multMatrixVector(AinvArmOrig, context)
        let denom = 1.0 + dot(context, Ainv_x)
        let outer = outerProduct(Ainv_x, Ainv_x)
        var updatedAinv = AinvArmOrig
        for r in 0..<dimension {
            for c in 0..<dimension {
                updatedAinv[r][c] -= outer[r][c] / denom
            }
        }
        Ainv[arm] = updatedAinv
        // b更新
        var updatedB = bArmOrig
        for i in 0..<dimension {
            updatedB[i] += reward * context[i]
        }
        b[arm] = updatedB
    }
}

// MARK: - 行列・ベクトル演算ヘルパー
private func identityMatrix(_ n: Int) -> [[Double]] {
    var mat = Array(repeating: Array(repeating: 0.0, count: n), count: n)
    for i in 0..<n { mat[i][i] = 1.0 }
    return mat
}

private func dot(_ a: [Double], _ b: [Double]) -> Double {
    var sum = 0.0
    for i in 0..<a.count { sum += a[i] * b[i] }
    return sum
}

private func multMatrixVector(_ mat: [[Double]], _ vec: [Double]) -> [Double] {
    return mat.map { row in dot(row, vec) }
}

private func outerProduct(_ a: [Double], _ b: [Double]) -> [[Double]] {
    return a.map { ai in b.map { bj in ai * bj } }
} 