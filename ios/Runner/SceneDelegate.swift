import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    window = UIWindow(windowScene: windowScene)
    let flutterViewController = UIStoryboard(name: "Main", bundle: nil)
      .instantiateInitialViewController() as! FlutterViewController
    window?.rootViewController = flutterViewController
    window?.makeKeyAndVisible()

    // With UIScene lifecycle the FlutterEngine is created here, not in
    // AppDelegate.didFinishLaunchingWithOptions. Register plugins against
    // the scene's engine so platform channels (e.g. path_provider) work.
    GeneratedPluginRegistrant.register(with: flutterViewController)

    if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate {
      appDelegate.window = window
    }
  }
}
