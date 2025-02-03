//
//  AboutView.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/31/25.
//


import SwiftUI

struct AboutView: View {
    var appName: String {
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        } else {
            return "Oh One Pro"
        }
    }

    var appVersion: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        {
            return "\(version) (build \(build))"
        } else {
            return "1.0"
        }
    }

    var body: some View {
        VStack {
            // App icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .padding(.top, 16)
            
            VStack {
                // App name and version
                Text(appName)
                    .font(.largeTitle)
                    .padding(.top, 4)
                
                // App version
                Text("Version \(appVersion)")
                    .font(.headline)
                    .fontWeight(.regular)
                    .padding(.bottom, 4)
            }.padding(.bottom, 8)
            
            HStack(spacing: 0) {
                Text("Made by ")
                Text("[Daniel Nguyen](https://twitter.com/daniel_nguyenx) and 🤖 [BoltAI](https://boltai.com?utm_source=ohonepro)")
            }
            
            HStack {
                Button(action: {
                    openLink("https://ohonepro.com")
                }) {
                    Text("Website")
                }
                
                Button(action: {
                    openLink("https://ohonepro.com/acknowledgement")
                }) {
                    Text("Acknowledgement")
                }
                
                Button(action: {
                    openLink("https://twitter.com/daniel_nguyenx")
                }) {
                    Text("Twitter")
                }
                
                Button(action: {
                    openLink("https://boltai.com/buy?utm_source=ohonepro")
                }) {
                    Text("✨ Upgrade")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .padding()
        .frame(minWidth: 420, minHeight: 320)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }
    
    private func openLink(_ url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
