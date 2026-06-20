//
//  FileTreeView.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import SwiftUI

/// Hierarchical file tree view
struct FileTreeView: View {
    let projectURL: URL
    
    @EnvironmentObject var editorViewModel: EditorViewModel
    @State private var rootItems: [FileItem] = []
    @State private var expandedItems: Set<UUID> = []
    @State private var selectedItem: FileItem?
    @State private var isLoading = true
    @State private var showHiddenFiles = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Files")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showHiddenFiles.toggle()
                    loadFiles()
                } label: {
                    Image(systemName: showHiddenFiles ? "eye" : "eye.slash")
                }
                .help("Toggle hidden files")
                
                Button {
                    loadFiles()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            .padding()
            
            Divider()
            
            // File tree
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if rootItems.isEmpty {
                ContentUnavailableView(
                    "No Files",
                    systemImage: "folder",
                    description: Text("This project is empty")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(rootItems) { item in
                            FileTreeRow(
                                item: item,
                                level: 0,
                                expandedItems: $expandedItems,
                                selectedItem: $selectedItem,
                                onSelect: handleFileSelect
                            )
                        }
                    }
                }
            }
        }
        .task {
            loadFiles()
        }
    }
    
    private func loadFiles() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let fileService = FileService.shared
                rootItems = try await fileService.listDirectory(at: projectURL, includeHidden: showHiddenFiles)
            } catch {
                logError("Failed to load files: \(error)")
            }
        }
    }
    
    private func handleFileSelect(_ item: FileItem) {
        selectedItem = item
        
        if item.isDirectory {
            // Toggle expansion
            if expandedItems.contains(item.id) {
                expandedItems.remove(item.id)
            } else {
                expandedItems.insert(item.id)
            }
        } else if item.isEditable {
            // Open in editor
            Task {
                await editorViewModel.openFile(item)
            }
        }
    }
}

// MARK: - File Tree Row

struct FileTreeRow: View {
    let item: FileItem
    let level: Int
    @Binding var expandedItems: Set<UUID>
    @Binding var selectedItem: FileItem?
    let onSelect: (FileItem) -> Void
    
    @State private var children: [FileItem] = []
    
    private var isExpanded: Bool {
        expandedItems.contains(item.id)
    }
    
    private var isSelected: Bool {
        selectedItem?.id == item.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // This item
            Button {
                onSelect(item)
            } label: {
                HStack(spacing: 6) {
                    // Indentation
                    if level > 0 {
                        Color.clear
                            .frame(width: CGFloat(level * 16))
                    }
                    
                    // Expansion indicator for directories
                    if item.isDirectory {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .frame(width: 12)
                    } else {
                        Color.clear
                            .frame(width: 12)
                    }
                    
                    // Icon
                    Image(systemName: item.iconName)
                        .foregroundColor(item.iconColor)
                    
                    // Name
                    Text(item.name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Children (if expanded)
            if item.isDirectory && isExpanded {
                ForEach(children) { child in
                    FileTreeRow(
                        item: child,
                        level: level + 1,
                        expandedItems: expandedItems,
                        selectedItem: selectedItem,
                        onSelect: onSelect
                    )
                }
            }
        }
        .task(id: isExpanded) {
            if item.isDirectory && isExpanded && children.isEmpty {
                await loadChildren()
            }
        }
    }
    
    private func loadChildren() async {
        do {
            let fileService = FileService.shared
            children = try await fileService.listDirectory(at: item.path, includeHidden: false)
        } catch {
            logError("Failed to load children: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    FileTreeView(projectURL: URL(fileURLWithPath: "/Users/user/Projects/MyApp"))
        .environmentObject(EditorViewModel())
}
