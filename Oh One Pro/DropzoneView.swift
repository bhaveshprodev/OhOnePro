//
//  DropzoneView.swift
//  Oh One Pro
//
//  Created by Daniel Nguyen on 1/26/25.
//

import SwiftUI
import PDFKit

struct DropzoneView: View {
    @State private var droppedURLs: [URL] = []
    @State private var isDropTargeted = false
    @State private var pdfDocuments: [PDFDocument] = []
    @State private var previewImages: [NSImage] = []
    @State private var isHovering = false
    @State private var textContents: [String] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    // hide
                    if let window = NSApp.keyWindow {
                        reset()
                        window.close()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .controlSize(.large)
                
                Spacer()

                Text("Oh One Pro")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("Clear All Items") {
                        reset()
                    }
                    Button("Settings...") {
                        openSettings()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .controlSize(.large)
            }
            
            Spacer()
            
            VStack(alignment: .center) {
                if !previewImages.isEmpty {
                    // Stack of up to 3 thumbnails
                    ZStack {
                        // Show up to 3 thumbnails in a stack
                        ForEach(Array(previewImages.prefix(3).enumerated()), id: \.offset) { index, image in
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .shadow(radius: 2)
                                .rotationEffect(.degrees(Double(index) * 3))
                                .offset(x: Double(index) * 10, y: Double(index) * -10)
                        }
                        
                        // Action buttons
                        if !droppedURLs.isEmpty {
                            VStack(spacing: 12) {
                                Button(action: copyText) {
                                    Label("Copy as Text", systemImage: "doc.text")
                                        .frame(maxWidth: .infinity)
                                        .labelStyle(.titleOnly)
                                }
                                .buttonStyle(.bordered)
                                .clipShape(.capsule)
                                .controlSize(.large)
                                .tint(.accentColor)
                                .shadow(radius: 1)
                                
                                // Only show Copy as Images for PDFs
                                if !pdfDocuments.isEmpty && pdfDocuments.allSatisfy({ $0.pageCount > 0 }) {
                                    Button(action: copyImages) {
                                        Label("Copy as Images", systemImage: "photo")
                                            .frame(maxWidth: .infinity)
                                            .labelStyle(.titleOnly)
                                    }
                                    .buttonStyle(.bordered)
                                    .clipShape(.capsule)
                                    .controlSize(.large)
                                    .tint(.accentColor)
                                    .shadow(radius: 1)
                                }
                            }
                            .frame(maxWidth: 180)
                            .padding(.bottom, 8)
                            .opacity(isHovering ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: isHovering)
                        }
                    }
                    .frame(width: 140, height: 160)
                    
                    Text("^[\(droppedURLs.count) documents](inflect: true)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    dropZone
                }
            }
            
            Spacer()
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .padding(.horizontal, 10)
        .modifier(CustomWindowStyle())
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            let wasEmpty = droppedURLs.isEmpty
            
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    guard error == nil, let url = url else { return }
                    
                    DispatchQueue.main.async {
                        handleDroppedFile(url)
                    }
                }
            }
            return true
        }
    }
    
    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            
            VStack(spacing: 12) {
                Image(systemName: "rectangle.and.text.magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)
                
                Text("Drop Documents")
                    .font(.caption)
                    .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)
            }
        }
        .animation(.smooth, value: isDropTargeted)
    }
    
    private func reset() {
        droppedURLs = []
        pdfDocuments = []
        previewImages = []
        textContents = []
    }
    
    private func handleDroppedFile(_ url: URL) {
        if url.pathExtension.lowercased() == "pdf" {
            if let pdf = PDFDocument(url: url) {
                droppedURLs.append(url)
                pdfDocuments.append(pdf)
                textContents.append("")
                if let pdfPage = pdf.page(at: 0) {
                    let pageImage = pdfPage.thumbnail(of: CGSize(width: 400, height: 400), for: .artBox)
                    previewImages.append(pageImage)
                }
            }
        } else {
            // Handle text documents
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                droppedURLs.append(url)
                pdfDocuments.append(PDFDocument())  // Empty PDF document as placeholder
                textContents.append(content)
                // Use a generic document icon for text files
                let genericIcon = NSWorkspace.shared.icon(forFileType: url.pathExtension)
                previewImages.append(genericIcon)
            } catch {
                print("Error reading file: \(error)")
            }
        }
    }
    
    private func copyImages() {
        guard !pdfDocuments.isEmpty else { return }
        var temporaryFiles: [URL] = []
        
        // Create a temporary directory for our images
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Calculate total pages across all PDFs
        var totalPages = 0
        for pdf in pdfDocuments {
            totalPages += pdf.pageCount
        }
        
        let pagesPerImage = max(1, Int(ceil(Double(totalPages) / 9.0))) // Leave 1 slot for potential remainder
        var currentPages: [NSImage] = []
        var pageCounter = 0
        
        // Collect pages from all PDFs and stitch them together
        for pdf in pdfDocuments {
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i) {
                    let image = page.thumbnail(of: CGSize(width: 1024, height: 1024), for: .mediaBox)
                    currentPages.append(image)
                    pageCounter += 1
                    
                    // When we have enough pages or it's the last page, stitch and save
                    if currentPages.count == pagesPerImage || pageCounter == totalPages {
                        if let stitchedImage = stitchImages(currentPages) {
                            let fileURL = tempDir.appendingPathComponent("pages_\((pageCounter/pagesPerImage) + 1).jpg")
                            
                            if let cgImage = stitchedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                                if let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
                                    try? imageData.write(to: fileURL)
                                    temporaryFiles.append(fileURL)
                                }
                            }
                        }
                        currentPages.removeAll()
                    }
                }
            }
        }
        
        if !temporaryFiles.isEmpty {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects(temporaryFiles as [NSPasteboardWriting])
            
            // Schedule cleanup after 1 hour
            DispatchQueue.main.asyncAfter(deadline: .now() + 60 * 60) {
                try? FileManager.default.removeItem(at: tempDir)
            }
        }
    }
    
    private func stitchImages(_ images: [NSImage]) -> NSImage? {
        guard !images.isEmpty else { return nil }
        
        // Calculate the total height and maximum width
        var totalHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for image in images {
            totalHeight += image.size.height
            maxWidth = max(maxWidth, image.size.width)
        }
        
        // Create a new image context
        let resultImage = NSImage(size: NSSize(width: maxWidth, height: totalHeight))
        
        resultImage.lockFocus()
        var currentY = totalHeight // Start from top (NSImage coordinate system)
        
        for image in images {
            // Center the image horizontally if it's narrower than the widest image
            let x = (maxWidth - image.size.width) / 2
            currentY -= image.size.height // Move up by the height of the current image
            
            image.draw(in: NSRect(x: x,
                                y: currentY,
                                width: image.size.width,
                                height: image.size.height))
        }
        
        resultImage.unlockFocus()
        return resultImage
    }
    
    private func copyText() {
        do {
            let xmlDoc = XMLDocument(kind: .document)
            let rootElement = XMLElement(name: "files")
            xmlDoc.setRootElement(rootElement)
            
            for (index, url) in droppedURLs.enumerated() {
                let fileElement = XMLElement(name: "file")
                
                // Add file name as attribute
                let nameAttr = XMLNode(kind: .attribute)
                nameAttr.name = "name"
                nameAttr.stringValue = url.lastPathComponent
                fileElement.addAttribute(nameAttr)
                
                // Add content element
                let contentElement = XMLElement(name: "content")
                let text: String
                if url.pathExtension.lowercased() == "pdf" {
                    text = pdfDocuments[index].string ?? ""
                } else {
                    text = textContents[index]
                }
                contentElement.stringValue = text
                
                fileElement.addChild(contentElement)
                rootElement.addChild(fileElement)
            }
            
            // Generate formatted XML string
            let xmlString = xmlDoc.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
            
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(xmlString, forType: .string)
        } catch {
            print("Error generating XML: \(error)")
        }
    }
    
    private func openSettings() {
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
}

#Preview {
    DropzoneView()
        .frame(width: 260, height: 240)
}
