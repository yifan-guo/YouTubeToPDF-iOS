//
//  CommentsViewController.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 2/4/25.
//

import UIKit

protocol CommentsViewControllerDelegate: AnyObject {
    func didAddComment(_ comment: String, for pdfCard: PDFCard)
}

class CommentsViewController: UIViewController {
    var pdfCard: PDFCard?
    weak var delegate: CommentsViewControllerDelegate?

    private var comments: [String] = []
    
    private let tableView = UITableView()
    private let commentTextField = UITextField()
    private let submitButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        loadComments()
    }

    private func setupUI() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        commentTextField.placeholder = "Enter a comment"
        commentTextField.borderStyle = .roundedRect
        commentTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(commentTextField)

        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitComment), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: commentTextField.topAnchor, constant: -10),

            commentTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            commentTextField.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: -10),
            commentTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            submitButton.bottomAnchor.constraint(equalTo: commentTextField.bottomAnchor)
        ])
    }

    private func loadComments() {
        guard let pdfCard = pdfCard else { return }
        let key = "comments_\(pdfCard.url)"  // Unique key for each PDF
        comments = UserDefaults.standard.stringArray(forKey: key) ?? []
        tableView.reloadData()
    }

    @objc private func submitComment() {
        guard let pdfCard = pdfCard,
              let newComment = commentTextField.text,
              !newComment.isEmpty else { return }

        // Get current date & time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())

        // Format the comment with timestamp
        let formattedComment = "\(timestamp) - \(newComment)"

        // Update comments list
        comments.append(formattedComment)
        tableView.reloadData()

        // Save to UserDefaults
        let key = "comments_\(pdfCard.url)"
        UserDefaults.standard.set(comments, forKey: key)

        // Notify delegate
        delegate?.didAddComment(formattedComment, for: pdfCard)

        // Clear input field
        commentTextField.text = ""
    }
}

extension CommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = comments[indexPath.row]
        return cell
    }
}
