import UIKit
import UserNotifications

extension Notification.Name {
    static let didFinishDownloading = Notification.Name("didFinishDownloading")
    static let didTapNotification = Notification.Name("didTapNotification")
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    var deviceToken: String?
    
    
    // MARK: - App Lifecycle Methods
    
    // This method is triggered if the app is launched due to a notification while in the foreground.
    // If the app is completely closed and launched from a notification, this method is called
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        return true
    }

    
    // MARK: - Push Notification Handling
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("Device token: \(tokenString)")
        
        self.deviceToken = tokenString
        
        // Now you can send this token to your server (AWS Lambda)
        
        // Optioanal: Store it in UserDefaults to persist across app launches
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    
    // This method is triggered when a notification is received while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in foreground: \(notification.request.content.body)")
        
        // Extract the URL from the notification's userInfo and call the appropriate method in your view controller
        if let url = notification.request.content.userInfo["presigned_url"] as? String {
            // Post the notification to the ViewController
            NotificationCenter.default.post(name: .didFinishDownloading, object: nil, userInfo: ["url": url])
        }

        completionHandler([.alert, .sound])
    }
    
    // This method is called when the app receives a remote notification in the background or when the app is closed.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Notification received in background")
        if let url = userInfo["presigned_url"] as? String {
            // Post a notification to update the UI
            NotificationCenter.default.post(name: .didFinishDownloading, object: nil, userInfo: ["url": url])
        }
        completionHandler(.newData)
    }


    // This method is triggered when the user taps on a notification regardless of where app is
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Example of saving the URL in UserDefaults (or AppState)
            if let url = response.notification.request.content.userInfo["presigned_url"] as? String {
                NotificationCenter.default.post(name: .didTapNotification, object: nil, userInfo: ["url": url])
            }
        
        completionHandler()
    }

}


