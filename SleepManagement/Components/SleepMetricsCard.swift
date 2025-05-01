import SwiftUI

struct SleepMetricsCard: View {
    @StateObject private var vm = SleepViewModel()
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("metrics.title".localized)
                .font(Theme.Typography.subheadingFont)
                .foregroundColor(Theme.Colors.text)

            if let m = vm.latestMetrics {
                MetricRow(titleKey: "metrics.duration", value: m.durationH, unit: "h")
                MetricRow(titleKey: "metrics.efficiency", value: m.efficiency * 100, unit: "%")
                MetricRow(titleKey: "metrics.regularity", value: m.regularity, unit: "")
                MetricRow(titleKey: "metrics.latency", value: m.latency, unit: "min")
                MetricRow(titleKey: "metrics.waso", value: m.waso, unit: "min")
            } else {
                ProgressView()
                    .task { await vm.refresh() }
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func MetricRow(titleKey: String, value: Double, unit: String) -> some View {
        HStack {
            Text(titleKey.localized)
                .foregroundColor(Theme.Colors.text)
            Spacer()
            Text(String(format: unit.isEmpty ? "%.1f" : "%.1f %@", value, unit))
                .foregroundColor(Theme.Colors.subtext)
        }
    }
}

struct SleepMetricsCard_Previews: PreviewProvider {
    static var previews: some View {
        SleepMetricsCard()
            .environmentObject(LocalizationManager.shared)
            .background(Theme.Colors.background)
    }
} 