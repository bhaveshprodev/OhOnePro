//
//  AppDelegate.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/28/25.
//
import AppKit
import KeyboardShortcuts
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var aboutWindow: NSWindow?
    var window: FloatingPanel?
    var statusItem: NSStatusItem?
    
    // Shake detector instance (optional now)
    private var shakeDetector: CursorShakeDetector?
    private var defaultsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Observe status item toggle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusItemToggle),
            name: .toggleStatusItem,
            object: nil
        )
        
        // Observe UserDefaults changes for shake setting
        defaultsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateShakeDetectorState()
        }
        
        setupStatusBar()
        setupWindow()
        
        // Initialize based on current setting
        updateShakeDetectorState()
        
        KeyboardShortcuts.onKeyUp(for: .toggleOhOnePro) { [weak self] in
            self?.toggleWindow()
        }
    }
    
    deinit {
        if let observer = defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // shakeDetector's deinit will handle monitor removal
    }
    
    // Method to enable/disable shake detector based on UserDefaults
    private func updateShakeDetectorState() {
        let shouldEnable = UserDefaults.standard.bool(forKey: "enableShakeToShow")
        // Read the sensitivity distance, providing a default if not set
        let sensitivityDistance = UserDefaults.standard.double(forKey: "shakeSensitivityDistance")
        let distanceThreshold = (sensitivityDistance > 0) ? sensitivityDistance : 600.0 // Ensure non-zero, default 600
        
        if shouldEnable {
            // Check if detector exists and if its distance needs updating
            // Or simply recreate it if enabled, ensuring it always has the latest setting
            if shakeDetector == nil || shakeDetector?.distance != CGFloat(distanceThreshold) { // Check if distance differs
                 print("Enabling/Updating shake detector with distance: \(distanceThreshold)")
                 // Recreate the detector with the current sensitivity
                 shakeDetector = CursorShakeDetector(distanceThreshold: CGFloat(distanceThreshold)) { [weak self] in
                     self?.showWindowAtMouse()
                 }
            }
        } else {
            if shakeDetector != nil {
                print("Disabling shake detector")
                shakeDetector = nil 
            }
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
                window.center() // Keep centering for keyboard shortcut toggle
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
    
    // MARK: About Window

    func showAbout() {
        if let aboutWindow {
            aboutWindow.makeKeyAndOrderFront(nil)
        } else {
            aboutWindow = .init(contentRect: NSRect(x: 300, y: 300, width: 300, height: 300), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            aboutWindow?.titleVisibility = .hidden
            aboutWindow?.titlebarAppearsTransparent = true
            aboutWindow?.isMovableByWindowBackground = true
            
            aboutWindow?.contentViewController = NSHostingController(
                rootView: AboutView()
                    .ignoresSafeArea()
            )
            aboutWindow?.delegate = self
            aboutWindow?.center()
            aboutWindow?.makeKeyAndOrderFront(nil)
        }
    }

    // Modified to ensure activation before showing
    private func showWindowAtMouse() {
        guard let window = window else { return }

        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.screens.first { $0.frame.contains(mouseLocation) }?.frame ?? NSRect.zero
        let windowSize = window.frame.size

        var xPos = mouseLocation.x - windowSize.width / 2
        var yPos = mouseLocation.y - windowSize.height / 2

        xPos = max(screenFrame.minX, min(xPos, screenFrame.maxX - windowSize.width))
        yPos = max(screenFrame.minY, min(yPos, screenFrame.maxY - windowSize.height))

        let origin = NSPoint(x: xPos, y: yPos)

        DispatchQueue.main.async {
            // Activate first, as recommended
            NSApp.activate(ignoringOtherApps: true)
            window.setFrameOrigin(origin)
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFront(nil) // Move if already visible
            }
        }
    }
}

// MARK: - Cursor Shake Detector (Drop-in helper from o3)

final class CursorShakeDetector {
    private var monitor: Any?
    private var samples: [(t: TimeInterval, dx: CGFloat, dy: CGFloat)] = []
    private let window: TimeInterval = 0.30        // seconds to look back
    let distance: CGFloat                  // Changed to non-constant
    private let minReversals           = 3         // direction flips needed
    
    // Modified init to accept distance
    init(distanceThreshold: CGFloat, onShake: @escaping () -> Void) {
        self.distance = distanceThreshold // Assign the passed value
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged, .otherMouseDragged]) { [weak self] ev in
                self?.process(ev, trigger: onShake)
            }
    }
    
    deinit { monitor.map(NSEvent.removeMonitor) }
    
    private func process(_ ev: NSEvent, trigger: () -> Void) {
        // keep a sliding window of recent deltas
        samples.append((ev.timestamp, ev.deltaX, ev.deltaY))
        let now = ev.timestamp
        while let first = samples.first, now - first.t > window { samples.removeFirst() }
        
        // 1. accumulated path length
        let total = samples.reduce(CGFloat.zero) { $0 + abs($1.dx) + abs($1.dy) }
        guard total > distance else { return }
        
        // 2. make sure the pointer has changed direction several times
        let xs = samples.map(\.dx)
        var reversals = 0
        for i in 1 ..< xs.count where xs[i] * xs[i - 1] < 0 { reversals += 1 }
        if reversals >= minReversals {
            samples.removeAll() // reset to avoid repeats
            trigger() // show your window here
        }
    }
}
