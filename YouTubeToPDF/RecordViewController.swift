import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordButton: UIButton!
    var waveformView: WaveformView!
    var audioRecorder: AVAudioRecorder?
    var audioFileUrl: URL?
    
    let apiUploadURL = "https://your-api-endpoint.com/upload" // Replace with your actual API URL

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestAudioPermission()
    }
    
    func setupUI() {
        view.backgroundColor = .white

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
        
        // Submit Button
        let submitButton = UIButton(type: .system)
        submitButton.frame = CGRect(x: (view.frame.width - 150) / 2, y: 450, width: 150, height: 50)
        submitButton.setTitle("Submit Audio", for: .normal)
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
            startWaveformUpdates()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        recordButton.backgroundColor = .red  // Change color back
    }
    
    @objc func submitAudio() {
        guard let audioUrl = audioFileUrl else {
            print("No recorded audio file found")
            return
        }

        var request = URLRequest(url: URL(string: apiUploadURL)!)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = "recording.wav"
        let mimetype = "audio/wav"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        body.append(try! Data(contentsOf: audioUrl))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                return
            }
            print("Upload successful!")
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
}

