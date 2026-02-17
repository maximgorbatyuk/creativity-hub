import SwiftUI
import UserNotifications
import os

#if !DEBUG
import FirebaseCore
#endif

@main
struct CreativityHubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var colorScheme: AppColorScheme = .system

    private var analytics = AnalyticsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationManager)
                .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))
                .preferredColorScheme(colorScheme.colorScheme)
                .onAppear {
                    analytics.trackEvent("app_opened")
                    colorScheme = DatabaseManager.shared.userSettingsRepository?.fetchColorScheme() ?? .system
                }
                .onReceive(NotificationCenter.default.publisher(for: .appColorSchemeDidChange)) { notification in
                    guard
                        let rawValue = notification.userInfo?["colorScheme"] as? String,
                        let scheme = AppColorScheme(rawValue: rawValue)
                    else {
                        return
                    }

                    colorScheme = scheme
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "AppDelegate"
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        #if DEBUG
        logger.info("DEBUG: Firebase configuration skipped")
        #else
        FirebaseApp.configure()
        #endif

        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completion([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completion: @escaping () -> Void
    ) {
        completion()
    }
}
