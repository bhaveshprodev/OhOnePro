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
    @State private var textContents: [String] = []
    @State private var isHovering = false
    @State private var documentProcessor = DocumentProcessor()
    @State private var copyTextFeedback = false
    @State private var copyImageFeedback = false
    @State private var isProcessingImages = false
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
                    
                    Divider()
                    
                    Button("Check for updates...") {
                        AppState.shared.checkForUpdates()
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
                    GeometryReader { geometry in
                        let width = min(geometry.size.width * 0.7, geometry.size.height * 0.5)  // Maintain aspect ratio
                        let height = width * 1.4  // Keep 1:1.4 aspect ratio
                        
                        ZStack {
                            // Show up to 3 thumbnails in a stack, secondary images first
                            ForEach(Array(previewImages.prefix(3).enumerated()).reversed(), id: \.offset) { index, image in
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: width, height: height)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 2)
                                    .rotationEffect(.degrees(index == 0 ? 0 : (index == 1 ? -8 : 8)))
                                    .offset(x: index == 0 ? 0 : (index == 1 ? -width*0.1 : width*0.1), y: index == 0 ? 0 : -height*0.03)
                                    .zIndex(index == 0 ? 1 : 0)  // Main preview on top of secondary images
                            }
                            
                            // Action buttons
                            if !droppedURLs.isEmpty {
                                actionButtons
                                    .frame(maxWidth: width * 1.8)  // Make buttons wider as preview grows
                                    .zIndex(2)  // Buttons always on top of everything
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    }
                    
                    Text("^[\(droppedURLs.count) documents](inflect: true)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    GeometryReader { geometry in
                        dropZone
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
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
                        if isDirectory(url) {
                            handleDroppedFolder(url)
                        } else {
                            handleDroppedFile(url)
                        }
                    }
                }
            }
            return true
        }
        .onAppear {
            // Setup notification observer for Dock drops
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("FilesDroppedOnDock"),
                object: nil,
                queue: .main
            ) { notification in
                if let urls = notification.userInfo?["urls"] as? [URL] {
                    for url in urls {
                        if isDirectory(url) {
                            handleDroppedFolder(url)
                        } else {
                            handleDroppedFile(url)
                        }
                    }
                }
            }
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
        documentProcessor = DocumentProcessor()
    }
    
    private func handleDroppedFolder(_ folderURL: URL) {
        // Check if folder already exists
        if droppedURLs.contains(folderURL) { return }
        
        let fileManager = FileManager.default
        
        // Create a new processor with the folder as root
        documentProcessor = DocumentProcessor(rootURL: folderURL)
        
        // Add the folder URL first, but don't add to preview
        droppedURLs.append(folderURL)
        pdfDocuments.append(PDFDocument())  // Empty PDF document as placeholder
        textContents.append("")  // Empty content for folder
        
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey]) else { return }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    // Skip if file already exists
                    if droppedURLs.contains(fileURL) { continue }
                    
                    // Only process text files for now
                    if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                        droppedURLs.append(fileURL)
                        pdfDocuments.append(PDFDocument())  // Empty PDF document as placeholder
                        textContents.append(content)
                        let genericIcon = NSWorkspace.shared.icon(forFileType: fileURL.pathExtension)
                        previewImages.append(genericIcon)
                        
                        // Add to document processor
                        documentProcessor.addDocument(ProcessedDocument(url: fileURL, content: content, isPDF: false))
                    }
                }
            } catch {
                print("Error accessing file: \(error)")
            }
        }
    }
    
    private func handleDroppedFile(_ url: URL) {
        // Check if file already exists
        if droppedURLs.contains(url) { return }
        
        if url.pathExtension.lowercased() == "pdf" {
            if let pdf = PDFDocument(url: url) {
                droppedURLs.append(url)
                pdfDocuments.append(pdf)
                textContents.append("")
                if let pdfPage = pdf.page(at: 0) {
                    let pageImage = pdfPage.thumbnail(of: CGSize(width: 400, height: 400), for: .artBox)
                    previewImages.append(pageImage)
                }
                // Add to document processor
                documentProcessor.addDocument(ProcessedDocument(url: url, content: pdf.string ?? "", isPDF: true))
            }
        } else {
            // Handle text documents
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                droppedURLs.append(url)
                pdfDocuments.append(PDFDocument())  // Empty PDF document as placeholder
                textContents.append(content)
                let genericIcon = NSWorkspace.shared.icon(forFileType: url.pathExtension)
                previewImages.append(genericIcon)
                // Add to document processor
                documentProcessor.addDocument(ProcessedDocument(url: url, content: content, isPDF: false))
            } catch {
                print("Error reading file: \(error)")
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                copyText()
                withAnimation {
                    copyTextFeedback = true
                }
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        copyTextFeedback = false
                    }
                }
            }) {
                Label(copyTextFeedback ? "Copied!" : "Copy as Text", systemImage: copyTextFeedback ? "checkmark" : "doc.text")
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
                Button(action: {
                    Task { @MainActor in
                        // Start with UI update on main thread
                        isProcessingImages = true
                        
                        // Do heavy work in background
                        await Task.detached(priority: .userInitiated) {
                            await copyImages()
                        }.value
                        
                        // UI updates back on main thread
                        isProcessingImages = false
                        copyImageFeedback = true
                        
                        // Reset after delay
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        copyImageFeedback = false
                    }
                }) {
                    if isProcessingImages {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(copyImageFeedback ? "Copied!" : "Copy as Images", systemImage: copyImageFeedback ? "checkmark" : "photo")
                            .frame(maxWidth: .infinity)
                            .labelStyle(.titleOnly)
                    }
                }
                .buttonStyle(.bordered)
                .clipShape(.capsule)
                .controlSize(.large)
                .tint(.accentColor)
                .shadow(radius: 1)
                .disabled(isProcessingImages)
            }
        }
        .frame(maxWidth: 180)
        .padding(.bottom, 8)
        .opacity(isHovering ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
    
    private func copyImages() async {
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
                // Run UI-related code on main thread
                let page = await MainActor.run {
                    pdf.page(at: i)?.thumbnail(of: CGSize(width: 1024, height: 1024), for: .mediaBox)
                }
                
                if let page = page {
                    currentPages.append(page)
                    pageCounter += 1
                    
                    // When we have enough pages or it's the last page, stitch and save
                    if currentPages.count == pagesPerImage || pageCounter == totalPages {
                        if let stitchedImage = await MainActor.run(body: {
                            stitchImages(currentPages)
                        }) {
                            let fileURL = tempDir.appendingPathComponent("pages_\((pageCounter/pagesPerImage) + 1).jpg")
                            
                            // Run image saving in background
                            if let cgImage = await MainActor.run(body: {
                                stitchedImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
                            }) {
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
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects(temporaryFiles as [NSPasteboardWriting])
            }
            
            // Schedule cleanup after 1 hour
            Task {
                try? await Task.sleep(nanoseconds: 3600_000_000_000) // 1 hour
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
            let xmlString = try documentProcessor.generateXML()
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
    
    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
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

#Preview {
    DropzoneView()
        .frame(width: 260, height: 240)
}
