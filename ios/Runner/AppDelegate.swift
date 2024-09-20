import UIKit
import Flutter
import BrazeKit
import BrazeUI
import braze_plugin

let brazeApiKey = "< removed >"
let brazeEndpoint = "< removed >"

@main
@objc class AppDelegate: FlutterAppDelegate {

  static var braze: Braze? = nil
  var pushEventsSubscription: Braze.Cancellable?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup Braze
    let configuration = Braze.Configuration(
      apiKey: brazeApiKey,
      endpoint: brazeEndpoint
    )
    // - Enable logging or customize configuration here
    configuration.logger.level = .info
    configuration.triggerMinimumTimeInterval = 1
    
//    // Disable Push Automation which uses swizzling
//    configuration.push.automation = true

    let braze = BrazePlugin.initBraze(configuration)
    AppDelegate.braze = braze

    // IAM UI
    let inAppMessageUI = BrazeInAppMessageUI()
    braze.inAppMessagePresenter = inAppMessageUI

    // Push notifications support
    application.registerForRemoteNotifications()
    let center = UNUserNotificationCenter.current()
    center.setNotificationCategories(Braze.Notifications.categories)
    center.delegate = self
    center.requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
      print("Notification authorization, granted: \(granted), error: \(String(describing: error))")
    }

    pushEventsSubscription = braze.notifications.subscribeToUpdates(payloadTypes: [.opened, .received]) { payload in
      print("""
      => [Push Event Subscription] Received push event: \(payload)
        - type: \(payload.type)
        - title: \(payload.title ?? "<empty>")
        - isSilent: \(payload.isSilent)
      """)
      BrazePlugin.processPushEvent(payload)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Push Notification support

  // - Register the device token with Braze

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    AppDelegate.braze?.notifications.register(deviceToken: deviceToken)
  }

  // - Add support for silent notification

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if let braze = AppDelegate.braze,
      braze.notifications.handleBackgroundNotification(
        userInfo: userInfo,
        fetchCompletionHandler: completionHandler
      )
    {
      return
    }
    completionHandler(.noData)
  }

  // - Add support for push notifications

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let braze = AppDelegate.braze,
      braze.notifications.handleUserNotification(
        response: response,
        withCompletionHandler: completionHandler
      )
    {
      return
    }
    completionHandler()
  }

  // - Add support for displaying push notification when the app is currently running in the
  //   foreground

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let braze = AppDelegate.braze {
      braze.notifications.handleForegroundNotification(notification: notification)
    }

    if #available(iOS 14, *) {
      completionHandler([.list, .banner])
    } else {
      completionHandler(.alert)
    }
  }

}
