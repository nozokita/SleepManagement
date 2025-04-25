import SwiftUI

struct SettingsView: View {
    @StateObject var settings = SettingsManager.shared
    @State private var navigateHome = false
    @State private var navigateToHomeFromOnboarding = false
    var onComplete: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("ユーザー情報")) {
                        TextField("生年", value: $settings.birthYear, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                    }
                    Section(header: Text("理想睡眠時間")) {
                        Stepper(value: $settings.idealSleepDuration, in: 0...(24 * 3600), step: 3600) {
                            Text("理想時間: \(Int(settings.idealSleepDuration / 3600))時間")
                        }
                    }
                    Section {
                        Button(action: {
                            print("設定を保存しました")
                            settings.save()
                            
                            if let onComplete = onComplete {
                                // オンボーディングからの場合はHomeViewに遷移
                                print("オンボーディングからの遷移を開始")
                                // まず遷移フラグをセット
                                navigateToHomeFromOnboarding = true
                                
                                // 少し遅延させてからonCompleteを呼び出す
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onComplete()
                                    print("onComplete実行完了")
                                }
                            } else {
                                print("通常の設定画面からの遷移")
                                navigateHome = true
                            }
                        }) {
                            Text("保存")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationDestination(isPresented: $navigateHome) {
                HomeView()
            }
            .navigationDestination(isPresented: $navigateToHomeFromOnboarding) {
                HomeView()
                    .navigationBarHidden(true)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewLayout(.sizeThatFits)
    }
} 