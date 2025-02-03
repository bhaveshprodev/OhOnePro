//
//  AppState.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/31/25.
//

import Foundation
import Sparkle

class AppState {
    static let shared = AppState()
    
    // MARK: Updater
    private var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
