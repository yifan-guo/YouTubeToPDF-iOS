//
//  GenerateViewController.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 2/10/25.
//

import UIKit

// API URLs
let apiGatewayUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/convert"
let pollingUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/status"

class GenerateViewController: UIViewController {

    var youtubeUrlTextField: UITextField!
    var submitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    func setupUI() {
        self.title = "Generate"
        
        // Set up a label for the Generate tab
        let generateLabel = UILabel()
        generateLabel.text = "Generate Tab"
        generateLabel.textAlignment = .center
        generateLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        generateLabel.center = CGPoint(x: view.center.x, y: view.center.y - 100)
        view.addSubview(generateLabel)
        
        // Set up a text field for YouTube URL input
        youtubeUrlTextField = UITextField()
        youtubeUrlTextField.placeholder = "Enter YouTube URL"
        youtubeUrlTextField.borderStyle = .roundedRect
        youtubeUrlTextField.frame = CGRect(x: 20, y: view.center.y, width: view.frame.width - 40, height: 40)
        view.addSubview(youtubeUrlTextField)

        // Set up a Submit button
        submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit URL", for: .normal)
        submitButton.frame = CGRect(x: (view.frame.width - 200) / 2, y: view.center.y + 60, width: 200, height: 50)
        submitButton.addTarget(self, action: #selector(submitUrl), for: .touchUpInside)
        view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            generateLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            generateLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }

    @objc func submitUrl() {
        // Handle the submit action
        guard let youtubeUrl = youtubeUrlTextField.text, !youtubeUrl.isEmpty else {
            print("YouTube URL is empty")
            return
        }
        
        guard let deviceToken = (UIApplication.shared.delegate as? AppDelegate)?.deviceToken else {
            print("Device token not available")
            return
        }
        
        // Disable the button to prevent multiple submissions
        submitButton.isEnabled = false
            
        // Trigger the API call to start the process
        triggerStepFunction(youtubeURL: youtubeUrl, deviceToken: deviceToken)
        
        // Only for local testing where you don't want to incur AWS and Proxy usage
        // sleep(2)
        // sendLocalNotification("https://www.adobe.com/content/dam/cc/en/legal/terms/enterprise/pdfs/GeneralTerms-NA-2024v1.pdf")
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
                                                            
                                // Notify the user that the download is complete
                                DispatchQueue.main.async {
                                    self.notifyUserDownloadStarted(executionId: executionId)
                                }
                            }
                        } else {
                            // Handle non-202 status codes
                            print("Error: Received status code \(statusCode)")
                            self.notifyUserDownloadFailed(message: "An error occurred while processing your request. Please try again later.")
                            return
                        }
                    } else {
                        // Handle missing statuscode
                        print("Error: Response is missing 'statusCode' attribute")
                        if let errorBody = String(data: data, encoding: .utf8) {
                            print("Response body: \(errorBody)")
                        }
                        self.notifyUserDownloadFailed(message: "An error occurred while processing your request. Please try again later.")
                    }
                } else {
                    print("Unexpected response structure")
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("Response body: \(errorBody)")
                    }
                    self.notifyUserDownloadFailed(message: "An error occurred while processing your request. Please try again later.")
                }
            } catch {
                print("Error parsing Step Function response: \(error)")
                self.notifyUserDownloadFailed(message: "An error occurred while processing your request. Please try again later.")
            }
        }
        
        task.resume()
    }
    
    // This function sends a local notification to the user indicating the download started
    // a local notification is scheduled and displayed on the device itself, without needing to communicate with a server.
    func notifyUserDownloadStarted(executionId: String) {
        // Store the presigned URL in UserDefaults so it can be accessed when the app is opened manually
        UserDefaults.standard.set(executionId, forKey: "executionId")
        
        sendPushNotification(title: "Download Started", message: "Your download has started. You'll receive another notification once it's complete.", identifier: "downloadStarted")
    }
    
    // This function sends a local notification to the user indicating the download started
    func notifyUserDownloadFailed(message: String) {
        // Send a notification when the download fails
        sendPushNotification(title: "Download Failed", message: "Something went wrong while processing your request. Please reopen the app to try again.", identifier: "errorNotification"
        )
        
        // Show error alert to the user once they reopen the app
        showErrorAlert(message: message)
    }
    
    func sendPushNotification(title: String, message: String, identifier: String) {
        // Use UNUserNotificationCenter to schedule a local notification.
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Trigger notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling push notification: \(error)")
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
}
