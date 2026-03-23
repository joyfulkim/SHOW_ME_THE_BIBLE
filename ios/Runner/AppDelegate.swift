import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var secureTextField: UITextField?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "show_me_bible/security",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "enableSecureMode":
        self?.enableSecureMode()
        result(nil)
      case "disableSecureMode":
        self?.disableSecureMode()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // 앱 시작 시 캡처 방지 즉시 활성화 (개발 단계에서는 비활성화)
    /*
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.enableSecureMode()
    }
    */
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // iOS 캡처 방지: 보안 텍스트 필드를 윈도우에 삽입
  private func enableSecureMode() {
    guard secureTextField == nil else { return }
    let tf = UITextField()
    tf.isSecureTextEntry = true
    tf.isUserInteractionEnabled = false
    tf.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    window?.addSubview(tf)
    window?.layer.superlayer?.addSublayer(tf.layer)
    tf.layer.sublayers?.first?.addSublayer(window!.layer)
    secureTextField = tf
  }
  
  private func disableSecureMode() {
    secureTextField?.removeFromSuperview()
    secureTextField = nil
  }
}
