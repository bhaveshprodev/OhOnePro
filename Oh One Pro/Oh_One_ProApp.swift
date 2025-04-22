//
//  Oh_One_ProApp.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/26/25.
//

import SwiftUI
import AppKit

@main
struct Oh_One_ProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .frame(width: 500)
                .frame(minHeight: 530)
                .frame(maxHeight: 600)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button("About Oh One Pro") {
                    appDelegate.showAbout()
                }
            }
            
            CommandGroup(after: CommandGroupPlacement.appInfo) {
                Button("Check for Updates...") {
                    AppState.shared.checkForUpdates()
                }
            }
        }
    }
}
