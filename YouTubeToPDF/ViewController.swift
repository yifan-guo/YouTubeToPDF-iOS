import UIKit
import PDFKit
import WebKit

public var cardKey: UInt8 = 0

class ViewController: UIViewController,CommentsViewControllerDelegate {
    
    func saveUpdatedPDFCard(_ pdfCard: PDFCard) {
        // Find the index of the modified pdfCard in the downloadedPDFs array
        if let index = downloadedPDFs.firstIndex(where: { $0.url == pdfCard.url }) {
            downloadedPDFs[index] = pdfCard  // Update the pdfCard at the found index
            savePDFs()  // Save the updated list to UserDefaults
        }
    }

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
    var recordButton: UIButton!
    
    var exploreHeaderLabel: UILabel!
    var generateHeaderLabel: UILabel!
    
    var currentTab = "Explore" // Default active tab
    
    // Store all downloaded PDFs as cards
    var downloadedPDFs: [PDFCard] = []
    
    // A dictionary to store comments by card URL
    var pdfComments: [String: [String]] = [:]

    // Create PDFView instance to display the PDF inside the app
    var pdfView: PDFView!
    
    // API URLs
    let apiGatewayUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/convert"
    let pollingUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/status"
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear called")  // Check if this is being triggered

        super.viewWillAppear(animated)
        
        // Load saved PDFs from UserDefaults
        loadPDFs()
    }
                                              
    override func viewDidLoad() {
        print("viewDidLoad called")

        super.viewDidLoad()
        
        
        // Load saved PDFs from persistent storage
        self.loadPDFs()
        
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

    // Unregister when the view controller goes away
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didTapNotification, object: nil)
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

        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "Generated PDF"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Timestamp label
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

        // Add tap gesture recognizer to the card to open the PDF
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        

        // Create the action "bubbles" for each card: Print, Share, Delete
        let buttonSize: CGFloat = 30  // Smaller button size
        let bubblePadding: CGFloat = 10 // Padding from card edges

        // Print Button (using system icon)
        let printButton = UIButton()
        printButton.setImage(UIImage(systemName: "printer"), for: .normal)
        printButton.tintColor = .black
        printButton.translatesAutoresizingMaskIntoConstraints = false
        printButton.addTarget(self, action: #selector(printPDF(_:)), for: .touchUpInside)
        cardView.addSubview(printButton)
        
        // Share Button (using system icon)
        let shareButton = UIButton()
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .black
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(sharePDF(_:)), for: .touchUpInside)
        cardView.addSubview(shareButton)
        
        // Delete Button (using system icon)
        let deleteButton = UIButton()
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .black
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deletePDF(_:)), for: .touchUpInside)
        cardView.addSubview(deleteButton)
        
        // Comment Button
        let commentButton = UIButton()
        commentButton.setImage(UIImage(systemName: "bubble.left.and.bubble.right"), for: .normal)
        commentButton.tintColor = .black
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.addTarget(self, action: #selector(showComments(_:)), for: .touchUpInside)
        cardView.addSubview(commentButton)
        
        // Store the URL for this card in the gesture's associated object
        objc_setAssociatedObject(cardView, &cardKey, pdfCard, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(commentButton, &cardKey, pdfCard, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)


        // Constraints for buttons (position them in the bottom right corner)
        NSLayoutConstraint.activate([
            printButton.widthAnchor.constraint(equalToConstant: buttonSize),
            printButton.heightAnchor.constraint(equalToConstant: buttonSize),
            printButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -bubblePadding),
            printButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -bubblePadding),

            shareButton.widthAnchor.constraint(equalToConstant: buttonSize),
            shareButton.heightAnchor.constraint(equalToConstant: buttonSize),
            shareButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -bubblePadding),
            shareButton.trailingAnchor.constraint(equalTo: printButton.leadingAnchor, constant: -bubblePadding),

            deleteButton.widthAnchor.constraint(equalToConstant: buttonSize),
            deleteButton.heightAnchor.constraint(equalToConstant: buttonSize),
            deleteButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -bubblePadding),
            deleteButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -bubblePadding),
            
            commentButton.widthAnchor.constraint(equalToConstant: buttonSize),
            commentButton.heightAnchor.constraint(equalToConstant: buttonSize),
            commentButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -bubblePadding),
            commentButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -bubblePadding)
        ])
        
        return cardView
    }
    
    func openPDF(_ url: String) {
        // Convert the S3 presigned URL string to a URL object
        guard let url = URL(string: url) else { return }
        
        // Perform the PDF loading on a background thread to avoid blocking the main thread
        DispatchQueue.global(qos: .background).async {
            do {
                // Download the PDF data from the URL asynchronously
                let pdfData = try Data(contentsOf: url)
                
                // Once the data is downloaded, we need to display the PDF
                if let document = PDFDocument(data: pdfData) {
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
                        print("Failed to load PDF document")

                    }
                }
            } catch {
                print("Failed to download PDF from URL: \(error.localizedDescription)")
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
}
