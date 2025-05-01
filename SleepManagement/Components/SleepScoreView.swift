import SwiftUI

struct SleepScoreView: View {
    let score: Double
    var size: CGFloat = 80
    var showText: Bool = true
    var showAnimation: Bool = true
    
    // アニメーションの状態
    @State private var animationProgress: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.1
                )
                .frame(width: size, height: size)
            
            // スコアを表す円弧（グラデーション）
            Circle()
                .trim(from: 0, to: CGFloat(min(animationProgress / 100, 1.0)))
                .stroke(
                    Theme.Colors.scoreGradient(score: score),
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.Colors.scoreColor(score: score).opacity(0.5), radius: 4, x: 0, y: 2)
            
            if showText {
                // スコアのテキスト表示
                VStack(spacing: 0) {
                    Text("\(Int(score))")
                        .font(.system(size: size / 2.5, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("score_points".localized)
                        .font(.system(size: size / 6, design: .rounded))
                        .foregroundColor(Theme.Colors.subtext)
                }
                .opacity(textOpacity)
            }
            
            // スコア評価ラベル（スコアが高い場合）
            if score >= 80 && showText && size >= 80 {
                Text("excellent".localized)
                    .font(.system(size: size / 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.scoreColor(score: score))
                    .clipShape(Capsule())
                    .offset(y: size * 0.4)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            if showAnimation {
                // 円弧のアニメーション
                withAnimation(Animation.easeOut(duration: 1.5)) {
                    animationProgress = score
                }
                
                // テキストのフェードインアニメーション
                withAnimation(Animation.easeIn.delay(0.7)) {
                    textOpacity = 1
                }
            } else {
                // アニメーションなしの場合は即座に表示
                animationProgress = score
                textOpacity = 1
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            SleepScoreView(score: 85)
            SleepScoreView(score: 65)
        }
        
        HStack(spacing: 20) {
            SleepScoreView(score: 45)
            SleepScoreView(score: 95)
        }
        
        SleepScoreView(score: 90, size: 150)
    }
    .padding()
    .background(Theme.Colors.background)
    .environmentObject(LocalizationManager.shared)
} 