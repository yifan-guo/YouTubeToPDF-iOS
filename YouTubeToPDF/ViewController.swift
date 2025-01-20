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
                                
                                // Poll for the result (the presigned URL)
                                let startTime = Date()      // Capture the start time when polling begins
                                self.pollForResult(executionId: executionId, startTime: startTime)
                            }
                        } else {
                            // Handle non-202 status codes
                            print("Error: Received status code \(statusCode)")
                            self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                            return
                        }
                    } else {
                        // Handle missing statuscode
                        print("Response is missing statusCode")
                        if let errorBody = String(data: data, encoding: .utf8) {
                            print("Response body: \(errorBody)")
                        }
                        self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                    }
                } else {
                    print("Unexpected response structure")
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("Response body: \(errorBody)")
                    }
                    self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                }
            } catch {
                print("Error parsing Step Function response: \(error)")
                self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
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
    
    /*
     Retry for up to 15 minutes. We'll keep track of the time elapsed and ensure we don't keep retrying past 15 minutes.
     Stop retrying if the status code is not 200. We'll check if the response status code is not 200, and then stop the retries.
     If the response is valid (status 200), proceed with extracting the presigned_url and open the PDF.
     */
    func pollForResult(executionId: String, startTime: Date, timeOutInterval: Double = 900) {
        // Poll for the result of the Step Function execution
        guard let url = URL(string: "\(pollingUrl)/\(executionId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60 // Set timeout to 1 minute (adjust as needed)
        
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
                // Parse the response to extract the presignedUrl
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let statusCode = responseDict["statusCode"] as? Int {
                        if statusCode == 200 {
                            if let status = responseDict["status"] as? String {
                                if status == "SUCCEEDED" {
                                    // Successfully completed execution
                                    if let body = responseDict["body"] as? String,
                                       let jsonData = body.data(using: .utf8),
                                       let bodyDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                                       let presignedUrl = bodyDict["presigned_url"] as? String {
                                        print("Presigned URL received: \(presignedUrl)")
                                        
                                        // Open the PDF using the presigned URL
                                        self.openPDF(presignedUrl)
                                        return
                                    }
                                } else if status == "RUNNING" {
                                    // If it's still running, keep polling
                                    print("Step Function is still running. Retrying...")
                                    
                                    // Check if 15 minutes have passed
                                    let elapsedTime = Date().timeIntervalSince(startTime)
                                    if elapsedTime >= timeOutInterval {
                                        print("15 minutes have passed. Stopping polling.")
                                        self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                                        return
                                    }
                                    
                                    // Retry polling after a short delay (e.g., 15 seconds)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                                        self.pollForResult(executionId: executionId, startTime: startTime)
                                    }
                                } else {
                                    print("Unexpected status: \(status)")
                                    self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                                    return
                                }
                            } else {
                                print("Missing or invalid status. Stopping polling.")
                                if let errorBody = String(data: data, encoding: .utf8) {
                                    print("Response Body: \(errorBody)")
                                }
                                self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                                return
                            }
                        } else {
                            // If statusCode is not 200
                            print("Received failed status code \(statusCode). Stopping polling.")
                            if let message = responseDict["message"] as? String {
                                print("Error message: \(message)")
                            }
                            self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                            return
                        }
                    } else {
                        print("Error: Missing or invalid statusCode. Retrying...")
                        if let errorBody = String(data: data, encoding: .utf8) {
                            print("Response Body: \(errorBody)")
                        }
                    }
                } else {
                    print("Unable to parse the response body. Retrying...")
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("Response Body: \(errorBody)")
                    }
                }
                
                // Check if 15 minutes (900 seconds) have passed
                let elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime >= timeOutInterval {
                    print("15 minutes have passed. Stopping polling.")
                    self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
                    return
                }
        
                // Poll again in 15 seconds if status is not complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    self.pollForResult(executionId: executionId, startTime: startTime)
                }
            } catch {
                print("Error parsing polling result: \(error)")
                self.showErrorAlert(message: "An error occurred while processing your request. Please try again later.")
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
