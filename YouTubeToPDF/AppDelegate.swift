import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - App Lifecycle Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Request notification permission
        requestNotificationPermission()
        
        // Configure push notifications
        configurePushNotifications(application)
        
        // Register for background fetch (this is important for background polling)
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }

    // MARK: - Push Notification Setup & Handling
    
    func configurePushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Handling Background Fetch
    
    // This method is called when background fetch is triggered by the system
    // Inside AppDelegate.swift

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Retrieve the executionId from UserDefaults
        if let executionId = UserDefaults.standard.string(forKey: "currentExecutionId") {
            let startTime = Date()
            
            // We will invoke the polling function from ViewController, if it's available
            if let viewController = window?.rootViewController as? ViewController {
                viewController.pollForResultInBackground(executionId: executionId, startTime: startTime)
            }
            
            completionHandler(.newData)
        } else {
            print("No executionId found in UserDefaults")
            completionHandler(.noData)
        }
    }
    
    // MARK: - Background Task Registration
    
    func beginBackgroundTask() {
        // Start a background task to keep the app running in the background while polling
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            // Handle task expiration (e.g., the system stops your task because it's running too long)
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = .invalid
        })
    }
    
    func endBackgroundTask() {
        // End the background task after polling is done
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    // MARK: - Push Notification Handling
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle push notification received
        print("Received remote notification: \(userInfo)")
        
        // Example: If we get a failure message, we show an alert in the app
        if let error = userInfo["error"] as? String, error == "true" {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Download Failed", message: "Something went wrong while processing your request. Please try again later.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.window?.rootViewController?.present(alert, animated: true)
            }
        }
        
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Send the device token to your server for push notification registration
        print("Successfully registered for push notifications with device token: \(deviceToken)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Handle failure to register for push notifications
        print("Failed to register for push notifications: \(error)")
    }

    // MARK: - App State Handling
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Handle app going into inactive state
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Handle app going into the background
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Handle app coming into the foreground
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Handle app becoming active
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Handle app termination
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    // Called when the user taps on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the user tapping on the notification
        let userInfo = response.notification.request.content.userInfo
        
        if let error = userInfo["error"] as? String, error == "true" {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Download Failed", message: "Something went wrong while processing your request. Please try again later.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.window?.rootViewController?.present(alert, animated: true)
            }
        }
        
        completionHandler()
    }
}
