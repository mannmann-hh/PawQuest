import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Platform channel used by Flutter (WatchService) to push state to the watch.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "pawquest/watch",
        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "updateContext",
           let args = call.arguments as? [String: Any] {
          self?.sendToWatch(args)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Activate the WatchConnectivity session.
    if WCSession.isSupported() {
      let session = WCSession.default
      session.delegate = self
      session.activate()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func sendToWatch(_ data: [String: Any]) {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated else { return }
    do {
      try session.updateApplicationContext(data)
    } catch {
      NSLog("PawQuest: updateApplicationContext failed: \(error.localizedDescription)")
    }
  }

  // MARK: - WCSessionDelegate (required stubs)
  func session(_ session: WCSession,
               activationDidCompleteWith activationState: WCSessionActivationState,
               error: Error?) {}
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }
}
