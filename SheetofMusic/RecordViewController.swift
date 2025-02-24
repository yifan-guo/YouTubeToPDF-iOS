import UIKit
import AVFoundation
import UserNotifications
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate {

    var recordButton: UIButton!
    var deleteButton: UIButton!
    var submitButton: UIButton!
    var playButton: UIButton!
    var waveformView: WaveformView!
    var audioRecorder: AVAudioRecorder?
    var audioFileUrl: URL?
    var audioPlayer: AVAudioPlayer?

    let apiUploadURL = "https://bnwc9iszkk.execute-api.us-east-2.amazonaws.com/prod/upload-audio" // Replace with your API

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestAudioPermission()
        requestNotificationPermission()
    }

    func setupUI() {
        view.backgroundColor = .white
        self.title = "Record"

        let label = UILabel()
        label.text = "Record Tab"
        self.view.addSubview(label)

        if navigationController == nil {
            print("❌ navigationController is nil!")
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissView))
        }

        waveformView = WaveformView(frame: CGRect(x: 20, y: 150, width: view.frame.width - 40, height: 150))
        waveformView.backgroundColor = .clear
        view.addSubview(waveformView)

        recordButton = UIButton(type: .custom)
        recordButton.frame = CGRect(x: (view.frame.width - 80) / 2, y: 350, width: 80, height: 80)
        recordButton.layer.cornerRadius = 40
        recordButton.backgroundColor = .red
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        view.addSubview(recordButton)

        // Create a container for the submit and delete buttons
        let buttonsContainer = UIView()
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsContainer)

        // Apply constraints to position the container below the record button
        NSLayoutConstraint.activate([
            buttonsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonsContainer.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            buttonsContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            // Adjust buttonsContainer height to accommodate the new Play button
            buttonsContainer.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Create Submit Button
        submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit Audio", for: .normal)
        submitButton.isHidden = true
        submitButton.addTarget(self, action: #selector(submitAudio), for: .touchUpInside)
        submitButton.layer.cornerRadius = 10
        submitButton.layer.borderWidth = 1
        submitButton.layer.borderColor = UIColor.green.cgColor
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        buttonsContainer.addSubview(submitButton)

        // Add green icon to submit button
        let submitIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        submitIcon.tintColor = .green
        submitIcon.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addSubview(submitIcon)

        // Set constraints for Submit Button and Icon
        NSLayoutConstraint.activate([
            submitButton.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            submitButton.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            submitButton.bottomAnchor.constraint(equalTo: buttonsContainer.centerYAnchor),
            submitButton.widthAnchor.constraint(equalTo: buttonsContainer.widthAnchor, multiplier: 0.45),
            
            submitIcon.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
            submitIcon.leadingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: 10),
            submitIcon.widthAnchor.constraint(equalToConstant: 20),
            submitIcon.heightAnchor.constraint(equalToConstant: 20)
        ])

        // Create Delete Button
        deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete Recording", for: .normal)
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteRecording), for: .touchUpInside)
        deleteButton.layer.cornerRadius = 10
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.red.cgColor
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.addSubview(deleteButton)

        // Add red icon to delete button
        let deleteIcon = UIImageView(image: UIImage(systemName: "trash.fill"))
        deleteIcon.tintColor = .red
        deleteIcon.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addSubview(deleteIcon)
        
        // Space between delete icon and text
        deleteButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)

        // Set constraints for Delete Button and Icon
        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: submitButton.trailingAnchor, constant: 10),
            deleteButton.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: buttonsContainer.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalTo: buttonsContainer.widthAnchor, multiplier: 0.5),

            deleteIcon.centerYAnchor.constraint(equalTo: deleteButton.centerYAnchor),
            deleteIcon.leadingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: 10),
            deleteIcon.widthAnchor.constraint(equalToConstant: 20),
            deleteIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Create Play Button
        playButton = UIButton(type: .system)
        playButton.setTitle("Play Recording", for: .normal)
        playButton.isHidden = true
        playButton.addTarget(self, action: #selector(playRecording), for: .touchUpInside)
        playButton.layer.cornerRadius = 10
        playButton.layer.borderWidth = 1
        playButton.layer.borderColor = UIColor.blue.cgColor
        playButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.addSubview(playButton)
        
        // Add blue icon to play button
        let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        playIcon.tintColor = .blue
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playButton.addSubview(playIcon)
        
        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: buttonsContainer.centerYAnchor, constant: 10),
            playButton.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor),
            playButton.centerXAnchor.constraint(equalTo: buttonsContainer.centerXAnchor),
            playButton.widthAnchor.constraint(equalTo: buttonsContainer.widthAnchor, multiplier: 0.45),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            playIcon.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            playIcon.leadingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: 10),
            playIcon.widthAnchor.constraint(equalToConstant: 20),
            playIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied")
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
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

            recordButton.backgroundColor = .gray
            startWaveformUpdates()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil

        recordButton.backgroundColor = .lightGray
        recordButton.isEnabled = false
        
        submitButton.isHidden = false
        deleteButton.isHidden = false
        playButton.isHidden = false
    }

    @objc func deleteRecording() {
        if let audioUrl = audioFileUrl {
            try? FileManager.default.removeItem(at: audioUrl)
        }
        waveformView.clearWaveform()
        resetUIAfterDelete()
    }
    
    @objc func playRecording() {
        print("tapped")
        guard let audioUrl = audioFileUrl else {
            print("No recorded audio file found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }


    func resetUIAfterDelete() {
        recordButton.backgroundColor = .red
        recordButton.isEnabled = true
        
        submitButton.isHidden = true
        deleteButton.isHidden = true
        playButton.isHidden = true
    }

    @objc func submitAudio() {
        guard let audioUrl = audioFileUrl else {
            print("❌ No recorded audio file found")
            sendErrorNotification(message: "No recorded audio file found. Please record audio before submitting.")
            return
        }
        
        DispatchQueue.main.async {
            self.submitButton.isEnabled = false
            self.submitButton.setTitle("Uploading...", for: .disabled)
        }

        sendSubmissionStartedNotification()

        DispatchQueue.global(qos: .background).async {
            self.uploadAudioFile(audioUrl: audioUrl)
        }
    }

    func uploadAudioFile(audioUrl: URL) {
        defer {
            DispatchQueue.main.async {
                self.submitButton.isEnabled = true
                self.submitButton.setTitle("Submit Audio", for: .normal)
            }
        }
        
        guard var urlComponents = URLComponents(string: apiUploadURL) else {
            print("❌ Invalid API URL")
            sendErrorNotification(message: "Invalid API URL. Please try again later.")
            return
        }

        guard let deviceToken = (UIApplication.shared.delegate as? AppDelegate)?.deviceToken else {
            print("❌ Device token not available")
            sendErrorNotification(message: "Device token not available. Please restart the app and try again.")
            return
        }

        urlComponents.queryItems = [URLQueryItem(name: "deviceToken", value: deviceToken)]
        guard let finalUrl = urlComponents.url else {
            print("❌ Failed to construct URL with query parameters")
            sendErrorNotification(message: "Failed to construct URL. Please try again later.")
            return
        }

        var request = URLRequest(url: finalUrl)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = "recording.wav"
        let mimetype = "audio/wav"

        body.append("\r\n".data(using: .utf8)!)
        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)

        do {
            let audioData = try Data(contentsOf: audioUrl)
            body.append(audioData)
        } catch {
            print("❌ Error reading audio file: \(error.localizedDescription)")
            sendErrorNotification(message: "Error reading audio file. Please try recording again.")
            return
        }

        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
                self.sendErrorNotification(message: "Upload failed: \(error.localizedDescription). Please try again.")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Audio upload successful!")
                self.sendSuccessNotification()
            } else {
                print("⚠️ Upload failed with response: \(response.debugDescription)")
                self.sendErrorNotification(message: "Upload failed. Please try again later.")
            }
        }
        task.resume()
    }

    func sendSubmissionStartedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Submission Started"
        content.body = "Your audio recording is being submitted..."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send submission started notification: \(error.localizedDescription)")
            }
        }
    }

    // The code uses local notifications, specifically in the sendSuccessNotification() method. This method creates a UNMutableNotificationContent object and schedules it immediately using UNUserNotificationCenter.
    // The local notification would be scheduled and displayed even if the app is in the background.
    func sendSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Upload Successful"
        content.body = "Your audio recording has been submitted successfully."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send success notification: \(error.localizedDescription)")
            } else {
                print("✅ Success notification sent successfully.")
            }
        }
    }

    func sendErrorNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Upload Error"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send error notification: \(error.localizedDescription)")
            } else {
                print("✅ Error notification sent successfully.")
            }
        }
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
            let normalizedLevel = max(0, min(1, (level + 60) / 60))
            self.waveformView.addWaveformLevel(level: CGFloat(normalizedLevel))
        }
    }

    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

