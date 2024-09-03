import UIKit
import Flutter
import BrazeKit
import braze_plugin

let brazeApiKey = "9292484d-3b10-4e67-971d-ff0c0d518e21"
let brazeEndpoint = "sondheim.braze.com"

@UIApplicationMain
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
    
    // Push Auto
    configuration.push.automation = true
    let braze = BrazePlugin.initBraze(configuration)
    AppDelegate.braze = braze

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
}
