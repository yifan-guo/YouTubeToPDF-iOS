import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var youtubeUrlTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    // API URLs
    let apiGatewayUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/convert"
    let pollingUrl = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/status"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let youtubeUrl = youtubeUrlTextField.text, !youtubeUrl.isEmpty else {
            print("YouTube URL is empty")
            return
        }
        
        // Disable the button to prevent multiple submissions
        submitButton.isEnabled = false
        
        // Trigger the API call to start the process
        submitYouTubeUrl(youtubeUrl)
    }
    
    func submitYouTubeUrl(_ youtubeUrl: String) {
        // Trigger the Step Function via API Gateway
        triggerStepFunction(youtubeUrl: youtubeUrl)
    }
    
    func triggerStepFunction(youtubeUrl: String) {
        guard let url = URL(string: apiGatewayUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add body with YouTube URL or other required parameters
        let requestBody: [String: Any] = ["youtube_url": youtubeUrl]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
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
            
            guard let data = data else {
                print("No data received from Step Function")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if no data
                }
                return
            }
            
            do {
                // Parse the response to extract the execution ID or task status
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let executionId = responseDict["executionId"] as? String {
                    // Store the execution ID for polling the status later
                    print("Step Function triggered successfully. Execution ID: \(executionId)")
                    
                    // Poll for the result (the presigned URL)
                    self.pollForResult(executionId: executionId)
                }
            } catch {
                print("Error parsing Step Function response: \(error)")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if error occurs
                }
            }
        }
        
        task.resume()
    }
    
    func pollForResult(executionId: String) {
        // Poll for the result of the Step Function execution
        guard let url = URL(string: "\(pollingUrl)/\(executionId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error polling for result: \(error)")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if error occurs
                }
                return
            }
            
            guard let data = data else {
                print("No data received while polling")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if no data
                }
                return
            }
            
            do {
                // Parse the response to extract the presigned URL
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let presignedUrl = responseDict["presigned_url"] as? String {
                    print("Presigned URL received: \(presignedUrl)")
                    
                    // Open the PDF using the presigned URL
                    self.openPDF(presignedUrl)
                }
            } catch {
                print("Error parsing polling result: \(error)")
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true // Re-enable button if error occurs
                }
            }
        }
        
        task.resume()
    }
    
    func openPDF(_ url: String) {
        // Use Safari or WebView to open the presigned URL
        if let url = URL(string: url) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
}
