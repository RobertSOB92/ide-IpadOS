# IDEApp - Natywna Aplikacja IDE dla iPad

Pełnofunkcjonalna aplikacja IDE dla iPada z obsługą Git i synchronizacją z GitHub. Działa w pełni offline - tylko synchronizacja z GitHub wymaga połączenia internetowego.

## 🎯 Funkcje

### MVP (Minimum Viable Product)
- ✅ **Edytor Monaco** - Pełnofunkcjonalny edytor kodu z syntax highlighting
- ✅ **System plików** - Przeglądanie i edycja plików lokalnych
- ✅ **File Browser** - Drzewo plików z ikonami i operacjami
- ✅ **Git lokalny** - Status, add, commit, log (działa offline)
- ✅ **Zarządzanie branchami** - Tworzenie, przełączanie, usuwanie
- ✅ **GitHub OAuth** - Bezpieczna autentykacja
- ✅ **Clone** - Klonowanie repozytoriów z GitHub
- ✅ **Push/Pull** - Podstawowa synchronizacja (wymaga internetu)
- ✅ **Offline indicator** - Wyraźne oznaczenie statusu połączenia
- ✅ **iPad UI** - Zoptymalizowany interfejs dotykowy
- ✅ **Keyboard shortcuts** - Obsługa zewnętrznej klawiatury

## 📋 Wymagania

- **macOS** (do development)
- **Xcode 15+**
- **Swift 5.9+**
- **iPadOS 16.0+** (minimum deployment target)
- **Konto Apple Developer** (do publikacji w App Store)

## 🚀 Szybki Start

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/RobertSOB92/ide.git
cd ide

# 2. Otwórz w Xcode i utwórz nowy projekt:
# - iOS -> App
# - Product Name: IDEApp
# - Interface: SwiftUI
# - Language: Swift
# - Organizacja: com.yourcompany

# 3. Przeciągnij folder IDEApp/ do projektu Xcode
# 4. Dodaj SwiftGit2 dependency przez SPM
# 5. Build & Run (Cmd + R)
```

Szczegółowa instrukcja w [SETUP.md](SETUP.md)

## 📁 Struktura Projektu

```
IDEApp/
├── App/                  # Main app entry
├── Models/               # Data models
├── Views/                # SwiftUI views
├── ViewModels/           # Business logic
├── Services/             # File, Git, GitHub services
├── Utilities/            # Helpers and extensions
└── Resources/            # Assets and Monaco Editor
```

## 🛠 Stack Technologiczny

- **Swift 5.9+** + **SwiftUI**
- **SwiftGit2** (libgit2 wrapper)
- **Monaco Editor** (via WKWebView)
- **URLSession** (GitHub API)
- **Keychain** (credential storage)

## 📚 Dokumentacja

- [SETUP.md](SETUP.md) - Instrukcja instalacji
- Zobacz kod źródłowy dla szczegółów implementacji

## 🗺 Roadmap

### v1.0 (MVP)
- [x] Podstawowy edytor
- [x] System plików  
- [x] Git lokalny
- [x] GitHub sync
- [ ] App Store release

## 👨‍💻 Autor

@RobertSOB92

---

**Projekt w aktywnym development. MVP w trakcie implementacji.**