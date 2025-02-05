//
//  AVAudioRecorder.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 2/4/25.
//

import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var recordedFileURL: URL?
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? audioSession.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,  // Use WAV format
            AVSampleRateKey: 44100,  // Standard sample rate for WAV
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,  // Standard bit depth
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        let filename = UUID().uuidString + ".wav"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        recordedFileURL = fileURL

        audioRecorder = try? AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

