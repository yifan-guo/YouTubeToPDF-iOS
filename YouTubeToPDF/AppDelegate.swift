import UIKit
import UserNotifications

extension Notification.Name {
    static let didFinishDownloading = Notification.Name("didFinishDownloading")
}


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // When the app is in the foreground, you can handle the notification here
        print("Notification received in foreground: \(notification.request.content.body)")
        completionHandler([.alert, .sound])
    }
    

    // Handle notification tap (app launch from a notification)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification clicked: \(response.notification.request.content.body)")

        // Example of saving the URL in UserDefaults (or AppState)
        if let userInfo = response.notification.request.content.userInfo as? [String: Any],
           let url = userInfo["presigned_url"] as? String {
            UserDefaults.standard.set(url, forKey: "downloadURL")
            
            // Post a notification to update the UI
            NotificationCenter.default.post(name: .didFinishDownloading, object: nil, userInfo: ["url": url])
        }
        
        completionHandler()
    }
}
