import UIKit
import AVFoundation
import UserNotifications

class RecordViewController: UIViewController, AVAudioRecorderDelegate {

    var recordButton: UIButton!
    var deleteButton: UIButton!
    var submitButton: UIButton!
    var waveformView: WaveformView!
    var audioRecorder: AVAudioRecorder?
    var audioFileUrl: URL?

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

        submitButton = UIButton(type: .system)
        submitButton.frame = CGRect(x: (view.frame.width - 150) / 2, y: 450, width: 150, height: 50)
        submitButton.setTitle("Submit Audio", for: .normal)
        submitButton.isEnabled = false
        submitButton.alpha = 0.5
        submitButton.addTarget(self, action: #selector(submitAudio), for: .touchUpInside)
        view.addSubview(submitButton)

        deleteButton = UIButton(type: .system)
        deleteButton.frame = CGRect(x: (view.frame.width - 150) / 2, y: 510, width: 150, height: 50)
        deleteButton.setTitle("Delete Recording", for: .normal)
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteRecording), for: .touchUpInside)
        view.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
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
            submitButton.isEnabled = false
            submitButton.alpha = 0.5
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
        submitButton.isEnabled = true
        submitButton.alpha = 1.0
        deleteButton.isHidden = false
    }

    @objc func deleteRecording() {
        if let audioUrl = audioFileUrl {
            try? FileManager.default.removeItem(at: audioUrl)
        }
        waveformView.clearWaveform()
        resetUIAfterDelete()
    }

    func resetUIAfterDelete() {
        recordButton.backgroundColor = .red
        recordButton.isEnabled = true
        submitButton.isEnabled = false
        submitButton.alpha = 0.5
        deleteButton.isHidden = true
    }

    @objc func submitAudio() {
        guard let audioUrl = audioFileUrl else {
            print("❌ No recorded audio file found")
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.uploadAudioFile(audioUrl: audioUrl)
        }
    }

    func uploadAudioFile(audioUrl: URL) {
        guard var urlComponents = URLComponents(string: apiUploadURL) else {
            print("❌ Invalid API URL")
            return
        }

        guard let deviceToken = (UIApplication.shared.delegate as? AppDelegate)?.deviceToken else {
            print("❌ Device token not available")
            return
        }

        urlComponents.queryItems = [URLQueryItem(name: "deviceToken", value: deviceToken)]
        guard let finalUrl = urlComponents.url else {
            print("❌ Failed to construct URL with query parameters")
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
            return
        }

        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Audio upload successful!")
                self.sendSuccessNotification()
            } else {
                print("⚠️ Upload failed with response: \(response.debugDescription)")
            }
        }
        task.resume()
    }

    func sendSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Upload Successful"
        content.body = "Your audio recording has been submitted successfully."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification sent successfully.")
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

