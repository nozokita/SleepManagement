import SwiftUI

// オンボーディングナビゲーション用のコンテナビュー
struct OnboardingNavigationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var currentStep: OnboardingStep = .sourceSelection
    @State private var navigateToDashboard = false
    @State private var refreshView = false // 言語変更時の再描画用
    
    enum OnboardingStep {
        case sourceSelection          // 新規ステップ: データ取得方法選択
        case healthAndWatchSettings   // HealthKit 許可
        case idealSleepTimeSettings   // 理想睡眠時間設定
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // プログレスインジケーター（3ステップ）
                    HStack(spacing: 8) {
                        Circle().fill(currentStep == .sourceSelection ? Color.blue : Color.gray)
                            .frame(width: 10, height: 10)
                        Rectangle().fill(Color.gray.opacity(0.3))
                            .frame(height: 2).frame(maxWidth: .infinity)
                        Circle().fill(currentStep == .healthAndWatchSettings ? Color.blue : Color.gray)
                            .frame(width: 10, height: 10)
                        Rectangle().fill(Color.gray.opacity(0.3))
                            .frame(height: 2).frame(maxWidth: .infinity)
                        Circle().fill(currentStep == .idealSleepTimeSettings ? Color.blue : Color.gray)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // ステップテキスト
                    HStack {
                        Text("onboarding.step.sourceSelection")
                            .font(.caption)
                            .foregroundColor(currentStep == .sourceSelection ? .blue : .gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("onboarding.step.deviceSettings")
                            .font(.caption)
                            .foregroundColor(currentStep == .healthAndWatchSettings ? .blue : .gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("onboarding.step.sleepSettings")
                            .font(.caption)
                            .foregroundColor(currentStep == .idealSleepTimeSettings ? .blue : .gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 16)
                    
                    // ステップに応じたビューを表示
                    switch currentStep {
                    case .sourceSelection:
                        // データ取得方法選択ステップ
                        VStack(spacing: 20) {
                            Text("onboarding.selectSource.title")
                                .font(.headline)
                            Button(action: {
                                // 手動入力を選択
                                SettingsManager.shared.autoSyncHealthKit = false
                                withAnimation { currentStep = .idealSleepTimeSettings }
                            }) {
                                Text("onboarding.selectSource.manual")
                                    .padding().frame(maxWidth: .infinity)
                                    .background(Color.blue).foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            Button(action: {
                                // HealthKit自動取得を選択
                                SettingsManager.shared.autoSyncHealthKit = true
                                withAnimation { currentStep = .healthAndWatchSettings }
                            }) {
                                Text("onboarding.selectSource.healthkit")
                                    .padding().frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.2)).foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                    case .healthAndWatchSettings:
                        OnboardingView(onComplete: {
                            withAnimation { currentStep = .idealSleepTimeSettings }
                        })
                        .environmentObject(localizationManager)
                        
                    case .idealSleepTimeSettings:
                        SettingsView(onComplete: {
                            appState.completeOnboarding()
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