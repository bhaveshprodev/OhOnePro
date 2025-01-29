import Foundation

struct ProcessedDocument {
    let url: URL
    let content: String
    let isPDF: Bool
}

class DocumentProcessor {
    private var documents: [ProcessedDocument] = []
    private let rootURL: URL?
    
    init(rootURL: URL? = nil) {
        self.rootURL = rootURL
    }
    
    func addDocument(_ document: ProcessedDocument) {
        documents.append(document)
    }
    
    func clear() {
        documents.removeAll()
    }
    
    func generateXML() throws -> String {
        let xmlDoc = XMLDocument(kind: .document)
        let isFolder = rootURL != nil
        
        // Create root element based on whether we have a folder structure
        let rootElement = XMLElement(name: isFolder ? "folder" : "files")
        if isFolder, let rootURL = rootURL {
            let nameAttr = XMLNode(kind: .attribute)
            nameAttr.name = "name"
            nameAttr.stringValue = rootURL.lastPathComponent
            rootElement.addAttribute(nameAttr)
        }
        xmlDoc.setRootElement(rootElement)
        
        // If there are no documents, return empty root element
        if documents.isEmpty {
            return """
                <?xml version="1.0" encoding="utf-8" standalone="yes"?>
                <\(isFolder ? "folder" : "files")\(isFolder ? " name=\"\(rootURL?.lastPathComponent ?? "")\"" : "")/>
                """
        }
        
        // Create a dictionary to store folder structure
        var folderStructure: [String: XMLElement] = [:]
        
        for document in documents {
            // Get the relative path from the root folder
            var relativePath = ""
            if isFolder, let rootURL = rootURL {
                let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"
                relativePath = document.url.path.replacingOccurrences(of: rootPath, with: "")
            } else {
                relativePath = document.url.lastPathComponent
            }
            
            let pathComponents = relativePath.split(separator: "/")
            
            // Create or get parent folder elements
            var currentElement = rootElement
            var currentPath = ""
            
            // Process all components except the last one (which is the file)
            for i in 0..<pathComponents.count - 1 {
                let component = pathComponents[i]
                currentPath += "/" + component
                
                if let existingFolder = folderStructure[currentPath] {
                    currentElement = existingFolder
                } else {
                    let folderElement = XMLElement(name: "folder")
                    let nameAttr = XMLNode(kind: .attribute)
                    nameAttr.name = "name"
                    nameAttr.stringValue = String(component)
                    folderElement.addAttribute(nameAttr)
                    
                    currentElement.addChild(folderElement)
                    folderStructure[currentPath] = folderElement
                    currentElement = folderElement
                }
            }
            
            // Add the file element
            let fileElement = XMLElement(name: "file")
            let nameAttr = XMLNode(kind: .attribute)
            nameAttr.name = "name"
            nameAttr.stringValue = String(pathComponents.last ?? "")
            fileElement.addAttribute(nameAttr)
            
            let contentElement = XMLElement(name: "content")
            contentElement.stringValue = document.content
            
            fileElement.addChild(contentElement)
            currentElement.addChild(fileElement)
        }
        
        return xmlDoc.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }
    
    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
} 