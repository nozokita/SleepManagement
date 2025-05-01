//
//  SleepManagementApp.swift
//  SleepManagement
//
//  Created by Nozomu Kitamura on 4/20/25.
//

import SwiftUI
import CoreData
import UIKit

// アプリの状態を管理するクラス
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
            print("AppState: オンボーディング完了状態を変更: \(hasCompletedOnboarding)")
        }
    }
    
    init() {
        // UserDefaultsから初期化
        // デバッグ用：オンボーディング状態をリセットする場合はコメントを外す
        // UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        print("AppState: 初期化 - オンボーディング完了状態: \(hasCompletedOnboarding)")
    }
    
    func completeOnboarding() {
        print("AppState: オンボーディング完了処理を開始")
        
        // 同期的に更新
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // UIの更新のためにメインスレッドで確実に更新
        DispatchQueue.main.async {
            self.hasCompletedOnboarding = true
            print("AppState: オンボーディング完了状態を更新しました: \(self.hasCompletedOnboarding)")
        }
    }
    
    // 開発用：オンボーディングをリセット
    func resetOnboarding() {
        hasCompletedOnboarding = false
        print("AppState: オンボーディング状態をリセット")
    }
}

@main
struct SleepManagementApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // アプリの状態を管理
    @StateObject private var appState = AppState()
    // ユーザー設定管理
    @StateObject private var settingsManager = SettingsManager.shared
    
    // 開発用：強制的にオンボーディングを表示するフラグ
    private let forceOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if !appState.hasCompletedOnboarding || forceOnboarding {
                    OnboardingNavigationView()
                } else {
                    ContentView()
                }
            }
            // 設定トグルで変更があったら即時 overrideUserInterfaceStyle を反映
            .onChange(of: settingsManager.darkModeEnabled) { value in
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let win = scene.windows.first {
                    win.overrideUserInterfaceStyle = value ? .dark : .light
                }
            }
            // ユーザー設定に基づくカラースキーム切り替え
            .preferredColorScheme(settingsManager.darkModeEnabled ? .dark : .light)
            // グローバルな環境設定
            .environmentObject(appState)
            .environmentObject(localizationManager)
            .environmentObject(settingsManager)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environment(\.locale, Locale(identifier: localizationManager.currentLanguage))
        }
    }
}

// Core Data永続コントローラー
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SleepManagementModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
