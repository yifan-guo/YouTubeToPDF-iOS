import UIKit
import PDFKit
import WebKit

private var cardKey: UInt8 = 0

class ViewController: UIViewController {
    
    @IBOutlet weak var youtubeUrlTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    // IBOutlet for the Explore scroll view
    @IBOutlet weak var exploreScrollView: UIScrollView!
    
    // Declare a WKWebView to display PDFs
    var pdfWebView: WKWebView!
    var backButton: UIButton!

    // Define variables for the bottom tab bar and buttons
    var bottomTabBar: UIView!
    var exploreButton: UIButton!
    var generateButton: UIButton!
    
    var exploreHeaderLabel: UILabel!
    var generateHeaderLabel: UILabel!
    
    var currentTab = "Explore" // Default active tab
    
    
    // Store all downloaded PDFs as cards
    var downloadedPDFs: [PDFCard] = []

    // Create PDFView instance to display the PDF inside the app
    var pdfView: PDFView!
    
    // API URLs
    let apiGatewayUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/convert"
    let pollingUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/status"
    
                                                       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI and headers programmatically
        setupTabHeaders()
        
        // Set up the initial UI
        setupUI()
        
        // Add the PDFView to the view
        setupPDFView()
        
        // Observe the custom notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadFinished(_:)), name: .didFinishDownloading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationTap(_:)), name: .didTapNotification, object: nil)

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

    
    // MARK: - UI Setup
    func setupUI() {
//        // Stylize submit button (using helper function)
//        styleSubmitButton()
//        
//        // Stylize YouTube URL text field
//        styleYoutubeUrlTextField()
        
        setupBottomTabBar()
    }

    func setupTabHeaders() {
        // set up the "Explore" header
        exploreHeaderLabel = UILabel()
        exploreHeaderLabel.text = "My PDFs" // Title for Explore tab
        exploreHeaderLabel.font = UIFont.boldSystemFont(ofSize: 20)
        exploreHeaderLabel.textColor = .black
        exploreHeaderLabel.textAlignment = .center
        exploreHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exploreHeaderLabel)
        
        // Add constraints to position the header label at the top
        NSLayoutConstraint.activate([
            exploreHeaderLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            exploreHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            exploreHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exploreHeaderLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // set up the generate header
        generateHeaderLabel = UILabel()
        generateHeaderLabel.text = "Create PDF" // Title for generate tab
        generateHeaderLabel.font = UIFont.boldSystemFont(ofSize: 20)
        generateHeaderLabel.textColor = .black
        generateHeaderLabel.textAlignment = .center
        generateHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(generateHeaderLabel)
        
        // Add constraints to position the header label at the top
        NSLayoutConstraint.activate([
            generateHeaderLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            generateHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            generateHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            generateHeaderLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    
    func setupPDFView() {
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.backgroundColor = .lightGray
        view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Initially hide PDFView
        pdfView.isHidden = true
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
        default:
            break
        }
    }

    // Other methods for the "Generate" tab and handling downloads...

    
    // Handle the custom notification and update the UI
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
    
    func addDownloadedPDF(url: String) {
        print("inside addDownloadedPDF")
        // Create a new PDF card with the current timestamp
        let newPDFCard = PDFCard(url: url, timestamp: Date())
        
        // Append it to the list of downloaded PDFs
        downloadedPDFs.append(newPDFCard)
        print("appended pdf card to list, next step is to update UI")
        
        // Update the UI to display the new PDF card in the Explore tab
        updateExploreTabUI()
    }
    
    func updateExploreTabUI() {
        print("inside updateExploreTabUI")
        DispatchQueue.main.async {
            print("Updating Explore Tab UI...")  // Debug print
            
            // Remove all existing subviews from the Explore scroll view
            for subview in self.exploreScrollView.subviews {
                print("Removing subview: \(subview)")  // Debug print
                subview.removeFromSuperview()
            }

            var lastYPosition: CGFloat = 20
            
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

    // Create a custom "card" for each downloaded PDF
    func createCardView(for pdfCard: PDFCard) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 10
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4

        let titleLabel = UILabel()
        titleLabel.text = "Generated PDF"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        let timestampLabel = UILabel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        timestampLabel.text = "Downloaded: \(dateFormatter.string(from: pdfCard.timestamp))"
        timestampLabel.font = UIFont.systemFont(ofSize: 12)
        timestampLabel.textColor = .gray
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(timestampLabel)

        // Set up constraints for the labels
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),

            timestampLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            timestampLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            timestampLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            timestampLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10)
        ])

        // Add tap gesture recognizer to the card
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Store the URL for this card in the gesture's associated object
        print("Associating PDF card: \(pdfCard.url)")
        objc_setAssociatedObject(cardView, &cardKey, pdfCard, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return cardView
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
        // Re-setup or update the UI when the app is coming into the foreground
        // This ensures the view updates appropriately when the app comes from the background.
        print("App entered foreground - UI should be updated")
        
        // Update your UI or perform any necessary actions here
        updateExploreTabUI()
    }

    // Unregister when the view controller goes away
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didTapNotification, object: nil)
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
        // Convert the S3 presigned URL string to a URL object
        guard let url = URL(string: url) else { return }
        
        // Perform the PDF loading on a background thread to avoid blocking the main thread
        DispatchQueue.global(qos: .background).async {
            // Try to load the PDF asynchronously
            if let document = PDFDocument(url: url) {
                // Once the PDF is loaded, update the UI on the main thread
                DispatchQueue.main.async {
                    self.pdfView.document = document
                    self.pdfView.isHidden = false // Show the PDFView when the PDF is loaded
                    print("PDF loaded successfully")
                    
                    // Create a back button
                    self.addBackButton()
                }
            } else {
                // Handle error if the PDF couldn't be loaded
                DispatchQueue.main.async {
                    print("Failed to load PDF from URL")
                    // Optionally show an error message to the user
                }
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
        
        sleep(2)
    
        // Trigger the API call to start the process
//        triggerStepFunction(youtubeURL: youtubeUrl, deviceToken: deviceToken)
        sendLocalNotification("https://www.adobe.com/content/dam/cc/en/legal/terms/enterprise/pdfs/GeneralTerms-NA-2024v1.pdf")
    }
    
    // TODO remove this is temporary for testing
    func sendLocalNotification(_ url: String) {
        print("Inside sendLocalNotification")

        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "Your PDF is ready. Tap to view it."
        content.userInfo = ["presigned_url": url]  // Attach URL in userInfo

        // Set the trigger to fire immediately (1 second)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: "didFinishDownloading", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
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
