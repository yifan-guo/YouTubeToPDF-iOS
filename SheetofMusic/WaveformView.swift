//
//  WaveformView.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 2/5/25.
//

import UIKit

class WaveformView: UIView {
    private var levels: [CGFloat] = []
    
    // Method to add a new waveform level to the view
    func addWaveformLevel(level: CGFloat) {
        levels.append(level)
        if levels.count > 50 { levels.removeFirst() }
        setNeedsDisplay()  // This will trigger a redraw of the view
    }
    
    // Method to clear the waveform
    func clearWaveform() {
        levels.removeAll()  // Remove all waveform data
        setNeedsDisplay()    // Trigger a redraw to clear the screen
    }
    
    // Custom drawing method for the waveform
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)  // Clear any existing drawing in the view
        
        let midY = rect.height / 2
        let barWidth: CGFloat = rect.width / CGFloat(levels.count)
        
        // Draw each waveform level
        for (index, level) in levels.enumerated() {
            let height = level * rect.height
            let x = CGFloat(index) * barWidth
            let y = midY - (height / 2)
            
            let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: barWidth, height: height),
                                    cornerRadius: barWidth / 2)
            UIColor.red.setFill()
            path.fill()
        }
    }
}
