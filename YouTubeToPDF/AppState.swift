//
//  AppState.swift
//  YouTubeToPDF
//
//  Created by Yifan Guo on 1/24/25.
//

import UIKit

class AppState {
    static let shared = AppState()
    
    private init() {}
    
    var shouldShowPopup = false
    var downloadURL: String?
    
    func triggerPopup(with url: String) {
        shouldShowPopup = true
        downloadURL = url
    }
    
    func resetState() {
        shouldShowPopup = false
        downloadURL = nil
    }
}
