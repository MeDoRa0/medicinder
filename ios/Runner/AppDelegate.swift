import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureNotificationPermissions(application)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureNotificationPermissions(_ application: UIApplication) {
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.delegate = self

    notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        NSLog("Notification permission error: \(error.localizedDescription)")
        return
      }
      NSLog("Notification permission granted: \(granted)")
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    }
  }
}
