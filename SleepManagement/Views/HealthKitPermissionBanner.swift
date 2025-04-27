import SwiftUI
import HealthKit
import UIKit

struct HealthKitPermissionBanner: View {
    @ObservedObject private var hkManager = HealthKitManager.shared
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        // 権限未許可（要リクエスト）の場合に表示
        if hkManager.authorizationStatus == .shouldRequest {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("healthkit.permission.required".localized)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("healthkit.permission.button".localized)
                        .font(.subheadline.bold())
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct HealthKitPermissionBanner_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionBanner()
            .environmentObject(LocalizationManager.shared)
            .previewLayout(.sizeThatFits)
    }
} 