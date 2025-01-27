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
    
    func openPDF(_ url: String) {
        // Use Safari or WebView to open the presigned URL
        if let url = URL(string: url) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }

    
   let errorUserInfo = ["error": "true"]
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let youtubeUrl = youtubeUrlTextField.text, !youtubeUrl.isEmpty else {
            print("YouTube URL is empty")
            return
        }
        
        guard let deviceToken = (UIApplication.shared.delegate as? AppDelegate)?.deviceToken else {
            print("Device token not aavilable")
            return
        }
        
        // Disable the button to prevent multiple submissions
        submitButton.isEnabled = false
        
    
        // Trigger the API call to start the process
        triggerStepFunction(youtubeURL: youtubeUrl, deviceToken: deviceToken)
    }
    
    
    // Trigger the Step Function via API Gateway
    func triggerStepFunction(youtubeURL: String, deviceToken: String) {
        guard let url = URL(string: apiGatewayUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add body with YouTube URL or other required parameters
        let requestBody: [String: Any] = ["youtube_url": youtubeURL, "deviceToken": deviceToken]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [.withoutEscapingSlashes])
            print("Request URL: \(url)")
            print("Request Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            request.httpBody = jsonData
        } catch {
            print("Error encoding request body: \(error)")
            return
        }
        
        // Set headers if needed (authentication, content type, etc.)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error invoking Step Function: \(error)")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if error occurs
                }
                return
            }
            
            // Log the response
            if let response = response as? HTTPURLResponse {
                print("Response Status Code: \(response.statusCode)")
                print("Response Headers: \(response.allHeaderFields)")
                
                if response.statusCode == 400, let data = data {
                    // Log the body of the error response
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("Error Body: \(errorBody)")
                    }
                }
            }
        
            guard let data = data else {
                print("No data received from Step Function")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if no data
                }
                return
            }
            
            do {
                // Parse the response to extract the execution ID or task status
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let statusCode = responseDict["statusCode"] as? Int {
                        if statusCode == 202 {
                            if let body = responseDict["body"] as? String,
                               let jsonData = body.data(using: .utf8),
                               let bodyDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let executionId = bodyDict["job_id"] as? String {
                                // Store the execution ID for polling the status later
                                print("Step Function triggered successfully. Job ID: \(executionId). Polling for result")
                                
                                // Save the executionId in UserDefaults
                                UserDefaults.standard.set(executionId, forKey: "currentExecutionId")
                            }
                        } else {
                            // Handle non-202 status codes
                            print("Error: Received status code \(statusCode)")
                            self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                            return
                        }
                    } else {
                        // Handle missing statuscode
                        print("Error: Response is missing 'statusCode' attribute")
                        if let errorBody = String(data: data, encoding: .utf8) {
                            print("Response body: \(errorBody)")
                        }
                        self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                    }
                } else {
                    print("Unexpected response structure")
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("Response body: \(errorBody)")
                    }
                    self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                }
            } catch {
                print("Error parsing Step Function response: \(error)")
                self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
            }
        }
        
        task.resume()
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
    
//    /*
//     Retry for up to 15 minutes. We'll keep track of the time elapsed and ensure we don't keep retrying past 15 minutes.
//     Stop retrying if the status code is not 200. We'll check if the response status code is not 200, and then stop the retries.
//     If the response is valid (status 200), proceed with extracting the presigned_url and open the PDF.
//     */
//    func pollForResult(executionId: String, startTime: Date, timeOutInterval: Double = 900) {
//        print("inside pollForResult")
//        
//        // Poll for the result of the Step Function execution
//        guard let url = URL(string: "\(pollingUrl)/\(executionId)") else { return }
//        print ("url: \(url)")
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Perform the network request
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error polling for result: \(error)")
//                // Send push notification for polling error
//                self.notifyUserDownloadFailed(message: "An error occurred while polling for the PDF. Tap to try again.", userInfo: self.errorUserInfo)
//                return
//            }
//            
//            guard let data = data else {
//                print("No data received while polling")
//                // Send push notification for no data received
//                self.notifyUserDownloadFailed(message: "No data was received while polling for the PDF. Please try again.", userInfo: self.errorUserInfo)
//                return
//            }
//            
//            do {
//                // Parse the response to extract the status and the body
//                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    if let status = responseDict["status"] as? String {
//                        print("Polling status: \(status)")
//                        if status == "SUCCEEDED" {
//                            print("Polling finished successfully")
//                            print("responseDict: \(responseDict)")
//                            
//                            // Now, handle the nested 'output' key which contains a stringified JSON
//                            if let outputString = responseDict["output"] as? String {
//                                // Parse the stringified JSON in 'output'
//                                if let outputData = outputString.data(using: .utf8),
//                                   let outputDict = try? JSONSerialization.jsonObject(with: outputData, options: []) as? [String: Any] {
//                                    
//                                    // Extract the presigned_url from the parsed output JSON
//                                    if let body = outputDict["body"] as? String,
//                                       let bodyData = body.data(using: .utf8),
//                                       let bodyDict = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any],
//                                       let presignedUrl = bodyDict["presigned_url"] as? String {
//                                        print("Presigned URL received: \(presignedUrl)")
//                                        self.notifyUserDownloadComplete(presignedUrl)
//                                        return
//                                    } else {
//                                        print("Could not parse the 'body' field of SUCCESS response")
//                                        print("responseDict: \(responseDict)")
//                                        self.notifyUserDownloadFailed(message: "Could not parse the 'body' field of SUCCESS response", userInfo: self.errorUserInfo)
//                                        return
//                                    }
//                                } else {
//                                    print("Failed to parse 'output' JSON")
//                                    self.notifyUserDownloadFailed(message: "Failed to parse 'output' JSON", userInfo: self.errorUserInfo)
//                                    return
//                                }
//                            } else {
//                                print("'output' key missing or invalid")
//                                self.notifyUserDownloadFailed(message: "'output' key missing or invalid", userInfo: self.errorUserInfo)
//                                return
//                            }
//                        } else if status == "RUNNING" {
//                            // If it's still running, keep polling
//                            print("Step Function is still running. Retrying request to \(url)...")
//                        } else {
//                            // If the job status is unexpected, send a push notification and show the error alert
//                            print("Unexpected job status: \(status)")
//                            self.notifyUserDownloadFailed(message: "The job encountered an unexpected status: \(status) while processing your PDF. Please try again later.", userInfo: self.errorUserInfo)
//                            return
//                        }
//                    } else {
//                        print("Invalid response format: missing or invalid status. Retrying...")
//                        print("Response dict: \(responseDict)")
//                    }
//                } else {
//                    print("Unable to parse the response body. Retrying...")
//                    if let errorBody = String(data: data, encoding: .utf8) {
//                        print("Response Body: \(errorBody)")
//                    }
//                }
//                
//                // Check if 15 minutes (900 seconds) have passed
//                let elapsedTime = Date().timeIntervalSince(startTime)
//                if elapsedTime >= timeOutInterval {
//                    print("15 minutes have passed. Stopping polling.")
//                    // Send push notification for timeout
//                    self.notifyUserDownloadFailed(message: "The process took too long to complete. Please try again.", userInfo: self.errorUserInfo)
//                }
//        
//                // Poll again in 15 seconds if status is not complete
//                sleep(15)
//                self.pollForResult(executionId: executionId, startTime: startTime)
//            } catch {
//                print("Error parsing polling result: \(error)")
//                // Send push notification for unexpected error
//                self.notifyUserDownloadFailed(message: "An unexpected error occurred while polling for the PDF. Please try again.", userInfo: self.errorUserInfo)
//            }
//        }
//        
//        task.resume()
//    }
    
    func notifyUserDownloadComplete(_ url: String) {
        // This function should send a push notification to the user
        // using your server or Apple's Push Notification service (APNs)
        print("Download complete! Presigned URL: \(url)")
        
        // Store the presigned URL in UserDefaults so it can be accessed when the app is opened manually
        UserDefaults.standard.set(url, forKey: "downloadURL")
        
        print("abc")
        sleep(1)
        print("def")
        
        // Your code here to trigger a notification to the user
        self.sendLocalNotification(url: url)
    }
    
    

    func notifyUserDownloadFailed(message: String, userInfo: [String: String]) {
        // Send a notification when the download fails
        sendPushNotification(title: "Download Failed", message: "Something went wrong while processing your request. Please reopen the app to try again.", userInfo: userInfo)
        
        // Show error alert to the user once they reopen the app
        showErrorAlert(message: message)
    }

    func sendPushNotification(title: String, message: String, userInfo: [String: String]) {
        // Assuming you've already configured APNs in your app
        // Use UNUserNotificationCenter to schedule a local notification.
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // You can add userInfo for deep linking to the app if needed
        content.userInfo = userInfo

        // Trigger notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: "errorNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling push notification: \(error)")
            }
        }
        
    }
}
