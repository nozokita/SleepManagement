import SwiftUI

// オンボーディングナビゲーション用のコンテナビュー
struct OnboardingNavigationView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .healthAndWatchSettings
    
    enum OnboardingStep {
        case healthAndWatchSettings
        case idealSleepTimeSettings
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // プログレスインジケーター
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentStep == .healthAndWatchSettings ? Color.blue : Color.gray)
                        .frame(width: 10, height: 10)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                    
                    Circle()
                        .fill(currentStep == .idealSleepTimeSettings ? Color.blue : Color.gray)
                        .frame(width: 10, height: 10)
                }
                .padding(.horizontal, 60)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // ステップテキスト
                HStack {
                    Text("デバイス設定")
                        .font(.caption)
                        .foregroundColor(currentStep == .healthAndWatchSettings ? .blue : .gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("睡眠設定")
                        .font(.caption)
                        .foregroundColor(currentStep == .idealSleepTimeSettings ? .blue : .gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 16)
                
                // ステップに応じたビューを表示
                switch currentStep {
                case .healthAndWatchSettings:
                    OnboardingView(onComplete: {
                        withAnimation {
                            currentStep = .idealSleepTimeSettings
                        }
                    })
                    
                case .idealSleepTimeSettings:
                    SettingsView(onComplete: {
                        appState.completeOnboarding()
                    })
                }
            }
        }
        .transition(.opacity.combined(with: .slide))
        .animation(.easeInOut, value: currentStep)
    }
}

struct OnboardingNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingNavigationView()
            .environmentObject(AppState())
    }
} 