import SwiftUI

/// 睡眠の質スコアとその内訳を表示するビュー
struct SleepQualityScoreView: View {
    /// 睡眠の質スコアデータ
    let score: SleepQualityScore
    
    /// 元データ（実測値表示用）
    let data: SleepQualityData
    
    /// ビューの本体
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreHeader
                
                Divider()
                
                scoreComponents
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    /// スコアヘッダーセクション
    private var scoreHeader: some View {
        VStack(spacing: 8) {
            Text("睡眠の質スコア")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(score.totalScore)")
                    .font(.system(size: 48, weight: .bold))
                
                Text("/100")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
            }
            
            qualityLevelView
                .padding(.top, 4)
            
            scoreDescription
                .padding(.top, 8)
        }
    }
    
    /// 質レベル表示
    private var qualityLevelView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(qualityLevelColor)
                .frame(width: 12, height: 12)
            
            Text(qualityLevelText)
                .font(.subheadline)
                .bold()
                .foregroundColor(qualityLevelColor)
        }
    }
    
    /// 質レベルに対応するテキスト
    private var qualityLevelText: String {
        switch score.qualityLevel {
        case .excellent:
            return "最高の睡眠"
        case .good:
            return "良い睡眠"
        case .fair:
            return "普通の睡眠"
        case .poor:
            return "改善が必要"
        case .unknown:
            return "評価不能"
        }
    }
    
    /// 質レベルに対応する色
    private var qualityLevelColor: Color {
        switch score.qualityLevel {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    /// スコアの説明
    private var scoreDescription: some View {
        Text(getScoreDescription())
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    /// スコア説明文を取得
    private func getScoreDescription() -> String {
        switch score.qualityLevel {
        case .excellent:
            return "理想的な睡眠が取れています。この状態を維持しましょう。"
        case .good:
            return "良質な睡眠が取れています。少し改善するともっと良くなります。"
        case .fair:
            return "平均的な睡眠状態です。いくつかの要素を改善するとより良い睡眠になります。"
        case .poor:
            return "睡眠の質に課題があります。下記のポイントを参考に改善を検討しましょう。"
        case .unknown:
            return "十分なデータがないため、正確な評価ができません。"
        }
    }
    
    /// スコアの内訳表示
    private var scoreComponents: some View {
        VStack(spacing: 24) {
            // 睡眠時間スコア
            ScoreComponentRow(
                title: "睡眠時間",
                score: score.componentScores.durationScore,
                maxScore: 40,
                description: durationDescription
            )
            
            // 睡眠効率スコア
            ScoreComponentRow(
                title: "睡眠効率",
                score: score.componentScores.efficiencyScore,
                maxScore: 25,
                description: efficiencyDescription
            )
            
            // 睡眠の規則性スコア
            ScoreComponentRow(
                title: "睡眠の規則性",
                score: score.componentScores.regularityScore,
                maxScore: 15,
                description: regularityDescription
            )
            
            // 入眠潜時スコア
            ScoreComponentRow(
                title: "入眠潜時",
                score: score.componentScores.latencyScore,
                maxScore: 10,
                description: latencyDescription
            )
            
            // 夜間覚醒スコア
            ScoreComponentRow(
                title: "夜間覚醒",
                score: score.componentScores.wasoScore,
                maxScore: 10,
                description: wasoDescription
            )
        }
    }
    
    /// 睡眠時間の説明
    private var durationDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("あなたの睡眠時間: \(formatDuration(data.totalSleepTime))")
                .font(.subheadline)
            
            Text(getDurationAdvice())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 睡眠時間のアドバイスを取得
    private func getDurationAdvice() -> String {
        let hoursSlept = data.totalSleepTime / 3600.0
        
        if hoursSlept >= 7.0 && hoursSlept <= 9.0 {
            return "理想的な睡眠時間です（7-9時間）。"
        } else if hoursSlept < 7.0 {
            return "睡眠時間がやや短いです。理想は7-9時間です。"
        } else {
            return "睡眠時間がやや長いです。理想は7-9時間です。"
        }
    }
    
    /// 睡眠効率の説明
    private var efficiencyDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let efficiency = data.sleepEfficiency {
                Text("あなたの睡眠効率: \(formatEfficiency(efficiency))")
                    .font(.subheadline)
            } else if let quality = data.subjectiveSleepQuality {
                Text("主観的な質: \(quality)/5")
                    .font(.subheadline)
            }
            
            Text(getEfficiencyAdvice())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 睡眠効率のアドバイスを取得
    private func getEfficiencyAdvice() -> String {
        if let efficiency = data.sleepEfficiency {
            if efficiency >= 0.90 {
                return "素晴らしい睡眠効率です。ベッドで過ごす時間のほとんどを睡眠に使えています。"
            } else if efficiency >= 0.85 {
                return "良好な睡眠効率です。理想は90%以上です。"
            } else if efficiency >= 0.80 {
                return "平均的な睡眠効率です。就寝環境を改善するとさらに良くなるでしょう。"
            } else {
                return "睡眠効率が低めです。ベッドでの覚醒時間を減らすことを検討しましょう。"
            }
        } else {
            return "睡眠の質をさらに向上させるには、就寝環境や睡眠習慣の改善を検討しましょう。"
        }
    }
    
    /// 睡眠の規則性の説明
    private var regularityDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let sleepVar = data.sleepTimeVariability, let wakeVar = data.wakeTimeVariance {
                let avgVar = (sleepVar + wakeVar) / 2 / 60
                Text("就寝・起床時間のばらつき: 約\(Int(avgVar))分")
                    .font(.subheadline)
            } else if let regularity = data.subjectiveSleepRegularity {
                Text("主観的な規則性: \(regularity)/5")
                    .font(.subheadline)
            }
            
            Text(getRegularityAdvice())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 睡眠の規則性のアドバイスを取得
    private func getRegularityAdvice() -> String {
        if let sleepVar = data.sleepTimeVariability, let wakeVar = data.wakeTimeVariance {
            let avgVar = (sleepVar + wakeVar) / 2 / 60
            
            if avgVar < 30 {
                return "非常に規則的な睡眠パターンです。体内時計が整っています。"
            } else if avgVar < 60 {
                return "比較的規則的な睡眠パターンです。さらに一定の時間に就寝・起床するとより良いでしょう。"
            } else {
                return "睡眠パターンにばらつきがあります。毎日同じ時間に就寝・起床すると改善します。"
            }
        } else {
            return "規則的な睡眠スケジュールは良質な睡眠と体内時計の維持に重要です。"
        }
    }
    
    /// 入眠潜時の説明
    private var latencyDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let latency = data.sleepLatency {
                Text("入眠までの時間: \(formatDuration(latency))")
                    .font(.subheadline)
            } else if let latencyRating = data.subjectiveSleepLatency {
                Text("主観的な入眠のしやすさ: \(latencyRating)/5")
                    .font(.subheadline)
            }
            
            Text(getLatencyAdvice())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 入眠潜時のアドバイスを取得
    private func getLatencyAdvice() -> String {
        if let latency = data.sleepLatency {
            let latencyMinutes = latency / 60
            
            if latencyMinutes <= 15 {
                return "理想的な入眠時間です。スムーズに眠りについています。"
            } else if latencyMinutes <= 30 {
                return "平均的な入眠時間です。就寝前のリラックス習慣で改善できるかもしれません。"
            } else {
                return "入眠に時間がかかっています。就寝前の活動やカフェイン摂取を見直しましょう。"
            }
        } else {
            return "入眠しやすくするには、就寝前のスクリーン利用を控え、リラックスする習慣を作りましょう。"
        }
    }
    
    /// 夜間覚醒の説明
    private var wasoDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let waso = data.waso {
                Text("夜間の覚醒時間: \(formatDuration(waso))")
                    .font(.subheadline)
            } else if let wasoRating = data.subjectiveWaso {
                Text("主観的な夜間覚醒: \(wasoRating)/5")
                    .font(.subheadline)
            }
            
            Text(getWasoAdvice())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 夜間覚醒のアドバイスを取得
    private func getWasoAdvice() -> String {
        if let waso = data.waso {
            let wasoMinutes = waso / 60
            
            if wasoMinutes < 20 {
                return "夜間の覚醒が少なく、連続的な睡眠が取れています。"
            } else if wasoMinutes < 40 {
                return "平均的な夜間覚醒時間です。就寝環境の改善で減らせる可能性があります。"
            } else {
                return "夜間に頻繁に目覚めています。室温、光、音などの環境要因を確認しましょう。"
            }
        } else {
            return "夜間の覚醒を減らすには、アルコール摂取を控え、快適な寝室環境を整えましょう。"
        }
    }
    
    /// 時間を表示用にフォーマット
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    /// 効率を表示用にフォーマット
    private func formatEfficiency(_ efficiency: Double) -> String {
        let percentage = efficiency * 100
        return String(format: "%.1f%%", percentage)
    }
}

/// スコアコンポーネント行（各要素のスコア表示）
struct ScoreComponentRow: View {
    let title: String
    let score: Int
    let maxScore: Int
    let description: AnyView
    
    init(title: String, score: Int, maxScore: Int, description: some View) {
        self.title = title
        self.score = score
        self.maxScore = maxScore
        self.description = AnyView(description)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(score)/\(maxScore)")
                    .font(.headline)
                    .foregroundColor(scoreColor)
            }
            
            ProgressBar(value: Float(score) / Float(maxScore), color: scoreColor)
                .frame(height: 8)
            
            description
        }
    }
    
    /// スコアに対応する色
    private var scoreColor: Color {
        let percentage = Float(score) / Float(maxScore)
        
        if percentage >= 0.8 {
            return .green
        } else if percentage >= 0.6 {
            return .blue
        } else if percentage >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

/// プログレスバー
struct ProgressBar: View {
    var value: Float
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.2)
                    .foregroundColor(Color(.systemGray4))
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(color)
            }
            .cornerRadius(4)
        }
    }
}

#Preview {
    // サンプルデータ
    let componentScores = SleepQualityScore.ComponentScores(
        durationScore: 35,
        efficiencyScore: 20,
        regularityScore: 12,
        latencyScore: 8,
        wasoScore: 7
    )
    
    let sampleScore = SleepQualityScore(
        totalScore: 82,
        componentScores: componentScores
    )
    
    let sampleData = SleepQualityData(
        totalSleepTime: 27000,        // 7.5時間
        idealSleepTime: 28800,        // 8時間（例）
        timeInBed: 28800,             // ベッドイン時間のプレースホルダー
        sleepEfficiency: 0.92,
        sleepLatency: 900,            // 15分
        waso: 1200,                   // 20分
        sleepTimeVariability: 1800,   // 30分
        wakeTimeVariability: 1200,    // 20分
        sleepRegularityIndex: nil,
        subjectiveSleepQuality: 4,
        subjectiveSleepLatency: nil,
        subjectiveSleepRegularity: 4,
        subjectiveWaso: 4,
        subjectiveSleepiness: nil,
        hasWearableData: false
    )
    SleepQualityScoreView(score: sampleScore, data: sampleData)
        .padding()
} 