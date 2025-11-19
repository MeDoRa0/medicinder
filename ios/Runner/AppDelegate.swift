import UIKit
import Flutter
import UserNotifications
import awesome_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Initialize Awesome Notifications
    AwesomeNotifications().initialize(
      nil,
      [
        "channelKey": "basic_channel",
        "channelName": "Basic notifications",
        "channelDescription": "Notification tests"
      ]
    )

    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
