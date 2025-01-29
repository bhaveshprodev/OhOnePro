import XCTest
@testable import Oh_One_Pro

final class DocumentProcessorTests: XCTestCase {
    func testSingleFileXML() throws {
        let fileURL = URL(fileURLWithPath: "/test/test.txt")
        let processor = DocumentProcessor()
        processor.addDocument(ProcessedDocument(url: fileURL, content: "Hello, World!", isPDF: false))
        
        let xml = try processor.generateXML()
        
        XCTAssertTrue(xml.contains("<files>"))
        XCTAssertTrue(xml.contains("<file name=\"test.txt\">"))
        XCTAssertTrue(xml.contains("<content>Hello, World!</content>"))
    }
    
    func testMultipleFilesXML() throws {
        let processor = DocumentProcessor()
        processor.addDocument(ProcessedDocument(url: URL(fileURLWithPath: "/test/file1.txt"), content: "Content 1", isPDF: false))
        processor.addDocument(ProcessedDocument(url: URL(fileURLWithPath: "/test/file2.txt"), content: "Content 2", isPDF: false))
        
        let xml = try processor.generateXML()
        
        XCTAssertTrue(xml.contains("<files>"))
        XCTAssertTrue(xml.contains("<file name=\"file1.txt\">"))
        XCTAssertTrue(xml.contains("<file name=\"file2.txt\">"))
        XCTAssertTrue(xml.contains("<content>Content 1</content>"))
        XCTAssertTrue(xml.contains("<content>Content 2</content>"))
    }
    
    func testFolderStructureXML() throws {
        let rootURL = URL(fileURLWithPath: "/test/root")
        let processor = DocumentProcessor(rootURL: rootURL)
        
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/root/file1.txt"),
            content: "Content 1",
            isPDF: false
        ))
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/root/subfolder/file2.txt"),
            content: "Content 2",
            isPDF: false
        ))
        
        let xml = try processor.generateXML()
        
        XCTAssertTrue(xml.contains("<folder name=\"root\">"))
        XCTAssertTrue(xml.contains("<folder name=\"subfolder\">"))
        XCTAssertTrue(xml.contains("<file name=\"file1.txt\">"))
        XCTAssertTrue(xml.contains("<file name=\"file2.txt\">"))
        XCTAssertTrue(xml.contains("<content>Content 1</content>"))
        XCTAssertTrue(xml.contains("<content>Content 2</content>"))
    }
    
    func testEmptyProcessor() throws {
        let processor = DocumentProcessor()
        let xml = try processor.generateXML()
        
        let expectedXML = """
            <?xml version="1.0" encoding="utf-8" standalone="yes"?>
            <files/>
            """
        XCTAssertEqual(xml.trimmingCharacters(in: .whitespacesAndNewlines), expectedXML)
    }
    
    func testClearDocuments() throws {
        let processor = DocumentProcessor()
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/test.txt"),
            content: "Test",
            isPDF: false
        ))
        processor.clear()
        
        let xml = try processor.generateXML()
        let expectedXML = """
            <?xml version="1.0" encoding="utf-8" standalone="yes"?>
            <files/>
            """
        XCTAssertEqual(xml.trimmingCharacters(in: .whitespacesAndNewlines), expectedXML)
    }
    
    func testDeepNestedFolderStructure() throws {
        let rootURL = URL(fileURLWithPath: "/test/root")
        let processor = DocumentProcessor(rootURL: rootURL)
        
        // Add files at different levels
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/root/root.txt"),
            content: "Root Content",
            isPDF: false
        ))
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/root/level1/level1.txt"),
            content: "Level 1 Content",
            isPDF: false
        ))
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/root/level1/level2/level3/deep.txt"),
            content: "Deep Content",
            isPDF: false
        ))
        
        let xml = try processor.generateXML()
        
        // Verify nested structure
        XCTAssertTrue(xml.contains("<folder name=\"root\">"))
        XCTAssertTrue(xml.contains("<folder name=\"level1\">"))
        XCTAssertTrue(xml.contains("<folder name=\"level2\">"))
        XCTAssertTrue(xml.contains("<folder name=\"level3\">"))
        XCTAssertTrue(xml.contains("<file name=\"root.txt\">"))
        XCTAssertTrue(xml.contains("<file name=\"level1.txt\">"))
        XCTAssertTrue(xml.contains("<file name=\"deep.txt\">"))
        XCTAssertTrue(xml.contains("<content>Root Content</content>"))
        XCTAssertTrue(xml.contains("<content>Level 1 Content</content>"))
        XCTAssertTrue(xml.contains("<content>Deep Content</content>"))
    }
    
    func testPDFDocument() throws {
        let processor = DocumentProcessor()
        processor.addDocument(ProcessedDocument(
            url: URL(fileURLWithPath: "/test/document.pdf"),
            content: "PDF Content",
            isPDF: true
        ))
        
        let xml = try processor.generateXML()
        
        XCTAssertTrue(xml.contains("<files>"))
        XCTAssertTrue(xml.contains("<file name=\"document.pdf\">"))
        XCTAssertTrue(xml.contains("<content>PDF Content</content>"))
    }
} 

