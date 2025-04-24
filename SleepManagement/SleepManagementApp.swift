//
//  SleepManagementApp.swift
//  SleepManagement
//
//  Created by Nozomu Kitamura on 4/20/25.
//

import SwiftUI
import CoreData

// アプリの状態を管理するクラス
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    init() {
        // UserDefaultsから初期化
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

@main
struct SleepManagementApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // アプリの状態を管理
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if !appState.hasCompletedOnboarding {
                // 初回起動時のオンボーディングフロー
                OnboardingNavigationView()
                    .environmentObject(appState)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(localizationManager)
            } else {
                // 通常起動時のメインフロー
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(localizationManager)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                        // 言語変更通知を受け取った時の処理（必要に応じて）
                    }
            }
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
