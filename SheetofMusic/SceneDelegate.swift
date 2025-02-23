//
//  SceneDelegate.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 1/6/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var tabBarController: UITabBarController?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
                
        window = UIWindow(windowScene: windowScene)
        
        // Initialize the root view controller, which is the TabBarController
        let exploreVC = ExploreViewController() // Replace with your actual view controller
        let generateVC = GenerateViewController() // Replace with your actual view controller
        let recordVC = RecordViewController() // Your RecordViewController
        
        exploreVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "house.fill"), tag: 0)
        generateVC.tabBarItem = UITabBarItem(title: "Generate", image: UIImage(systemName: "doc.text"), tag: 1)
        recordVC.tabBarItem = UITabBarItem(title: "Record", image: UIImage(systemName: "mic.fill"), tag: 2)
        
        // Embed each of them in a UINavigationController
        let exploreNavVC = UINavigationController(rootViewController: exploreVC)
        let generateNavVC = UINavigationController(rootViewController: generateVC)
        let recordNavVC = UINavigationController(rootViewController: recordVC)
        
        // Create a Tab Bar Controller
        tabBarController = UITabBarController()
        tabBarController?.viewControllers = [exploreNavVC, generateNavVC, recordNavVC]

        
        // Set the root view controller to the tab bar controller
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationTap(_:)), name: .didTapNotification, object: nil)
        
        // Handle launching from notification
        if let notificationResponse = connectionOptions.notificationResponse {
            NotificationCenter.default.post(name: .didTapNotification, object: notificationResponse, userInfo: notificationResponse.notification.request.content.userInfo)
        }
    }

    // Open the PDF when the notification is tapped
    @objc func handleNotificationTap(_ notification: Notification) {
        
        // Prioritize userInfo since it's populated reliably
        if let userInfo = notification.userInfo,
          let pdfURLString = userInfo["url"] as? String {
            
            guard let tabBarController = tabBarController else {
                print("No tabBarController found")
                return
            }

            // Switch to the Explore tab
            tabBarController.selectedIndex = 0
            
            // Ensure ExploreViewController is visible
            guard let navController = tabBarController.selectedViewController as? UINavigationController
            else {
                print("selected view controller not found")
                return
            }

            guard let  exploreVC = navController.topViewController as? ExploreViewController else {
                print("ExploreViewController is not visible after switching tabs")
                return
            }
            
            // Wait a moment to ensure ExploreViewController has loaded before opening the PDF
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Open the PDF in ExploreViewController
                exploreVC.openPDF(pdfURLString)
            }
            
        } else {
            print("No PDF URL found in notification")
        }
    }
   
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

