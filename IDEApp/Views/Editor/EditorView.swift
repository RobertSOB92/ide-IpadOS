//
//  EditorView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// Main editor container view
struct EditorView: View {
    @EnvironmentObject var editorViewModel: EditorViewModel
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if !editorViewModel.openFiles.isEmpty {
                TabBarView()
                Divider()
            }
            
            // Editor content
            if let activeTab = editorViewModel.activeTab {
                MonacoWebView(tab: activeTab)
            } else {
                emptyEditorView
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if editorViewModel.activeTab != nil {
                    Button {
                        Task {
                            await editorViewModel.saveActiveFile()
                        }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(editorViewModel.activeTab?.hasUnsavedChanges == false)
                }
                
                Button {
                    showingSettings = true
                } label: {
                    Label("Editor Settings", systemImage: "textformat")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            EditorSettingsSheet()
                .environmentObject(editorViewModel)
        }
    }
    
    private var emptyEditorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No File Open")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Select a file from the file browser to edit")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Editor Settings Sheet

struct EditorSettingsSheet: View {
    @EnvironmentObject var editorViewModel: EditorViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { editorViewModel.theme },
                        set: { editorViewModel.updateTheme($0) }
                    )) {
                        ForEach(Constants.Editor.themes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    
                    Stepper("Font Size: \(Int(editorViewModel.fontSize))", value: Binding(
                        get: { editorViewModel.fontSize },
                        set: { editorViewModel.updateFontSize($0) }
                    ), in: Constants.Editor.minFontSize...Constants.Editor.maxFontSize)
                }
                
                Section("Formatting") {
                    Picker("Tab Size", selection: Binding(
                        get: { editorViewModel.tabSize },
                        set: { editorViewModel.updateTabSize($0) }
                    )) {
                        ForEach(Constants.Editor.tabSizeOptions, id: \.self) { size in
                            Text("\(size) spaces").tag(size)
                        }
                    }
                }
            }
            .navigationTitle("Editor Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditorView()
            .environmentObject(EditorViewModel())
    }
}
