//
//  AppDelegate.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/28/25.
//
import AppKit
import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: FloatingPanel?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Observe status item toggle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusItemToggle),
            name: NSNotification.Name("ToggleStatusItem"),
            object: nil
        )
        
        setupStatusBar()
        setupWindow()
        
        KeyboardShortcuts.onKeyUp(for: .toggleOhOnePro) { [weak self] in
            self?.toggleWindow()
        }
    }
    
    @objc private func handleStatusItemToggle(_ notification: Notification) {
        if let show = notification.userInfo?["show"] as? Bool {
            if show {
                setupStatusBar()
            } else {
                if let statusItem = statusItem {
                    NSStatusBar.system.removeStatusItem(statusItem)
                    self.statusItem = nil
                }
            }
        }
    }
    
    private func setupStatusBar() {
        // Only setup if we don't already have a status item
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.and.text.magnifyingglass", accessibilityDescription: "Oh One Pro")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            
            let openItem = NSMenuItem(title: "Open Oh One Pro", action: #selector(toggleWindow), keyEquivalent: "")
            openItem.image = NSImage(systemSymbolName: "rectangle.and.text.magnifyingglass", accessibilityDescription: nil)
            menu.addItem(openItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: "")
            settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
            menu.addItem(settingsItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
            quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
            menu.addItem(quitItem)
            
            menu.popUp(positioning: menu.item(at: 0), at: NSPoint(x: 0, y: sender.bounds.height + 8), in: sender)
        } else {
            toggleWindow()
        }
    }
    
    private func setupWindow() {
        window = FloatingPanel()
        window?.contentViewController = NSHostingController(
            rootView: DropzoneView()
                .ignoresSafeArea()
        )
        window?.delegate = self
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func toggleWindow() {
        if let window = window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        if #available(macOS 14, *) {
            let eventSource = CGEventSource(stateID: .hidSystemState)
            let keyCommand = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x2B, keyDown: true)
            guard let keyCommand else { return }

            keyCommand.flags = .maskCommand
            let event = NSEvent(cgEvent: keyCommand)
            guard let event else { return }

            NSApp.sendEvent(event)
            
            NSApp.activate(ignoringOtherApps: true)
            NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            NSApp.keyWindow?.orderFrontRegardless()
        } else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    // Handle files dropped onto the Dock icon
    func application(_ sender: NSApplication, open urls: [URL]) {
        // Show the window if it's not visible
        if let window = window, !window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // Post notification with the dropped URLs
        NotificationCenter.default.post(
            name: NSNotification.Name("FilesDroppedOnDock"),
            object: nil,
            userInfo: ["urls": urls]
        )
    }
    
    // MARK: WindowDelegate
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide the window instead of closing
        sender.orderOut(nil)
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let autoHideDockIcon = UserDefaults.standard.bool(forKey: "hideDockIcon")
        if autoHideDockIcon {
            NSApplication.setDockIconVisible(false)
        }

        return false
    }
}
