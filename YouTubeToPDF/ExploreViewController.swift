//
//  ExploreViewController.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 2/10/25.
//

import UIKit
import PDFKit
import WebKit

public var cardKey: UInt8 = 0

class ExploreViewController: UIViewController, CommentsViewControllerDelegate {
    
    // implement CommentsViewControllerDelegate
    func didAddComment(_ comment: String, for pdfCard: PDFCard) {
        print("New comment added: \(comment) for PDF \(pdfCard.url)")
    }
    
    // Store all downloaded PDFs as cards
    var downloadedPDFs: [PDFCard] = []
    
    // A dictionary to store comments by card URL
    var pdfComments: [String: [String]] = [:]

    // Create PDFView instance to display the PDF inside the app
    var pdfView: PDFView!
    
    var backButton: UIButton!
    
    // Programmatic UIScrollView
    private let exploreScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "Explore"

        let label = UILabel()
        label.text = "Explore Tab"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        setupScrollView()
        
        // Load saved PDFs from persistent storage
        loadPDFs()
        
        // Add the PDFView to the view
        setupPDFView()
        
        // Observe the custom notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadFinished(_:)), name: .didFinishDownloading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationTap(_:)), name: .didTapNotification, object: nil)
    }
    
    // Unregister when the view controller goes away
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didTapNotification, object: nil)
    }
    
    private func setupScrollView() {
        view.addSubview(exploreScrollView)

        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            exploreScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            exploreScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            exploreScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            exploreScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        // Create a new PDF card with the current timestamp
        let newPDFCard = PDFCard(url: url, timestamp: Date(), comments: [])
        
        // Append it to the list of downloaded PDFs
        downloadedPDFs.append(newPDFCard)
        print("appended pdf card to list, next step is to update UI")
        
        savePDFs()  // Save the updated list to UserDefaults
        
        // Update the UI to display the new PDF card in the Explore tab
        updateExploreTabUI()
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
//        updateTabSelection(selectedTab: "Explore", from: self)
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
//            self.submitButton.isEnabled = true
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
    
    @objc func refreshUIOnForeground() {
        // Refresh Explore tab and ensure the PDFView is shown if necessary
        print("App is coming to the foreground, updating UI.")
        updateExploreTabUI()

        // Optional: If you need to open a PDF right away, check if there is any URL to open
        if let lastDownloadedURL = downloadedPDFs.last?.url {
            openPDF(lastDownloadedURL)
        }
    }
}
