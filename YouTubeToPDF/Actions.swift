//
//  Actions.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 2/4/25.
//

import UIKit



extension ViewController {
    
    @objc func showComments(_ sender: UIButton) {
        print("Comment button tapped")  // Add this line to debug
        guard var pdfCard = objc_getAssociatedObject(sender, &cardKey) as? PDFCard else {
                print("No PDF card found")
                return
            }
            
            // Present the CommentsViewController
            let commentsVC = CommentsViewController()
            commentsVC.pdfCard = pdfCard
            commentsVC.delegate = self as CommentsViewControllerDelegate
            present(commentsVC, animated: true, completion: nil)
    }
    
    func didAddComment(_ comment: String, for pdfCard: PDFCard) {
        print("New comment added: \(comment) for PDF \(pdfCard.url)")
    }

    func saveComments() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(pdfComments) {
            UserDefaults.standard.set(encoded, forKey: "pdfComments")
        }
    }

    func loadComments() {
        if let savedData = UserDefaults.standard.data(forKey: "pdfComments"),
           let decodedComments = try? JSONDecoder().decode([String: [String]].self, from: savedData) {
            pdfComments = decodedComments
        }
    }

    
    // MARK: - UI Setup
    func setupUI() {
        setupBottomTabBar()
    }

    
    @objc func refreshUIOnForeground() {
        // Refresh Explore tab and ensure the PDFView is shown if necessary
        print("App is coming to the foreground, updating UI.")
        updateExploreTabUI()

        // Optional: If you need to open a PDF right away, check if there is any URL to open
        if let lastDownloadedURL = downloadedPDFs.last?.url {
            openPDF(lastDownloadedURL)
        }
    }
    
    // Tab button actions
    @objc private func exploreTapped() {
        updateTabSelection(selectedTab: "Explore")
    }

    @objc private func generateTapped() {
        updateTabSelection(selectedTab: "Generate")
    }
    
    @objc private func recordTapped() {
        updateTabSelection(selectedTab: "Record")
    }
    
    // Update the UI when a tab is selected
    private func updateTabSelection(selectedTab: String) {
        currentTab = selectedTab
        print("Selected Tab: \(selectedTab)")

        // Show/Hide UI elements based on the selected tab
        switch selectedTab {
        case "Explore":
            // Hide the YouTube URL text field and submit button when Explore tab is selected
            exploreScrollView.isHidden = false
            youtubeUrlTextField.isHidden = true
            submitButton.isHidden = true
            exploreHeaderLabel.isHidden = false // Show the header for Explore tab
            generateHeaderLabel.isHidden = true
            
            // Optionally update the background to show that Explore is selected
            exploreButton.backgroundColor = UIColor.systemGreen
            generateButton.backgroundColor = UIColor.darkGray
            
            // Update the Explore tab UI to show the downloaded PDFs
            updateExploreTabUI()
        case "Generate":
            // Show the YouTube URL text field and submit button when Generate tab is selected
            exploreScrollView.isHidden = true
            youtubeUrlTextField.isHidden = false
            submitButton.isHidden = false
            exploreHeaderLabel.isHidden = true // Hide the header for Explore tab
            generateHeaderLabel.isHidden = false

            // Highlight the Generate button and dim the Explore button
            generateButton.backgroundColor = UIColor.systemGreen
            exploreButton.backgroundColor = UIColor.darkGray
        case "Record":
            let recordVC = RecordViewController()
            recordVC.modalPresentationStyle = .fullScreen
            present(recordVC, animated: true, completion: nil)

            recordButton.backgroundColor = UIColor.systemGreen
            exploreButton.backgroundColor = UIColor.darkGray
            generateButton.backgroundColor = UIColor.darkGray
            
        default:
            break
        }
    }
    
    @objc func handleDownloadFinished(_ notification: Notification) {
        // Retrieve the URL from the notification's userInfo
        if let userInfo = notification.userInfo, let url = userInfo["url"] as? String {
            // Update the UI or show the download popup
            // showDownloadPopup(url: url)
            print("inside handleDownloadFinished")
            // Check if the PDF is already in the list to prevent duplicates
            if !downloadedPDFs.contains(where: { $0.url == url }) {
                print("url not in downloadedPDFs, adding it")
                // Add the downloaded PDF to the list and update UI
                addDownloadedPDF(url: url)
            } else {
                print("PDF already downloaded, skipping addition.")
            }
        }
     }
     
     // Open the PDF when the notification is tapped
     @objc func handleNotificationTap(_ notification: Notification) {
         if let userInfo = notification.userInfo, let url = userInfo["url"] as? String {
             // Check if the PDF is already in the list
             if let pdfCard = downloadedPDFs.first(where: { $0.url == url }) {
                 // Open the PDF directly (since it's already in the list)
                 openPDF(pdfCard.url)  // Make sure the URL is passed to the openPDF method
             } else {
                 print("PDF not found in list.")
             }
         }
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
        recordButton = createTabButton(title: "Record", action: #selector(recordTapped)) // New Record tab

        // Add buttons to the bottom tab bar
        bottomTabBar.addSubview(exploreButton)
        bottomTabBar.addSubview(generateButton)
        bottomTabBar.addSubview(recordButton)

        // Set up button constraints inside the bottom tab bar
        let buttons = [exploreButton, generateButton, recordButton]
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
    
    func updateExploreTabUI() {
        print("inside updateExploreTabUI")
        DispatchQueue.main.async {
            print("Updating Explore Tab UI...")  // Debug print
            
            // First, remove any existing card views
            for subview in self.exploreScrollView.subviews {
                subview.removeFromSuperview()
            }

            var lastYPosition: CGFloat = 60  // Ensure there's space between the header and the first card

            // Loop through all the downloaded PDFs and create "cards" for each
            for (index, pdf) in self.downloadedPDFs.enumerated() {
                // Create the card view for each PDF
                print("Creating card for PDF: \(pdf.url)")  // Debug print
                let cardView = self.createCardView(for: pdf)
                cardView.frame = CGRect(x: 20, y: lastYPosition, width: self.view.frame.width - 40, height: 100)
                self.exploreScrollView.addSubview(cardView)
                
                lastYPosition = cardView.frame.maxY + 20
            }

            // Set the content size of the scroll view so that it is scrollable
            self.exploreScrollView.contentSize = CGSize(width: self.view.frame.width, height: lastYPosition)
            print("Scroll view content size updated: \(self.exploreScrollView.contentSize)")  // Debug print
            
            // Ensure that the layout is updated (in case there are layout issues)
            self.view.layoutIfNeeded()
            
            // Re-enable the submit button
            self.submitButton.isEnabled = true
        }
    }

    
    @objc func cardTapped(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view else { return }
        
        // Attempt to retrieve the associated PDFCard
        if let pdfCard = objc_getAssociatedObject(cardView, &cardKey) as? PDFCard {
            print("Card tapped! PDF URL: \(pdfCard.url)")
            openPDF(pdfCard.url)
        } else {
            // Print the associated object for debugging
            print("Failed to retrieve associated PDFCard.")
            if let associatedObject = objc_getAssociatedObject(cardView, &cardKey) {
                print("Associated object exists, but it is not of type PDFCard: \(associatedObject)")
            }
        }
    }
    
    
    @objc func printPDF(_ sender: UIButton) {
        guard let pdfCard = objc_getAssociatedObject(sender.superview!, &cardKey) as? PDFCard else { return }
        guard let pdfURL = URL(string: pdfCard.url) else { return }
        
        // Create print controller
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        
        printController.printInfo = printInfo
        printController.printingItem = pdfURL
        
        printController.present(animated: true, completionHandler: nil)
    }

    @objc func sharePDF(_ sender: UIButton) {
        guard let pdfCard = objc_getAssociatedObject(sender.superview!, &cardKey) as? PDFCard else { return }
        guard let pdfURL = URL(string: pdfCard.url) else { return }
        
        let activityController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        
        // Exclude certain activities if desired (e.g., AirDrop)
        activityController.excludedActivityTypes = [.airDrop, .postToFacebook, .postToTwitter]
        
        present(activityController, animated: true, completion: nil)
    }

    
    @objc func deletePDF(_ sender: UIButton) {
        guard let cardView = sender.superview,
              let pdfCard = objc_getAssociatedObject(cardView, &cardKey) as? PDFCard else {
            print("Could not find the associated PDF card")
            return
        }

        // Create the alert controller for deletion confirmation
        let alertController = UIAlertController(title: "Delete PDF", message: "Are you sure you want to delete this PDF?", preferredStyle: .alert)

        // Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        // Delete Action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            // 1. Remove the PDF from the list of downloaded PDFs
            if let index = self.downloadedPDFs.firstIndex(where: { $0.url == pdfCard.url }) {
                self.downloadedPDFs.remove(at: index)
                print("PDF deleted from model: \(pdfCard.url)")
            }

            // 2. Remove the card view from the scroll view (UI)
            cardView.removeFromSuperview()

            // 3. Persist the updated PDF list (you should save it to UserDefaults or another storage)
            self.savePDFs()

            // 4. Update the UI (rebuild the remaining cards)
            self.updateExploreTabUI()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)

        // Show the alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func addBackButton() {
        // Check if the back button already exists, if it does, return
        if backButton != nil { return }
        
        // Create the back button
        backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Set up the back button appearance
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.layer.cornerRadius = 10
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor.systemBlue.cgColor
        backButton.setTitleColor(.systemBlue, for: .normal)
        
        view.addSubview(backButton)
        
        // Add constraints for the back button
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 80),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc func backButtonTapped() {
        // Hide the PDF view
        pdfView.isHidden = true
        
        // Remove the back button
        backButton.removeFromSuperview()
        backButton = nil
        
        // Show the Explore tab again with the cards
        updateTabSelection(selectedTab: "Explore")
    }

    
    
    // Other methods for the "Generate" tab and handling downloads...

    
    // Handle the custom notification and update the UI
   
    
    func addDownloadedPDF(url: String) {
        print("inside addDownloadedPDF")
        // Create a new PDF card with the current timestamp
        let newPDFCard = PDFCard(url: url, timestamp: Date(), comments: [])
        
        // Append it to the list of downloaded PDFs
        downloadedPDFs.append(newPDFCard)
        print("appended pdf card to list, next step is to update UI")
        
        savePDFs()  // Save the updated list to UserDefaults
        
        // Update the UI to display the new PDF card in the Explore tab
        updateExploreTabUI()
    }
   

    func savePDFs() {
        let pdfDicts = downloadedPDFs.map { pdfCard in
            return [
                "url": pdfCard.url,
                "timestamp": DateFormatter.localizedString(from: pdfCard.timestamp, dateStyle: .short, timeStyle: .short),
                "comments": pdfCard.comments
            ]
        }
        
        UserDefaults.standard.set(pdfDicts, forKey: "downloadedPDFs")
    }

    
    // read from UserDefaults and into self.downloadedPDFs
    func loadPDFs() {
        if let savedPDFs = UserDefaults.standard.array(forKey: "downloadedPDFs") as? [[String: Any]] {
            self.downloadedPDFs = savedPDFs.compactMap { pdfDict in
                guard let urlString = pdfDict["url"] as? String,
                      let timestampString = pdfDict["timestamp"] as? String,
                      let comments = pdfDict["comments"] as? [String] else {
                    return nil
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                guard let timestamp = dateFormatter.date(from: timestampString) else {
                    return nil
                }
                
                return PDFCard(url: urlString, timestamp: timestamp, comments: comments)
            }
        }
    }





    // AWS
    
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

