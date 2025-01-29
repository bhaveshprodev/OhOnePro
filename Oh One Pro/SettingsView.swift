import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts
import AppKit

struct SettingsView: View {
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("hideDockIcon") private var hideDockIcon = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                LaunchAtLogin.Toggle()
                
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                
                Toggle("Auto hide dock icon", isOn: $hideDockIcon)
                    .disabled(!showMenuBarIcon)
                
                KeyboardShortcuts.Recorder("Toggle Oh One Pro", name: .toggleOhOnePro)
                
//                HStack {
//                    Text("©2025 BoltAI")
//                    
//                    Spacer()
//                    
//                    Link("Visit BoltAI Website", destination: URL(string: "https://boltai.com?ref=ohonepro")!)
//                        .foregroundColor(.blue)
//                }
                
                Text("Oh One Pro is an app by BoltAI. If you find the app useful, consider sharing BoltAI with your friends and colleagues. [Visit BoltAI Website](https://boltai.com?ref=ohonepro)")
            }
            .formStyle(.grouped)
            .onChange(of: hideDockIcon) { hidden in
                NSApplication.setDockIconVisible(!hidden)
                // Keep the window level above dock level to remain visible
                if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
                    window.level = .floating
                }
            }
            .onChange(of: showMenuBarIcon) { show in
                if !show {
                    // If hiding menu bar icon, ensure dock icon is visible
                    hideDockIcon = false
                }
                NotificationCenter.default.post(name: .toggleStatusItem, 
                                             object: nil, 
                                             userInfo: ["show": show])
            }
        }
        .frame(width: 400, height: 280)
    }
}

#Preview {
    SettingsView()
} 
