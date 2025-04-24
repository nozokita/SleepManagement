import SwiftUI

struct SettingsView: View {
    @StateObject var settings = SettingsManager.shared
    @State private var navigateHome = false
    var onComplete: (() -> Void)? = nil

    var body: some View {
        NavigationView {
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
                            settings.save()
                            if let onComplete = onComplete {
                                onComplete()
                            } else {
                                navigateHome = true
                            }
                        }) {
                            Text("保存")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                if onComplete == nil {
                    NavigationLink(destination: HomeView(), isActive: $navigateHome) {
                        EmptyView()
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewLayout(.sizeThatFits)
    }
} 