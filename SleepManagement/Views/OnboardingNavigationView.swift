import SwiftUI

// オンボーディングナビゲーション用のコンテナビュー
struct OnboardingNavigationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var currentStep: OnboardingStep = .healthAndWatchSettings
    @State private var navigateToDashboard = false
    @State private var refreshView = false // 言語変更時の再描画用
    
    enum OnboardingStep {
        case healthAndWatchSettings
        case idealSleepTimeSettings
    }
    
    var body: some View {
        NavigationStack {
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
                        Text("onboarding.step.deviceSettings")
                            .font(.caption)
                            .foregroundColor(currentStep == .healthAndWatchSettings ? .blue : .gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("onboarding.step.sleepSettings")
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
                        .environmentObject(localizationManager)
                        
                    case .idealSleepTimeSettings:
                        SettingsView(onComplete: {
                            print("オンボーディング完了コールバック実行")
                            // オンボーディング完了を記録
                            appState.completeOnboarding()
                            
                            // ダッシュボードに遷移
                            print("ダッシュボードへ遷移準備")
                            navigateToDashboard = true
                        })
                        .environmentObject(localizationManager)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToDashboard) {
                ContentView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                    .environmentObject(localizationManager)
                    .navigationBarHidden(true)
            }
        }
        .transition(.opacity.combined(with: .slide))
        .animation(.easeInOut, value: currentStep)
        .onAppear {
            print("OnboardingNavigationView表示: ステップ = \(currentStep)")
            print("OnboardingNavigationView表示 - 現在の言語: \(localizationManager.currentLanguage)")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
            print("OnboardingNavigationView - 言語変更通知を受信: \(localizationManager.currentLanguage)")
            refreshView.toggle() // 強制的に再描画
        }
        .id(refreshView) // 言語変更時に強制的に再描画
    }
}

struct OnboardingNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingNavigationView()
            .environmentObject(AppState())
            .environmentObject(LocalizationManager.shared)
    }
} 