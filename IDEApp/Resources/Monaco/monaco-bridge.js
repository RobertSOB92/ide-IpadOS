/**
 * Monaco Editor Bridge
 * JavaScript bridge for communication between Monaco Editor and Swift
 */

// Editor instance
let editor = null;

// Initialize Monaco Editor
function initializeEditor(config) {
    const container = document.getElementById('container');
    
    editor = monaco.editor.create(container, {
        value: config.value || '',
        language: config.language || 'javascript',
        theme: config.theme || 'vs-dark',
        fontSize: config.fontSize || 14,
        tabSize: config.tabSize || 4,
        insertSpaces: true,
        automaticLayout: true,
        scrollBeyondLastLine: false,
        wordWrap: 'on',
        minimap: {
            enabled: config.minimapEnabled !== false
        },
        lineNumbers: 'on',
        renderWhitespace: 'selection',
        folding: true,
        glyphMargin: true,
        // iPad/touch optimizations
        quickSuggestions: {
            other: true,
            comments: false,
            strings: false
        },
        suggestOnTriggerCharacters: true,
        acceptSuggestionOnCommitCharacter: true,
        acceptSuggestionOnEnter: 'on',
        tabCompletion: 'on',
        wordBasedSuggestions: true,
        parameterHints: {
            enabled: true
        }
    });
    
    // Setup event listeners
    setupEventListeners();
    
    return editor;
}

// Setup event listeners
function setupEventListeners() {
    if (!editor) return;
    
    // Content change
    editor.onDidChangeModelContent((e) => {
        sendMessage({
            type: 'contentChanged',
            content: editor.getValue(),
            changes: e.changes.length
        });
    });
    
    // Selection change
    editor.onDidChangeCursorSelection((e) => {
        const selection = editor.getSelection();
        sendMessage({
            type: 'selectionChanged',
            selection: {
                startLine: selection.startLineNumber,
                startColumn: selection.startColumn,
                endLine: selection.endLineNumber,
                endColumn: selection.endColumn
            }
        });
    });
    
    // Focus change
    editor.onDidFocusEditorText(() => {
        sendMessage({ type: 'focused' });
    });
    
    editor.onDidBlurEditorText(() => {
        sendMessage({ type: 'blurred' });
    });
}

// Send message to Swift
function sendMessage(message) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iosListener) {
        window.webkit.messageHandlers.iosListener.postMessage(message);
    } else {
        console.log('Message to Swift:', message);
    }
}

// Editor API for Swift
const EditorAPI = {
    // Content operations
    setValue: function(value) {
        if (editor) {
            editor.setValue(value || '');
        }
    },
    
    getValue: function() {
        return editor ? editor.getValue() : '';
    },
    
    insertText: function(text, position) {
        if (editor) {
            const pos = position || editor.getPosition();
            editor.executeEdits('', [{
                range: new monaco.Range(pos.lineNumber, pos.column, pos.lineNumber, pos.column),
                text: text
            }]);
        }
    },
    
    // Language operations
    setLanguage: function(language) {
        if (editor) {
            const model = editor.getModel();
            monaco.editor.setModelLanguage(model, language);
        }
    },
    
    getLanguage: function() {
        if (editor) {
            const model = editor.getModel();
            return model.getLanguageId();
        }
        return null;
    },
    
    // Theme operations
    setTheme: function(theme) {
        if (editor) {
            monaco.editor.setTheme(theme);
        }
    },
    
    // Options
    updateOptions: function(options) {
        if (editor) {
            editor.updateOptions(options);
        }
    },
    
    // Actions
    format: function() {
        if (editor) {
            editor.getAction('editor.action.formatDocument').run();
        }
    },
    
    undo: function() {
        if (editor) {
            editor.trigger('keyboard', 'undo');
        }
    },
    
    redo: function() {
        if (editor) {
            editor.trigger('keyboard', 'redo');
        }
    },
    
    find: function(text) {
        if (editor) {
            editor.trigger('keyboard', 'actions.find', { searchString: text });
        }
    },
    
    replace: function() {
        if (editor) {
            editor.trigger('keyboard', 'editor.action.startFindReplaceAction');
        }
    },
    
    // Selection
    selectAll: function() {
        if (editor) {
            editor.setSelection(editor.getModel().getFullModelRange());
        }
    },
    
    getSelection: function() {
        if (editor) {
            return editor.getSelection();
        }
        return null;
    },
    
    // Cursor
    setCursorPosition: function(lineNumber, column) {
        if (editor) {
            editor.setPosition({ lineNumber, column });
            editor.revealPosition({ lineNumber, column });
        }
    },
    
    // Layout
    layout: function() {
        if (editor) {
            editor.layout();
        }
    },
    
    focus: function() {
        if (editor) {
            editor.focus();
        }
    },
    
    // Dispose
    dispose: function() {
        if (editor) {
            editor.dispose();
            editor = null;
        }
    }
};

// Make API globally available
window.EditorAPI = EditorAPI;

// Notify Swift when ready
window.addEventListener('load', () => {
    sendMessage({ type: 'ready' });
});
