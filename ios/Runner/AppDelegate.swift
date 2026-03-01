import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDvlYk7df6J7Kvhgy1bUB4hAIETSi4lC5w")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
