import UIKit


class ViewController: UIViewController {
    
    @IBOutlet weak var youtubeUrlTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    // Define variables for the bottom tab bar and buttons
    var bottomTabBar: UIView!
    var exploreButton: UIButton!
    var generateButton: UIButton!
    
    var currentTab = "Explore" // Default active tab

    // API URLs
    let apiGatewayUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/convert"
    let pollingUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/status"
    
                                                       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the initial UI
        setupUI()
        
        // Observe the custom notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadFinished(_:)), name: .didFinishDownloading, object: nil)
    }
    
    // MARK: - UI Setup
    func setupUI() {
//        // Stylize submit button (using helper function)
//        styleSubmitButton()
//        
//        // Stylize YouTube URL text field
//        styleYoutubeUrlTextField()
        
        setupBottomTabBar()
    }
    
    func styleSubmitButton() {
        // Button background color
        submitButton.backgroundColor = UIColor.systemGreen
        
        // Button text color
        submitButton.setTitleColor(.white, for: .normal)
        
        // Button font and size
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        // Button corner radius and shadow for better visibility
        submitButton.layer.cornerRadius = 12
        submitButton.layer.shadowColor = UIColor.black.cgColor
        submitButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        submitButton.layer.shadowOpacity = 0.2
        submitButton.layer.shadowRadius = 6
    }
    
    func styleYoutubeUrlTextField() {
        // Set text field background color to light gray for contrast
        youtubeUrlTextField.backgroundColor = UIColor.darkGray
        
        // Set text field text color to white for better visibility
        youtubeUrlTextField.textColor = .white
        
        // Set placeholder text color for contrast
        youtubeUrlTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter YouTube URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        
        // Set text field font and size
        youtubeUrlTextField.font = UIFont.systemFont(ofSize: 16)
        
        // Set border radius for the text field
        youtubeUrlTextField.layer.cornerRadius = 8
        youtubeUrlTextField.layer.masksToBounds = true
    }

    // Set up the bottom tab bar with buttons for each feature
    private func setupBottomTabBar() {
        // Create the bottom tab bar container
        bottomTabBar = UIView()
        bottomTabBar.translatesAutoresizingMaskIntoConstraints = false
        bottomTabBar.backgroundColor = UIColor.darkGray
        bottomTabBar.layer.cornerRadius = 15
        bottomTabBar.layer.shadowOpacity = 0.5
        bottomTabBar.layer.shadowRadius = 5
        bottomTabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        
        view.addSubview(bottomTabBar)

        // Set up constraints for the bottom tab bar
        NSLayoutConstraint.activate([
            bottomTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            bottomTabBar.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Create the buttons for each tab
        exploreButton = createTabButton(title: "Explore", action: #selector(exploreTapped))
        generateButton = createTabButton(title: "Generate", action: #selector(generateTapped))

        // Add buttons to the bottom tab bar
        bottomTabBar.addSubview(exploreButton)
        bottomTabBar.addSubview(generateButton)

        // Set up button constraints inside the bottom tab bar
        let buttons = [exploreButton, generateButton]
        let buttonWidth = (view.frame.width - 40) / CGFloat(buttons.count) // Adjust width based on screen size

        for (index, button) in buttons.enumerated() {
            if let unwrappedButton = button {
                unwrappedButton.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    unwrappedButton.topAnchor.constraint(equalTo: bottomTabBar.topAnchor),
                    unwrappedButton.bottomAnchor.constraint(equalTo: bottomTabBar.bottomAnchor),
                    unwrappedButton.widthAnchor.constraint(equalToConstant: buttonWidth),
                    unwrappedButton.leftAnchor.constraint(equalTo: bottomTabBar.leftAnchor, constant: CGFloat(index) * buttonWidth)
                ])
            }
        }
            
            
        // Set the default active tab
        updateTabSelection(selectedTab: currentTab)
    }

    // Create a reusable tab button with a title and action
    private func createTabButton(title: String, action: Selector) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.layer.cornerRadius = 8
        return button
    }

    // Tab button actions
    @objc private func exploreTapped() {
        updateTabSelection(selectedTab: "Explore")
    }

    @objc private func generateTapped() {
        updateTabSelection(selectedTab: "Generate")
    }
    
    // Update the UI to reflect the selected tab
    private func updateTabSelection(selectedTab: String) {
        currentTab = selectedTab
        print("Selected Tab: \(selectedTab)")

        // Change background colors for the view based on the selected tab
        switch selectedTab {
        case "Explore":
            view.backgroundColor = .darkGray
        case "Generate":
            view.backgroundColor = .lightGray
        default:
            break
        }
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
}
