//
//  IDEApp.swift
//  IDEApp
//
//  Created by IDEApp Team
//
//  Main app entry point

import SwiftUI

@main
struct IDEApp: App {
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var editorViewModel = EditorViewModel()
    @StateObject private var gitViewModel = GitViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(projectViewModel)
                .environmentObject(editorViewModel)
                .environmentObject(gitViewModel)
        }
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    // TODO: Implement new file
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Open Project...") {
                    // TODO: Implement open project
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            // Edit menu commands
            CommandGroup(after: .undoRedo) {
                Divider()
                Button("Save") {
                    Task {
                        await editorViewModel.saveActiveFile()
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save All") {
                    Task {
                        await editorViewModel.saveAll()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
            
            // View menu commands
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    // TODO: Implement sidebar toggle
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
                
                Divider()
                
                Button("Zoom In") {
                    editorViewModel.updateFontSize(editorViewModel.fontSize + 1)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    editorViewModel.updateFontSize(editorViewModel.fontSize - 1)
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Reset Zoom") {
                    editorViewModel.updateFontSize(Constants.Editor.defaultFontSize)
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            
            // Git menu commands
            CommandMenu("Git") {
                Button("Commit...") {
                    // TODO: Show commit view
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
                Button("Push") {
                    Task {
                        await gitViewModel.push()
                    }
                }
                
                Button("Pull") {
                    Task {
                        await gitViewModel.pull()
                    }
                }
                
                Divider()
                
                Button("Refresh Status") {
                    Task {
                        await gitViewModel.loadStatus()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
