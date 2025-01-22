import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var youtubeUrlTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    // API URLs
    let apiGatewayUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/convert"
    let pollingUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/status"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe the custom notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadFinished(_:)), name: .didFinishDownloading, object: nil)
    }
    
    // Handle the custom notification and update the UI
   @objc func handleDownloadFinished(_ notification: Notification) {
       // Retrieve the URL from the notification's userInfo
       if let userInfo = notification.userInfo, let url = userInfo["url"] as? String {
           // Update the UI or show the download popup
           showDownloadPopup(url: url)
       }
   }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show the popup if the flag is set
        showPopupIfNeeded()
    }

    func showPopupIfNeeded() {
        if AppState.shared.shouldShowPopup, let url = AppState.shared.downloadURL {
            showDownloadPopup(url: url)
            AppState.shared.shouldShowPopup = false // Reset after showing the popup
        }
    }
    
    // This method is called when the app is about to enter the foreground
    @objc func appWillEnterForeground() {
        // Trigger the UI update or perform actions that should happen when the app returns to the foreground
        print("App entered foreground - UI should be updated")
        // Update your UI or perform any necessary actions here
    }
    
    // Unregister when the view controller goes away
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let youtubeUrl = youtubeUrlTextField.text, !youtubeUrl.isEmpty else {
            print("YouTube URL is empty")
            return
        }
        
        // Disable the button to prevent multiple submissions
        submitButton.isEnabled = false
        
        // Trigger the API call to start the process
        submitYouTubeUrl(youtubeUrl)
    }
    
    func submitYouTubeUrl(_ youtubeUrl: String) {
        // Trigger the Step Function via API Gateway
        triggerStepFunction(youtubeUrl: youtubeUrl)
    }
    
    func triggerStepFunction(youtubeUrl: String) {
        self.pollForResult(executionId: "abc", startTime: Date())
    }
    
    func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            // Re-enable the submit button if error occurs
            self.submitButton.isEnabled = true
            
            // Create the alert
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Add the "OK" action to dismiss the alert
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Present the alert
            self.present(alert, animated: true)
        }
    }
    
    func sendLocalNotification(url: String) {
        print("Inside sendLocalNotification")

        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "Your PDF is ready. Tap to view it."
        content.userInfo = ["presigned_url": url]  // Attach URL in userInfo

        // Set the trigger to fire immediately (1 second)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: "downloadComplete", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

    
    func showDownloadPopup(url: String) {
        print("inside showDownloadPopup")
        
        // Create the alert controller
        let alert = UIAlertController(title: "Download Complete", message: "Your PDF is ready. Tap below to view it.", preferredStyle: .alert)
        
        // Action to open the PDF
        let downloadAction = UIAlertAction(title: "View PDF", style: .default) { _ in
            // Re-enable the submit button when the user taps "View PDF"
            self.submitButton.isEnabled = true
            
            self.openPDF(url)  // Call the openPDF function to open the URL
        }
        
        // Action to dismiss the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Re-enable the submit button when the user taps "Cancel"
            self.submitButton.isEnabled = true
        }
        
        // Add actions to the alert
        alert.addAction(downloadAction)
        alert.addAction(cancelAction)
        
        // Present the alert controller
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    


    /*
     Retry for up to 15 minutes. We'll keep track of the time elapsed and ensure we don't keep retrying past 15 minutes.
     Stop retrying if the status code is not 200. We'll check if the response status code is not 200, and then stop the retries.
     If the response is valid (status 200), proceed with extracting the presigned_url and open the PDF.
     */
    func pollForResult(executionId: String, startTime: Date, timeOutInterval: Double = 900) {
        let url = "https://www.adobe.com/content/dam/cc/en/legal/terms/enterprise/pdfs/GeneralTerms-NA-2024v1.pdf"
        
        UserDefaults.standard.set(url, forKey: "downloadURL")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Code to run after 3 seconds
            print("This code runs after a 3-second delay.")
            self.sendLocalNotification(url: url)
        }
    }
    
    func openPDF(_ url: String) {
        // Use Safari or WebView to open the presigned URL
        if let url = URL(string: url) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
}
