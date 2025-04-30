// MARK: - 専門家からのアドバイスセクション
private var expertAdviceSection: some View {
    Group {
        if let latestRecord = sleepRecords.first {
            // SleepQualityDataを生成
            let sleepData = SleepQualityData.fromSleepEntry(
                latestRecord,
                sleepHistoryEntries: Array(sleepRecords),
                idealSleepDurationProvider: { SettingsManager.shared.idealSleepDuration }
            )
            let advices = SleepAdvice.generateAdviceFrom(sleepData: sleepData)
            VStack(spacing: 0) {
                // カードヘッダー
                HStack {
                    Label("expert_advice".localized, systemImage: "lightbulb")
                        .font(Theme.Typography.subheadingFont)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.Colors.cardGradient)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("expert_advice_description".localized)
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.subtext)

                    ForEach(advices.prefix(3), id: \.id) { advice in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(advice.title.localized)
                                .font(Theme.Typography.subheadingFont)
                                .foregroundColor(Theme.Colors.text)
                            Text(advice.description.localized)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.subtext)
                        }
                    }
                    // 医療的アドバイスではない旨の注意書き
                    Text("expert_advice_disclaimer".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.subtext)
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Layout.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .offset(y: animatedCards ? 0 : 50)
            .opacity(animatedCards ? 1 : 0)
        }
    }
} 