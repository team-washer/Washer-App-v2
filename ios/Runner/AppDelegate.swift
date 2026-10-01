import Flutter
import UIKit

// TODO(#251): Remove this native APNs diagnostic bridge after the iOS token
// registration issue is verified on TestFlight. It never stores token bytes.
private final class ApnsDiagnosticStore {
  static let shared = ApnsDiagnosticStore()

  private let callbackTimeout: TimeInterval = 15
  private let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private var registerCallCount = 0
  private var lastRegisterCallAt: Date?
  private var callbackStatus = "not_started"
  private var successCallbackCount = 0
  private var failureCallbackCount = 0
  private var callbackTimeoutCount = 0
  private var lastSuccessCallbackAt: Date?
  private var lastFailureCallbackAt: Date?
  private var lastCallbackTimeoutAt: Date?
  private var deviceTokenLength: Int?
  private var errorDomain: String?
  private var errorCode: Int?
  private var errorDescription: String?
  private var timeoutGeneration = 0

  private init() {}

  func registerForRemoteNotifications(_ application: UIApplication) -> [String: Any] {
    dispatchPrecondition(condition: .onQueue(.main))

    registerCallCount += 1
    lastRegisterCallAt = Date()

    let alreadyWaiting = callbackStatus == "waiting"
    let alreadyRegistered = callbackStatus == "success"
      && application.isRegisteredForRemoteNotifications
    if !alreadyWaiting && !alreadyRegistered {
      callbackStatus = "waiting"
      scheduleCallbackTimeout()
    }

    application.registerForRemoteNotifications()
    return snapshot(application)
  }

  func recordRegistrationSuccess(
    _ application: UIApplication,
    deviceTokenLength: Int
  ) {
    dispatchPrecondition(condition: .onQueue(.main))
    invalidateCallbackTimeout()
    callbackStatus = "success"
    successCallbackCount += 1
    lastSuccessCallbackAt = Date()
    self.deviceTokenLength = deviceTokenLength
    errorDomain = nil
    errorCode = nil
    errorDescription = nil
  }

  func recordRegistrationFailure(
    _ application: UIApplication,
    error: NSError
  ) {
    dispatchPrecondition(condition: .onQueue(.main))
    invalidateCallbackTimeout()
    callbackStatus = "failure"
    failureCallbackCount += 1
    lastFailureCallbackAt = Date()
    deviceTokenLength = nil
    errorDomain = error.domain
    errorCode = error.code
    errorDescription = error.localizedDescription
  }

  func snapshot(_ application: UIApplication) -> [String: Any] {
    dispatchPrecondition(condition: .onQueue(.main))
    return [
      "available": true,
      "firebaseAppDelegateProxyEnabled": isFirebaseAppDelegateProxyEnabled,
      "registerForRemoteNotificationsCallCount": registerCallCount,
      "lastRegisterForRemoteNotificationsCallAt": value(lastRegisterCallAt),
      "isRegisteredForRemoteNotifications": application.isRegisteredForRemoteNotifications,
      "callbackStatus": callbackStatus,
      "didRegisterCallbackCount": successCallbackCount,
      "didFailCallbackCount": failureCallbackCount,
      "callbackTimeoutCount": callbackTimeoutCount,
      "lastDidRegisterCallbackAt": value(lastSuccessCallbackAt),
      "lastDidFailCallbackAt": value(lastFailureCallbackAt),
      "lastCallbackTimeoutAt": value(lastCallbackTimeoutAt),
      "deviceTokenLength": deviceTokenLength ?? NSNull(),
      "errorDomain": errorDomain ?? NSNull(),
      "errorCode": errorCode ?? NSNull(),
      "errorDescription": errorDescription ?? NSNull(),
      "applicationState": applicationStateName(application.applicationState),
    ]
  }

  private var isFirebaseAppDelegateProxyEnabled: Bool {
    guard let value = Bundle.main.object(
      forInfoDictionaryKey: "FirebaseAppDelegateProxyEnabled"
    ) else {
      return true
    }
    if let boolean = value as? Bool {
      return boolean
    }
    if let number = value as? NSNumber {
      return number.boolValue
    }
    return true
  }

  private func scheduleCallbackTimeout() {
    timeoutGeneration += 1
    let generation = timeoutGeneration
    DispatchQueue.main.asyncAfter(deadline: .now() + callbackTimeout) { [weak self] in
      guard let self,
            self.timeoutGeneration == generation,
            self.callbackStatus == "waiting" else {
        return
      }
      self.callbackStatus = "timeout"
      self.callbackTimeoutCount += 1
      self.lastCallbackTimeoutAt = Date()
    }
  }

  private func invalidateCallbackTimeout() {
    timeoutGeneration += 1
  }

  private func value(_ date: Date?) -> Any {
    guard let date else { return NSNull() }
    return dateFormatter.string(from: date)
  }

  private func applicationStateName(_ state: UIApplication.State) -> String {
    switch state {
    case .active:
      return "active"
    case .inactive:
      return "inactive"
    case .background:
      return "background"
    @unknown default:
      return "unknown"
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsDiagnosticChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "washer/apns-diagnostics",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      DispatchQueue.main.async {
        let application = UIApplication.shared
        switch call.method {
        case "registerForRemoteNotifications":
          result(
            ApnsDiagnosticStore.shared.registerForRemoteNotifications(application)
          )
        case "getSnapshot":
          result(ApnsDiagnosticStore.shared.snapshot(application))
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    apnsDiagnosticChannel = channel
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    ApnsDiagnosticStore.shared.recordRegistrationSuccess(
      application,
      deviceTokenLength: deviceToken.count
    )

    // FlutterAppDelegate forwards this callback to firebase_messaging. Keep
    // this call so Firebase's APNs-token association and method swizzling work.
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    ApnsDiagnosticStore.shared.recordRegistrationFailure(
      application,
      error: error as NSError
    )

    // Preserve FlutterFire's existing application-delegate forwarding.
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }
}
