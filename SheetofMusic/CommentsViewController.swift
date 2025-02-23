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
    private var bottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadComments()
        setupKeyboardObservers()
        setupTapGestureToDismissKeyboard()
    }

    private func setupUI() {
        view.backgroundColor = .white
        
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        commentTextField.placeholder = "Enter a comment"
        commentTextField.borderStyle = .roundedRect
        commentTextField.backgroundColor = .lightGray
        commentTextField.translatesAutoresizingMaskIntoConstraints = false
        commentTextField.addTarget(self, action: #selector(submitComment), for: .editingDidEndOnExit)
        view.addSubview(commentTextField)

        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitComment), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitButton)

        bottomConstraint = commentTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: commentTextField.topAnchor, constant: -10),

            commentTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            commentTextField.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: -10),
            bottomConstraint,

            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            submitButton.bottomAnchor.constraint(equalTo: commentTextField.bottomAnchor)
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            bottomConstraint.constant = -keyboardFrame.height
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        bottomConstraint.constant = -16
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func loadComments() {
        guard let pdfCard = pdfCard else { return }
        let key = "comments_\(pdfCard.url)"
        comments = UserDefaults.standard.stringArray(forKey: key) ?? []
        tableView.reloadData()
    }

    @objc private func submitComment() {
        // Dismiss the keyboard
        commentTextField.resignFirstResponder()
        
        guard let pdfCard = pdfCard,
              let newComment = commentTextField.text,
              !newComment.isEmpty else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())

        let formattedComment = "\(timestamp) - \(newComment)"

        comments.append(formattedComment)
        tableView.reloadData()

        let key = "comments_\(pdfCard.url)"
        UserDefaults.standard.set(comments, forKey: key)

        delegate?.didAddComment(formattedComment, for: pdfCard)
        commentTextField.text = ""
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension CommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = comments[indexPath.row]
        cell.backgroundColor = .white
        cell.textLabel?.textColor = .black
        return cell
    }
}
