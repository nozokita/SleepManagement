import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            Bundle.setLanguage(currentLanguage)
            NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
        }
    }
    
    init() {
        // 保存されている言語設定を取得、なければデバイス言語を使用
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language") {
            self.currentLanguage = savedLanguage
        } else {
            // デバイスの言語が日本語なら日本語、それ以外は英語をデフォルトとする
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            self.currentLanguage = preferredLanguage.starts(with: "ja") ? "ja" : "en"
            
            // 初期値を保存
            UserDefaults.standard.set(self.currentLanguage, forKey: "app_language")
        }
        
        // 現在の言語を設定
        Bundle.setLanguage(currentLanguage)
    }
    
    func toggleLanguage() {
        // 日本語と英語を切り替え
        currentLanguage = (currentLanguage == "ja") ? "en" : "ja"
    }
    
    // アプリ名を現在の言語で取得
    var localizedAppName: String {
        return "app_name".localized
    }
}

// Bundleの拡張
extension Bundle {
    private static var bundle: Bundle?
    
    static func setLanguage(_ language: String) {
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? Bundle.main.path(forResource: "en", ofType: "lproj")!
        bundle = Bundle(path: path)
    }
    
    static var localized: Bundle {
        return bundle ?? Bundle.main
    }
}

// 文字列の拡張
extension String {
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.localized, comment: "")
    }
} 