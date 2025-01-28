//
//  Oh_One_ProApp.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/26/25.
//

import SwiftUI
import AppKit

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 320),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.title = "Oh One Pro"
        self.backgroundColor = .clear
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
//        self.setFrame(NSRect(x: 100, y: 100, width: 200, height: 300), display: false)
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

struct CustomWindowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 260, minHeight: 220)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            }
//            .clipShape(.rect(cornerRadii: .init(topLeading: 0, bottomLeading: 20, bottomTrailing: 20, topTrailing: 0)))
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct TitleBarView: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color.yellow)
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}



@main
struct Oh_One_ProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
