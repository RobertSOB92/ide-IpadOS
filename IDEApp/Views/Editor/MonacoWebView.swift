//
//  MonacoWebView.swift
//  IDEApp
//
//  Created by IDEApp Team
//
//  WKWebView wrapper for Monaco Editor

import SwiftUI
import WebKit

/// Monaco Editor integration using WKWebView
struct MonacoWebView: UIViewRepresentable {
    let tab: EditorTab
    @EnvironmentObject var editorViewModel: EditorViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        // Setup message handler for JavaScript -> Swift communication
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "iosListener")
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        // Load Monaco Editor HTML
        if let htmlURL = Bundle.main.url(forResource: "monaco", withExtension: "html", subdirectory: "Resources/Monaco") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        } else {
            // Fallback: Use basic TextEditor for now
            logWarning("Monaco HTML not found, using fallback")
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update editor content when tab changes
        context.coordinator.currentTab = tab
        
        // Send content to Monaco
        let escapedContent = tab.content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        
        let script = """
        if (window.editor) {
            window.editor.setValue("\(escapedContent)");
            window.editor.updateOptions({
                fontSize: \(editorViewModel.fontSize),
                tabSize: \(editorViewModel.tabSize),
                theme: '\(editorViewModel.theme)'
            });
        }
        """
        
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                logError("Failed to update Monaco: \(error)")
            }
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: MonacoWebView
        var currentTab: EditorTab
        
        init(parent: MonacoWebView) {
            self.parent = parent
            self.currentTab = parent.tab
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "iosListener",
                  let body = message.body as? [String: Any] else {
                return
            }
            
            if let event = body["event"] as? String {
                switch event {
                case "contentChanged":
                    if let content = body["content"] as? String {
                        parent.editorViewModel.updateContent(content)
                    }
                    
                case "ready":
                    logInfo("Monaco Editor ready")
                    
                default:
                    break
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            logInfo("Monaco WebView loaded")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            logError("Monaco WebView failed: \(error)")
        }
    }
}

// MARK: - Fallback Text Editor

/// Simple text editor fallback when Monaco is not available
struct FallbackTextEditor: View {
    let tab: EditorTab
    @EnvironmentObject var editorViewModel: EditorViewModel
    @State private var text: String
    
    init(tab: EditorTab) {
        self.tab = tab
        self._text = State(initialValue: tab.content)
    }
    
    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .padding()
            .onChange(of: text) { oldValue, newValue in
                editorViewModel.updateContent(newValue)
            }
    }
}

// MARK: - Preview

#Preview {
    let file = FileItem(
        name: "test.swift",
        path: URL(fileURLWithPath: "/test.swift"),
        isDirectory: false
    )
    let tab = EditorTab(file: file, content: "// Test content\nprint(\"Hello World\")")
    
    return MonacoWebView(tab: tab)
        .environmentObject(EditorViewModel())
}
