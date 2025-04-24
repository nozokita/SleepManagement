import SwiftUI

// オンボーディングナビゲーション用のコンテナビュー
struct OnboardingNavigationView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .healthAndWatch
    
    enum OnboardingStep {
        case healthAndWatch
        case idealSleepTime
    }
    
    var body: some View {
        NavigationView {
            VStack {
                switch currentStep {
                case .healthAndWatch:
                    OnboardingView(onComplete: { 
                        currentStep = .idealSleepTime 
                    })
                case .idealSleepTime:
                    SettingsView(onComplete: {
                        // 全てのオンボーディングステップが完了
                        appState.completeOnboarding()
                    })
                }
            }
        }
    }
}

struct OnboardingNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingNavigationView()
            .environmentObject(AppState())
    }
} 