//
//  CommentViewController.swift
//  YouTubeToPDF
//

//  Created by Yifan Guo on 2/3/25.
//

import UIKit

protocol CommentViewControllerDelegate: AnyObject {
    func savePDFs()  // Method to save PDFs
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CommentViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pdfCard?.comments.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        
        // Get the comment at the current index
        guard let comment = pdfCard?.comments[indexPath.row] else { return cell }
        
        // Display the comment text and timestamp
        cell.textLabel?.text = comment.text
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        cell.detailTextLabel?.text = dateFormatter.string(from: comment.timestamp)
        
        return cell
    }
}

class CommentViewController: UIViewController {

    // MARK: - Properties
    var pdfCard: PDFCard? // The PDF card that we're adding comments to
    weak var delegate: CommentViewControllerDelegate? // Delegate to save PDFs
    
    private let commentsTableView = UITableView()
    private let commentTextView = UITextView()
    private let addCommentButton = UIButton()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setupUI()
        
        // Add tap gesture to dismiss keyboard when tapping outside text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - UI Setup
    func setupUI() {
        view.backgroundColor = .white
        
        // Set up comments table view
        commentsTableView.translatesAutoresizingMaskIntoConstraints = false
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CommentCell")
        view.addSubview(commentsTableView)
        
        // Set up comment text view
        commentTextView.translatesAutoresizingMaskIntoConstraints = false
        commentTextView.layer.borderColor = UIColor.gray.cgColor
        commentTextView.layer.borderWidth = 1.0
        commentTextView.layer.cornerRadius = 5
        commentTextView.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(commentTextView)
        
        // Set up add comment button
        addCommentButton.translatesAutoresizingMaskIntoConstraints = false
        addCommentButton.setTitle("Add Comment", for: .normal)
        addCommentButton.backgroundColor = .blue
        addCommentButton.layer.cornerRadius = 5
        addCommentButton.addTarget(self, action: #selector(submitComment), for: .touchUpInside)
        view.addSubview(addCommentButton)
        
        // Set up layout constraints
        NSLayoutConstraint.activate([
            commentsTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            commentsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commentsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            commentsTableView.heightAnchor.constraint(equalToConstant: 300),
            
            commentTextView.topAnchor.constraint(equalTo: commentsTableView.bottomAnchor, constant: 20),
            commentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            commentTextView.heightAnchor.constraint(equalToConstant: 100),
            
            addCommentButton.topAnchor.constraint(equalTo: commentTextView.bottomAnchor, constant: 20),
            addCommentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addCommentButton.heightAnchor.constraint(equalToConstant: 44),
            addCommentButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Methods
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func submitComment() {
        // Ensure the comment field is not empty
        guard let commentText = commentTextView.text, !commentText.isEmpty else {
            print("Error: Comment text is empty.")
            return
        }
        
        // Safeguard: Ensure pdfCard is not nil
        guard let pdfCard = pdfCard else {
            print("Error: pdfCard is nil.")
            return
        }
        
        // Create a new Comment object with a timestamp
        let newComment = Comment(userName: "User", text: commentText, timestamp: Date())
        
        // Add the new comment to the PDFCard
        pdfCard.comments.append(newComment)
        
        // Reload the table view to display the new comment
        commentsTableView.reloadData()
        
        // Call the delegate method to save the PDF cards
        delegate?.savePDFs()
        
        // Clear the comment text view
        commentTextView.text = ""
    }
}
