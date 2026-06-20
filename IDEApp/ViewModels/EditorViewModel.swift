//
//  EditorViewModel.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for managing editor state and open files
@MainActor
class EditorViewModel: ObservableObject {
    @Published var openFiles: [EditorTab] = []
    @Published var activeTabId: UUID?
    @Published var fontSize: CGFloat = Constants.Editor.defaultFontSize
    @Published var tabSize: Int = Constants.Editor.defaultTabSize
    @Published var theme: String = Constants.Editor.defaultTheme
    @Published var isLoading = false
    @Published var error: Error?
    
    private let fileService = FileService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var activeTab: EditorTab? {
        openFiles.first { $0.id == activeTabId }
    }
    
    init() {
        loadSettings()
    }
    
    // MARK: - File Management
    
    /// Open file in editor
    func openFile(_ file: FileItem) async {
        // Check if already open
        if let existingTab = openFiles.first(where: { $0.file.path == file.path }) {
            activeTabId = existingTab.id
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let content = try await fileService.readFile(at: file.path)
            
            let tab = EditorTab(file: file, content: content)
            openFiles.append(tab)
            activeTabId = tab.id
            
            logInfo("Opened file: \(file.name)")
        } catch {
            self.error = error
            logError("Failed to open file: \(error)")
        }
    }
    
    /// Close tab
    func closeTab(_ tab: EditorTab) async {
        // Save if has unsaved changes
        if tab.hasUnsavedChanges {
            // TODO: Show save dialog
        }
        
        openFiles.removeAll { $0.id == tab.id }
        
        // Switch to another tab if this was active
        if activeTabId == tab.id {
            activeTabId = openFiles.first?.id
        }
        
        logInfo("Closed tab: \(tab.file.name)")
    }
    
    /// Close all tabs
    func closeAllTabs() async {
        for tab in openFiles where tab.hasUnsavedChanges {
            // TODO: Show save dialog for each unsaved file
        }
        
        openFiles.removeAll()
        activeTabId = nil
    }
    
    /// Update content for active tab
    func updateContent(_ content: String) {
        guard let activeId = activeTabId,
              let index = openFiles.firstIndex(where: { $0.id == activeId }) else {
            return
        }
        
        openFiles[index].content = content
        openFiles[index].hasUnsavedChanges = true
    }
    
    /// Save active file
    func saveActiveFile() async {
        guard let tab = activeTab else { return }
        await saveFile(tab)
    }
    
    /// Save specific file
    func saveFile(_ tab: EditorTab) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await fileService.writeFile(content: tab.content, to: tab.file.path)
            
            // Mark as saved
            if let index = openFiles.firstIndex(where: { $0.id == tab.id }) {
                openFiles[index].hasUnsavedChanges = false
                openFiles[index].lastSaved = Date()
            }
            
            logInfo("Saved file: \(tab.file.name)")
        } catch {
            self.error = error
            logError("Failed to save file: \(error)")
        }
    }
    
    /// Save all open files
    func saveAll() async {
        for tab in openFiles where tab.hasUnsavedChanges {
            await saveFile(tab)
        }
    }
    
    // MARK: - Settings
    
    func updateFontSize(_ size: CGFloat) {
        fontSize = size
        saveSettings()
    }
    
    func updateTabSize(_ size: Int) {
        tabSize = size
        saveSettings()
    }
    
    func updateTheme(_ newTheme: String) {
        theme = newTheme
        saveSettings()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: Constants.StorageKeys.editorSettings),
           let settings = try? JSONDecoder().decode(EditorSettings.self, from: data) {
            fontSize = settings.fontSize
            tabSize = settings.tabSize
            theme = settings.theme
        }
    }
    
    private func saveSettings() {
        let settings = EditorSettings(fontSize: fontSize, tabSize: tabSize, theme: theme)
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: Constants.StorageKeys.editorSettings)
        }
    }
}

// MARK: - Editor Tab

struct EditorTab: Identifiable, Equatable {
    let id: UUID
    let file: FileItem
    var content: String
    var hasUnsavedChanges: Bool
    var lastSaved: Date?
    
    init(
        id: UUID = UUID(),
        file: FileItem,
        content: String,
        hasUnsavedChanges: Bool = false,
        lastSaved: Date? = nil
    ) {
        self.id = id
        self.file = file
        self.content = content
        self.hasUnsavedChanges = hasUnsavedChanges
        self.lastSaved = lastSaved
    }
    
    static func == (lhs: EditorTab, rhs: EditorTab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Editor Settings

struct EditorSettings: Codable {
    var fontSize: CGFloat
    var tabSize: Int
    var theme: String
}
