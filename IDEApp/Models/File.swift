//
//  File.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import SwiftUI

/// Represents a file or directory in the project
struct FileItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let path: URL
    let isDirectory: Bool
    let modifiedDate: Date?
    let size: Int64?
    var children: [FileItem]?
    var isExpanded: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        isDirectory: Bool,
        modifiedDate: Date? = nil,
        size: Int64? = nil,
        children: [FileItem]? = nil,
        isExpanded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.modifiedDate = modifiedDate
        self.size = size
        self.children = children
        self.isExpanded = isExpanded
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - File Extensions

extension FileItem {
    /// Get file extension
    var fileExtension: String {
        path.pathExtension.lowercased()
    }
    
    /// Get icon name based on file type
    var iconName: String {
        if isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        }
        
        switch fileExtension {
        case "swift": return "swift"
        case "py": return "doc.text"
        case "js", "jsx": return "doc.text"
        case "ts", "tsx": return "doc.text"
        case "html", "htm": return "doc.richtext"
        case "css", "scss": return "doc.richtext"
        case "json": return "curlybraces"
        case "xml": return "chevron.left.forwardslash.chevron.right"
        case "md", "markdown": return "doc.plaintext"
        case "txt": return "doc.plaintext"
        case "pdf": return "doc.fill"
        case "png", "jpg", "jpeg", "gif": return "photo"
        case "zip", "tar", "gz": return "doc.zipper"
        default: return "doc"
        }
    }
    
    /// Get icon color based on file type
    var iconColor: Color {
        if isDirectory {
            return .blue
        }
        
        switch fileExtension {
        case "swift": return .orange
        case "py": return .blue
        case "js", "jsx", "ts", "tsx": return .yellow
        case "html": return .orange
        case "css", "scss": return .blue
        case "json": return .green
        case "md", "markdown": return .gray
        default: return .secondary
        }
    }
    
    /// Check if file is hidden (starts with .)
    var isHidden: Bool {
        name.hasPrefix(".")
    }
    
    /// Check if file is text-based and editable
    var isEditable: Bool {
        !isDirectory && isTextFile
    }
    
    /// Check if file is text file
    var isTextFile: Bool {
        let textExtensions = [
            "swift", "py", "js", "jsx", "ts", "tsx",
            "html", "htm", "css", "scss", "sass", "less",
            "json", "xml", "yaml", "yml", "toml",
            "md", "markdown", "txt", "log",
            "c", "cpp", "h", "hpp", "java", "kt",
            "rb", "php", "go", "rs", "sh", "bash"
        ]
        return textExtensions.contains(fileExtension)
    }
    
    /// Get formatted file size
    var formattedSize: String? {
        guard let size = size else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - File Creation

extension FileItem {
    /// Create FileItem from URL
    static func from(url: URL) -> FileItem? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            return nil
        }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let modifiedDate = attributes?[.modificationDate] as? Date
        let size = attributes?[.size] as? Int64
        
        return FileItem(
            name: url.lastPathComponent,
            path: url,
            isDirectory: isDir.boolValue,
            modifiedDate: modifiedDate,
            size: !isDir.boolValue ? size : nil
        )
    }
    
    /// Load children for directory
    mutating func loadChildren(includeHidden: Bool = false) {
        guard isDirectory else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                options: includeHidden ? [] : [.skipsHiddenFiles]
            )
            
            self.children = contents
                .compactMap { FileItem.from(url: $0) }
                .sorted { item1, item2 in
                    // Directories first, then alphabetically
                    if item1.isDirectory != item2.isDirectory {
                        return item1.isDirectory
                    }
                    return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
                }
        } catch {
            print("Error loading children: \(error)")
            self.children = []
        }
    }
}

// MARK: - Sample Data

extension FileItem {
    static let sampleDirectory = FileItem(
        name: "MyApp",
        path: URL(fileURLWithPath: "/Users/user/Projects/MyApp"),
        isDirectory: true,
        children: [
            FileItem(
                name: "Sources",
                path: URL(fileURLWithPath: "/Users/user/Projects/MyApp/Sources"),
                isDirectory: true
            ),
            FileItem(
                name: "README.md",
                path: URL(fileURLWithPath: "/Users/user/Projects/MyApp/README.md"),
                isDirectory: false,
                size: 1024
            ),
            FileItem(
                name: "Package.swift",
                path: URL(fileURLWithPath: "/Users/user/Projects/MyApp/Package.swift"),
                isDirectory: false,
                size: 2048
            )
        ]
    )
}
