//
//  Constant.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/28/25.
//

import Foundation
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let toggleOhOnePro = Self("toggleOhOnePro")
}

extension NSApplication {
    static func setDockIconVisible(_ visible: Bool) {
        if visible {
            NSApp.setActivationPolicy(.regular)
            NSApp.presentationOptions = []
            NSMenu.setMenuBarVisible(false)
            NSMenu.setMenuBarVisible(true)
        } else {
            NSApp.setActivationPolicy(.accessory)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            NSApp.keyWindow?.orderFrontRegardless()
        }
    }
}
