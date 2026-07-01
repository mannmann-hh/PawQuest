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

    if let controller = window?.rootViewController as? FlutterViewController {
      let watchChannel = FlutterMethodChannel(
        name: "pawquest/watch", binaryMessenger: controller.binaryMessenger)
      watchChannel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "updateContext",
           let args = call.arguments as? [String: Any] {
          let status = self?.sendToWatch(args) ?? ["supported": false]
          result(status)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    if WCSession.isSupported() {
      let session = WCSession.default
      session.delegate = self
      session.activate()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func sendToWatch(_ data: [String: Any]) -> [String: Any] {
    guard WCSession.isSupported() else { return ["supported": false] }
    let session = WCSession.default
    var status: [String: Any] = [
      "supported": true,
      "activation": session.activationState.rawValue,
      "paired": session.isPaired,
      "watchAppInstalled": session.isWatchAppInstalled,
      "reachable": session.isReachable
    ]
    guard session.activationState == .activated else {
      status["sent"] = false
      return status
    }
    do {
      try session.updateApplicationContext(data)
      status["appContext"] = "ok"
    } catch {
      status["appContext"] = "failed: \(error.localizedDescription)"
    }
    if session.isReachable {
      session.sendMessage(data, replyHandler: nil, errorHandler: nil)
      status["message"] = "sent"
    } else {
      status["message"] = "not reachable"
    }
    return status
  }

  func session(_ session: WCSession,
               activationDidCompleteWith activationState: WCSessionActivationState,
               error: Error?) {}
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }
}
