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

                // 端的な箇条書き表示
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(advices.prefix(2), id: \.id) { advice in
                        Text("• " + advice.title.localized)
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.text)
                    }
                    // 免責事項
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

// ヘッダービュー
private var headerView: some View {
    ZStack {
        // 背景グラデーション
        Theme.Colors.primaryGradient
            .ignoresSafeArea(edges: .top)
        
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localizedAppName)
                        .font(Theme.Typography.headingFont)
                        .foregroundColor(.white)
                    
                    Text("home_subtitle".localized)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // 言語切り替えボタン
                Button(action: {
                    localizationManager.toggleLanguage()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.body)
                        Text("switch_language".localized)
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
                
                // 設定ボタン
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            if let latestRecord = validNormalRecords.first, !validNormalRecords.isEmpty {
                // 最新の通常睡眠サマリー
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("last_sleep".localized)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(latestRecord.durationText)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("sleep_score".localized)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(.white.opacity(0.8))

                            Text("\(Int(latestRecord.score))" + "points".localized)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 45)
        .padding(.bottom, 15)
    }
    .frame(height: 150)
} 