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
        }
    }
}
