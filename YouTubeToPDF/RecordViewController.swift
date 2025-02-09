import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordButton: UIButton!
    var submitButton: UIButton!
    var waveformView: WaveformView!
    var audioRecorder: AVAudioRecorder?
    var audioFileUrl: URL?
    
    let apiUploadURL = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/upload-audio" // Replace with your API

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestAudioPermission()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        // Back Button (only needed if modal)
        if navigationController == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissView))
        }

        // Waveform View
        waveformView = WaveformView(frame: CGRect(x: 20, y: 150, width: view.frame.width - 40, height: 150))
        waveformView.backgroundColor = .clear
        view.addSubview(waveformView)
        
        // Record Button
        recordButton = UIButton(type: .custom)
        recordButton.frame = CGRect(x: (view.frame.width - 80) / 2, y: 350, width: 80, height: 80)
        recordButton.layer.cornerRadius = 40
        recordButton.backgroundColor = .red
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        view.addSubview(recordButton)
        
        // Submit Button (Disabled Initially)
        submitButton = UIButton(type: .system)
        submitButton.frame = CGRect(x: (view.frame.width - 150) / 2, y: 450, width: 150, height: 50)
        submitButton.setTitle("Submit Audio", for: .normal)
        submitButton.isEnabled = false
        submitButton.alpha = 0.5 // Visually indicate disabled state
        submitButton.addTarget(self, action: #selector(submitAudio), for: .touchUpInside)
        view.addSubview(submitButton)
    }
    
    func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied")
            }
        }
    }
    
    @objc func toggleRecording() {
        if audioRecorder == nil {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
        audioFileUrl = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            recordButton.backgroundColor = .gray  // Change color to indicate recording
            submitButton.isEnabled = false  // Disable submit while recording
            submitButton.alpha = 0.5
            startWaveformUpdates()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        recordButton.backgroundColor = .red  // Change color back
        submitButton.isEnabled = true  // Enable submit after recording stops
        submitButton.alpha = 1.0
    }
    
    @objc func submitAudio() {
        guard let audioUrl = audioFileUrl else {
            print("❌ No recorded audio file found")
            return
        }

        // API Endpoint
        guard var urlComponents = URLComponents(string: apiUploadURL) else {
            print("❌ Invalid API URL")
            return
        }

        // Retrieve device token
        guard let deviceToken = (UIApplication.shared.delegate as? AppDelegate)?.deviceToken else {
            print("❌ Device token not available")
            return
        }

        // Add deviceToken as a query parameter
        urlComponents.queryItems = [URLQueryItem(name: "deviceToken", value: deviceToken)]
        
        guard let finalUrl = urlComponents.url else {
            print("❌ Failed to construct URL with query parameters")
            return
        }

        print("🌍 API Request URL: \(finalUrl.absoluteString)")

        // Prepare the request
        var request = URLRequest(url: finalUrl)
        request.httpMethod = "POST"

        // Generate a unique boundary string
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = "recording.wav"
        let mimetype = "audio/wav"

        // Add newline before boundary to fix the issue
        // https://stackoverflow.com/questions/53500627/malformedstreamexception-stream-ended-unexpectedly ("After some debugging...")
        // Read the source code for MultipartStream
        body.append("\r\n".data(using: .utf8)!) // Add this line for the newline
        
        // Multipart form-data headers
        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)

        do {
            let audioData = try Data(contentsOf: audioUrl)
            body.append(audioData)
            print("🎵 Audio file size: \(audioData.count) bytes")
        } catch {
            print("❌ Error reading audio file: \(error.localizedDescription)")
            return
        }

        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        print("body: \(body)")

        // Set HTTP body
        request.httpBody = body

        print("Generated boundary: \(boundary)")
        print("Content-Type Header: multipart/form-data; boundary=\(boundary)")
        print("📦 Request Body Size: \(body.count) bytes")

        // Print a readable version of the request body
        if let bodyString = String(data: body, encoding: .utf8) {
            print("📜 Request Body (truncated for readability):")
            print(bodyString.prefix(500)) // Print first 500 characters for debugging
        } else {
            print("⚠️ Request body contains non-text data (binary audio file)")
        }

        print("📄 Headers: \(request.allHTTPHeaderFields ?? [:])")

        // Execute the upload task
        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response Status Code: \(httpResponse.statusCode)")
                if let responseBody = data, let responseText = String(data: responseBody, encoding: .utf8) {
                    print("📥 Response Body: \(responseText)")
                }

                if httpResponse.statusCode == 200 {
                    print("✅ Audio upload successful!")
                } else {
                    print("⚠️ Error: Received status code \(httpResponse.statusCode)")
                }
            }
        }

        task.resume()
    }

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func startWaveformUpdates() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard let recorder = self.audioRecorder else {
                timer.invalidate()
                return
            }
            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)
            let normalizedLevel = max(0, min(1, (level + 60) / 60))  // Normalize between 0 and 1
            self.waveformView.addWaveformLevel(level: CGFloat(normalizedLevel))
        }
    }

    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
