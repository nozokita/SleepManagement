import Foundation
import CoreData

/// BanditManager: LinUCBバンディットアルゴリズムをラップし、アクション選択と報酬更新を管理
final class BanditManager: ObservableObject {
    static let shared = BanditManager()

    @Published var suggestedArm: SleepActionArm = .earlyBedtime
    private let bandit: LinUCBBandit

    private init() {
        // 文脈ベクトルの次元数は [予測負債, 自由時間, クロノタイプ] で3
        bandit = LinUCBBandit(dimension: 3)
    }

    /// 文脈を取得して最適アクションを選択し、suggestedArmを更新
    func updateSuggestion(viewContext: NSManagedObjectContext, predictedDebtSec: Double?) {
        let contextVec = SleepContextProvider.getContext(
            viewContext: viewContext,
            predictedDebtSec: predictedDebtSec
        )
        let arm = bandit.chooseArm(context: contextVec)
        DispatchQueue.main.async {
            self.suggestedArm = arm
        }
    }

    /// ユーザーからの報酬を受け取り、Banditにフィードバック
    func recordReward(_ reward: Double, viewContext: NSManagedObjectContext, predictedDebtSec: Double?) {
        let contextVec = SleepContextProvider.getContext(
            viewContext: viewContext,
            predictedDebtSec: predictedDebtSec
        )
        bandit.update(arm: suggestedArm, reward: reward, context: contextVec)
    }
} 