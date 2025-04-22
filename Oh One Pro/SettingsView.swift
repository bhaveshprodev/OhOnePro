import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts
import AppKit

struct SettingsView: View {
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("hideDockIcon") private var hideDockIcon = true
    @AppStorage("enableShakeToShow") private var enableShakeToShow = true
    @AppStorage("shakeSensitivityDistance") private var shakeSensitivityDistance: Double = 300 // Use Double for Slider
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section("General") {
                    LaunchAtLogin.Toggle()
                    
                    Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
                    
                    Toggle("Auto hide dock icon", isOn: $hideDockIcon)
                        .disabled(!showMenuBarIcon)
                }
                
                Section("Interaction") {
                    KeyboardShortcuts.Recorder("Toggle Oh One Pro", name: .toggleOhOnePro)
                    
                    Toggle("Shake to toggle window", isOn: $enableShakeToShow)
                    
                    // Group sensitivity controls
                    VStack(alignment: .leading, spacing: 2) { // Add spacing: 2 for tighter layout
                        // Row 1: Label, Slider, Value
                        HStack { // Use HStack for the main controls
                            // Text("Shake Sensitivity")
                                //.frame(width: 120, alignment: .leading) // Optional fixed width if needed
                            
                            Slider(value: $shakeSensitivityDistance, in: 200...1000, step: 50) {
                                Text("Shake sensitivity")
                            }
                        }
                        
                        // Row 2: Min/Max Labels (Aligned under the slider part)
                        HStack {
                            Text("More sensitive")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer() // Pushes "Less Sensitive" to the right
                            Text("Less sensitive")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        // Add slight padding to align min/max labels visually under the slider
                         .padding(.leading, 200) // Adjust this based on actual appearance if needed
                    }
                    .disabled(!enableShakeToShow) 
                    .padding(.bottom, 5)
                }
                
                Section("About") {
                    HStack {
                        Text("©2025 BoltAI.")
                        
                        Spacer()
                        
                        Link("Acknowledgement", destination: URL(string: "https://ohonepro.com/acknowledgement")!)
                            .foregroundColor(.blue)
                        
                        Link("Privacy Policy", destination: URL(string: "https://ohonepro.com/privacy")!)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Oh One Pro is an app by BoltAI. If you find the app useful, consider sharing BoltAI with your friends and colleagues. [Visit BoltAI Website](https://boltai.com?ref=ohonepro)")
                }
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
    }
}

#Preview {
    SettingsView()
} 
