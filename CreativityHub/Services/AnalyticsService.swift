import FirebaseAnalytics
import Foundation
import os
import UIKit

/// Service for tracking analytics events using Firebase Analytics.
/// Analytics are only active in Release builds - DEBUG builds log locally only.
final class AnalyticsService: Sendable {

  static let shared = AnalyticsService()

  /// Cached global properties - using nonisolated(unsafe) for singleton pattern with Swift 6 concurrency
  nonisolated(unsafe) private var _globalProps: [String: Any]? = nil

  /// Session identifier - immutable after initialization
  private let _sessionId = UUID().uuidString

  /// Persistent user identifier from SQLite
  nonisolated(unsafe) private var _userId: String?

  let logger: Logger

  init() {
    self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "Analytics")
    self.initializeUserId()
  }

  /// Track a custom event with optional properties.
  /// - Parameters:
  ///   - name: The event name (e.g., "button_tapped", "feature_used")
  ///   - properties: Optional dictionary of event properties
  func trackEvent(_ name: String, properties: [String: Any]? = nil) {
    let mergedParams = mergeProperties(properties)

    #if DEBUG
    logger.info("Analytics Event: \(name), properties: \(String(describing: mergedParams))")
    #else
    Analytics.logEvent(name, parameters: mergedParams)
    #endif
  }

  /// Identify the current user for analytics tracking.
  /// - Parameters:
  ///   - userId: Unique user identifier
  ///   - properties: Optional user properties to set
  func identifyUser(_ userId: String, properties: [String: Any]? = nil) {
    #if DEBUG
    logger.info("Analytics Identify User: \(userId), properties: \(String(describing: properties))")
    #else
    Analytics.setUserID(userId)
    properties?.forEach { key, value in
      Analytics.setUserProperty(String(describing: value), forName: key)
    }
    #endif
  }

  /// Track a screen view event.
  /// - Parameters:
  ///   - screenName: The name of the screen being viewed
  ///   - properties: Optional additional properties
  func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
    var mergedParams = mergeProperties(properties)
    mergedParams[AnalyticsParameterScreenName] = screenName
    mergedParams[AnalyticsParameterScreenClass] = screenName

    #if DEBUG
    logger.info("Analytics Screen View: \(screenName), properties: \(String(describing: mergedParams))")
    #else
    Analytics.logEvent(AnalyticsEventScreenView, parameters: mergedParams)
    #endif
  }

  /// Track a button tap event with screen context.
  /// - Parameters:
  ///   - buttonName: The name/identifier of the button
  ///   - screen: The screen where the button was tapped
  ///   - additionalParams: Optional additional properties
  func trackButtonTap(_ buttonName: String, screen: String, additionalParams: [String: Any]? = nil) {
    var params: [String: Any] = [
      "button_name": buttonName,
      "screen": screen
    ]

    params.merge(additionalParams ?? [:]) { _, new in new }

    trackEvent("button_tapped", properties: params)
  }

  /// Track an error event.
  /// - Parameters:
  ///   - error: The error that occurred
  ///   - context: Additional context about where the error occurred
  func trackError(_ error: Error, context: String) {
    trackEvent("error_occurred", properties: [
      "error_message": error.localizedDescription,
      "error_context": context
    ])
  }

  // MARK: - Private

  private func initializeUserId() {
    if let repo = DatabaseManager.shared.userSettingsRepository {
      self._userId = repo.fetchOrGenerateUserId()
      logger.info("Initialized user_id: \(self._userId ?? "nil")")
    }
  }

  private func mergeProperties(_ parameters: [String: Any]?) -> [String: Any] {
    var merged = getGlobalProperties()

    if let params = parameters {
      merged.merge(params) { _, new in new }
    }

    return merged
  }

  private func getGlobalProperties() -> [String: Any] {
    if let props = _globalProps {
      return props
    }

    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

    _globalProps = [
      "session_id": _sessionId,
      "app_version": "\(version) (\(build))",
      "platform": "iOS",
      "os_version": UIDevice.current.systemVersion
    ]

    if let userId = _userId {
      _globalProps!["user_id"] = userId
    }

    guard let props = _globalProps else { return [:] }
    return props
  }
}
