import UIKit
import SwiftUI


class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    var window: UIWindow?

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            // 将文本传递给 ContentView
            if let contentView = window?.rootViewController as? UIHostingController<ContentView> {
                contentView.rootView.sharedDishes = text.components(separatedBy: "\n")
            }
        } catch {
            print("读取分享内容时出错：\(error)")
        }
        return true
    }

}
