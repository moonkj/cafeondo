import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Google Maps SDK before Flutter plugin registration
    GMSServices.provideAPIKey("AIzaSyDvlYk7df6J7Kvhgy1bUB4hAIETSi4lC5w")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
