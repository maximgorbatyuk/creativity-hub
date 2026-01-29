//
//  CreativeHubApp.swift
//  CreativeHub
//
//  Created by Maxim Gorbatyuk on 25.01.2026.
//

import SwiftUI
import UserNotifications

#if !DEBUG
import FirebaseCore
#endif

@main
struct CreativeHubApp: App {

  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  private var analytics = AnalyticsService.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          analytics.trackEvent("app_opened")
        }
    }
  }
}

/// App delegate for handling application lifecycle events and Firebase initialization.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {

    // Set up notification delegate
    UNUserNotificationCenter.current().delegate = self

    // Only configure Firebase in Release builds
    // DEBUG builds skip Firebase to avoid requiring GoogleService-Info.plist during development
    #if DEBUG
    // Skip Firebase in debug
    print("DEBUG: Firebase configuration skipped")
    #else
    FirebaseApp.configure()
    #endif

    return true
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Handle notifications when app is in foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show banner, list, and play sound even when app is in foreground
    completion([.banner, .list, .sound])
  }

  /// Handle notification response (user tapped on notification)
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completion: @escaping () -> Void
  ) {
    // Handle notification tap here
    // TODO: Add deep linking or navigation based on notification content
    completion()
  }
}
