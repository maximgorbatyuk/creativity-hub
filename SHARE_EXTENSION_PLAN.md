# SHARE_EXTENSION_PLAN.md - Share Extension Implementation Plan

This document provides a phased implementation plan for adding a Share Extension to CreativeHub, following the pattern from Journey Wallet. This plan should be executed **after** BASE_FUNCTIONALITY_PLAN.md is complete.

## Prerequisites

Before starting this plan, ensure:
- BASE_FUNCTIONALITY_PLAN.md is fully implemented
- App Group is configured (included in BASE_FUNCTIONALITY_PLAN.md Phase 1.4)
- xcconfig files are set up (included in BASE_FUNCTIONALITY_PLAN.md Phase 1.3)
- Main app uses AppGroupContainer for database (included in BASE_FUNCTIONALITY_PLAN.md Phase 4.1)

---

## Overview

The Share Extension allows users to share files (PDFs, images) and content (text, URLs) from other apps directly into CreativeHub.

### Supported Content Types

| Type | Max Count | Description |
|------|-----------|-------------|
| Files | 10 | PDFs, documents |
| Images | 10 | JPEG, PNG, HEIC |
| Text | Yes | Plain text content |
| URLs | 1 | Web links |

### Architecture

- **Single target** with xcconfig-based configuration for Debug/Release
- **Shared App Group** container for database and files
- **SwiftUI interface** presented via UIHostingController

---

## Phase 1: Xcode Target Setup

### 1.1 Create Share Extension Target

1. In Xcode, select File → New → Target
2. Choose "Share Extension"
3. Configure:
   - Product Name: `ShareExtension`
   - Language: Swift
   - Embed in Application: CreativeHub

### 1.2 Configure Target Build Settings

**General Settings:**
| Setting | Value |
|---------|-------|
| Product Bundle Identifier | `$(SHARE_EXTENSION_BUNDLE_ID)` |
| iOS Deployment Target | 18.0 |
| Build Configuration Files | Same as main app |

**Code Signing Entitlements:**
| Configuration | Entitlements File |
|---------------|-------------------|
| Debug | `ShareExtension/ShareExtensionDebug.entitlements` |
| Release | `ShareExtension/ShareExtension.entitlements` |

### 1.3 Create Directory Structure

```
ShareExtension/
├── Info.plist
├── ShareExtension.entitlements         # Release entitlements
├── ShareExtensionDebug.entitlements    # Debug entitlements
├── ShareViewController.swift           # Entry point
├── ShareView.swift                     # SwiftUI interface
├── ShareViewModel.swift                # Business logic
└── Models/
    ├── SharedContentType.swift
    └── ShareEntityType.swift
```

---

## Phase 2: Configuration Files

### 2.1 Update xcconfig Files

**CreativeHub/Config/Base.xcconfig** (add these lines):
```
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.CreativeHub.ShareExtension
```

**CreativeHub/Config/Debug.xcconfig** (add these lines):
```
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.CreativeHub.dev.ShareExtension
```

### 2.2 Create ShareExtension/Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AppGroupIdentifier</key>
    <string>$(APP_GROUP_IDENTIFIER)</string>
    <key>CFBundleDisplayName</key>
    <string>CreativeHub</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>NSExtensionActivationRule</key>
            <dict>
                <key>NSExtensionActivationSupportsFileWithMaxCount</key>
                <integer>10</integer>
                <key>NSExtensionActivationSupportsImageWithMaxCount</key>
                <integer>10</integer>
                <key>NSExtensionActivationSupportsText</key>
                <true/>
                <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
                <integer>1</integer>
            </dict>
        </dict>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
    </dict>
</dict>
</plist>
```

### 2.3 Create Entitlements Files

**ShareExtension/ShareExtension.entitlements** (Release):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.dev.mgorbatyuk.creativehub</string>
    </array>
</dict>
</plist>
```

**ShareExtension/ShareExtensionDebug.entitlements** (Debug):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.dev.mgorbatyuk.creativehub.dev</string>
    </array>
</dict>
</plist>
```

---

## Phase 3: Models

### 3.1 SharedContentType

**File:** `ShareExtension/Models/SharedContentType.swift`

```swift
import Foundation

/// Represents the type of content shared to the extension.
enum SharedContentType {
    /// One or more files (PDFs, images, etc.)
    case files([URL])

    /// Plain text content
    case text(String)

    /// A URL with optional title
    case url(URL, title: String?)

    /// A URL along with additional text
    case urlWithText(URL, String)

    var isTextBased: Bool {
        switch self {
        case .files:
            return false
        case .text, .url, .urlWithText:
            return true
        }
    }

    var displayText: String {
        switch self {
        case .files(let urls):
            return urls.map { $0.lastPathComponent }.joined(separator: ", ")
        case .text(let text):
            return text
        case .url(let url, _):
            return url.absoluteString
        case .urlWithText(let url, let text):
            return "\(text)\n\(url.absoluteString)"
        }
    }

    /// Extracts the URL if present
    var extractedURL: URL? {
        switch self {
        case .url(let url, _), .urlWithText(let url, _):
            return url
        case .text(let text):
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
               let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return URL(string: String(text[range]))
            }
            return nil
        case .files:
            return nil
        }
    }
}
```

### 3.2 ShareEntityType (Simplified for CreativeHub)

**File:** `ShareExtension/Models/ShareEntityType.swift`

Since CreativeHub is a stub app without domain-specific entities, create a simplified version:

```swift
import Foundation

/// Entity types that can be created from shared content.
/// NOTE: Expand this enum when adding domain features to CreativeHub.
enum ShareEntityType: String, CaseIterable, Identifiable {
    case note
    case bookmark

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .note: return "note.text"
        case .bookmark: return "bookmark.fill"
        }
    }

    var title: String {
        switch self {
        case .note: return L("share.entity_type.note")
        case .bookmark: return L("share.entity_type.bookmark")
        }
    }
}

/// Analyzes shared content to suggest entity type.
struct ContentAnalyzer {
    static func suggestEntityType(for text: String) -> ShareEntityType {
        // If it's a URL, suggest bookmark
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            return .bookmark
        }
        return .note
    }

    static func extractFirstLine(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "..."
        }
        return firstLine
    }
}
```

---

## Phase 4: Share Extension Views

### 4.1 ShareFileItem Model

**File:** `ShareExtension/Models/ShareFileItem.swift`

```swift
import Foundation

/// Represents a file to be shared, with optional custom name.
class ShareFileItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    let originalName: String
    let fileExtension: String
    @Published var customName: String

    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        self.fileExtension = url.pathExtension
        self.customName = ""
    }
}
```

### 4.2 ShareViewController

**File:** `ShareExtension/ShareViewController.swift`

```swift
import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Entry point for the Share Extension.
class ShareViewController: UIViewController {

    private var extractedContent: SharedContentType?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            close(withError: "No items to share")
            return
        }

        let group = DispatchGroup()

        var extractedURLs: [URL] = []
        var extractedText: String?
        var extractedWebURL: URL?
        var extractedWebTitle: String?

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            if let attributedText = item.attributedContentText {
                extractedWebTitle = attributedText.string
            }

            for provider in attachments {
                // Extract URL
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                        defer { group.leave() }
                        if let url = item as? URL {
                            DispatchQueue.main.async { extractedWebURL = url }
                        }
                    }
                }

                // Extract plain text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                        defer { group.leave() }
                        if let text = item as? String {
                            DispatchQueue.main.async { extractedText = text }
                        }
                    }
                }

                // Extract files
                let fileTypes = [
                    UTType.pdf.identifier,
                    UTType.image.identifier,
                    UTType.jpeg.identifier,
                    UTType.png.identifier,
                    UTType.heic.identifier
                ]

                for typeIdentifier in fileTypes {
                    if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                        group.enter()
                        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
                            defer { group.leave() }
                            guard let url = url else { return }

                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)

                            do {
                                try FileManager.default.copyItem(at: url, to: tempURL)
                                DispatchQueue.main.async { extractedURLs.append(tempURL) }
                            } catch {
                                print("Failed to copy file: \(error)")
                            }
                        }
                        break
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            let contentType: SharedContentType

            if !extractedURLs.isEmpty {
                contentType = .files(extractedURLs)
            } else if let webURL = extractedWebURL {
                if let text = extractedText, !text.isEmpty, text != webURL.absoluteString {
                    contentType = .urlWithText(webURL, text)
                } else {
                    contentType = .url(webURL, title: extractedWebTitle)
                }
            } else if let text = extractedText, !text.isEmpty {
                contentType = .text(text)
            } else {
                self.close(withError: "No supported content found")
                return
            }

            self.extractedContent = contentType
            self.presentShareUI(with: contentType)
        }
    }

    private func presentShareUI(with contentType: SharedContentType) {
        let viewModel = ShareViewModel(
            contentType: contentType,
            onComplete: { [weak self] success in
                if success {
                    self?.extensionContext?.completeRequest(returningItems: nil)
                } else {
                    self?.close(withError: "Failed to save")
                }
            },
            onCancel: { [weak self] in
                self?.cleanupTempFiles()
                self?.extensionContext?.cancelRequest(withError: NSError(
                    domain: "ShareExtension",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
                ))
            }
        )

        let shareView = ShareView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: shareView)

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func close(withError message: String) {
        cleanupTempFiles()
        extensionContext?.cancelRequest(withError: NSError(
            domain: "ShareExtension",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        ))
    }

    private func cleanupTempFiles() {
        if case .files(let urls) = extractedContent {
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
```

### 4.3 ShareViewModel (Simplified)

**File:** `ShareExtension/ShareViewModel.swift`

```swift
import Foundation
import Combine
import os

/// ViewModel for the Share Extension.
/// NOTE: This is a simplified version for CreativeHub stub app.
/// Expand when adding domain-specific features.
@MainActor
class ShareViewModel: ObservableObject {
    let contentType: SharedContentType
    @Published var files: [ShareFileItem] = []

    // For text-based content
    @Published var selectedEntityType: ShareEntityType = .note
    @Published var sharedText: String = ""
    @Published var sharedURL: URL?

    // UI state
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    // Form data
    @Published var entityTitle: String = ""
    @Published var entityNotes: String = ""

    private let onComplete: (Bool) -> Void
    private let onCancel: () -> Void
    private let logger = Logger(subsystem: "ShareExtension", category: "ShareViewModel")

    var canSave: Bool {
        !isSaving
    }

    var isFileBased: Bool {
        if case .files = contentType { return true }
        return false
    }

    init(contentType: SharedContentType, onComplete: @escaping (Bool) -> Void, onCancel: @escaping () -> Void) {
        self.contentType = contentType
        self.onComplete = onComplete
        self.onCancel = onCancel

        switch contentType {
        case .files(let urls):
            self.files = urls.map { ShareFileItem(url: $0) }

        case .text(let text):
            self.sharedText = text
            self.selectedEntityType = ContentAnalyzer.suggestEntityType(for: text)
            self.entityTitle = ContentAnalyzer.extractFirstLine(from: text)
            self.entityNotes = text

        case .url(let url, let title):
            self.sharedURL = url
            self.sharedText = url.absoluteString
            self.selectedEntityType = .bookmark
            self.entityTitle = title ?? url.host ?? ""
            self.entityNotes = url.absoluteString

        case .urlWithText(let url, let text):
            self.sharedURL = url
            self.sharedText = text
            self.selectedEntityType = ContentAnalyzer.suggestEntityType(for: text)
            self.entityTitle = ContentAnalyzer.extractFirstLine(from: text)
            self.entityNotes = "\(text)\n\n\(url.absoluteString)"
        }
    }

    func save() {
        isSaving = true
        errorMessage = nil

        Task {
            // TODO: Implement actual saving logic when domain features are added
            // For now, just simulate success after a brief delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            logger.info("Shared content saved (stub implementation)")

            // Clean up temp files if file-based
            if case .files = contentType {
                for file in files {
                    try? FileManager.default.removeItem(at: file.url)
                }
            }

            isSaving = false
            onComplete(true)
        }
    }

    func cancel() {
        if case .files = contentType {
            for file in files {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
        onCancel()
    }
}
```

### 4.4 ShareView

**File:** `ShareExtension/ShareView.swift`

```swift
import SwiftUI

/// SwiftUI view for the Share Extension interface.
struct ShareView: View {
    @ObservedObject var viewModel: ShareViewModel

    var body: some View {
        NavigationView {
            content
                .navigationTitle(L("share.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L("Cancel")) {
                            viewModel.cancel()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(L("Save")) {
                            viewModel.save()
                        }
                        .disabled(!viewModel.canSave)
                        .fontWeight(.semibold)
                    }
                }
        }
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            Form {
                if viewModel.isFileBased {
                    filesSection
                } else {
                    contentPreviewSection
                    entityFormSection
                }

                if let error = viewModel.errorMessage {
                    errorSection(error)
                }

                stubNoticeSection
            }
        }
    }

    // MARK: - File Sharing

    private var filesSection: some View {
        Section(header: Text(L("share.file_section"))) {
            ForEach(viewModel.files.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        fileIcon(for: viewModel.files[index].fileExtension)
                        Text(viewModel.files[index].originalName)
                            .font(.body)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("share.document_name") + " (" + L("Optional") + ")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField(L("share.document_name_placeholder"), text: $viewModel.files[index].customName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Text/URL Sharing

    private var contentPreviewSection: some View {
        Section(header: Text(L("share.content_preview"))) {
            VStack(alignment: .leading, spacing: 8) {
                if let url = viewModel.sharedURL {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text(url.host ?? url.absoluteString)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }

                Text(viewModel.sharedText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(5)
            }
            .padding(.vertical, 4)
        }
    }

    private var entityFormSection: some View {
        Section(header: Text(L("share.form.details"))) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("share.form.title"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField(L("share.form.title_placeholder"), text: $viewModel.entityTitle)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(L("share.form.notes"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $viewModel.entityNotes)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Stub Notice

    private var stubNoticeSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(L("share.stub_notice"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Error & Saving

    private func errorSection(_ message: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
            }
        }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(L("share.saving"))
                    .font(.headline)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }

    // MARK: - Helpers

    private func fileIcon(for ext: String) -> some View {
        let iconName: String
        let color: Color

        switch ext.lowercased() {
        case "pdf":
            iconName = "doc.fill"
            color = .red
        case "jpg", "jpeg", "png", "heic":
            iconName = "photo.fill"
            color = .blue
        default:
            iconName = "doc.fill"
            color = .gray
        }

        return Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(color)
            .frame(width: 32)
    }
}
```

---

## Phase 5: Localization

### 5.1 Add Share Extension Localization Keys

Add to all localization files (`en.lproj/Localizable.strings`, `ru.lproj/Localizable.strings`, `kk.lproj/Localizable.strings`):

**English:**
```
/* Share Extension */
"share.title" = "Save to CreativeHub";
"share.file_section" = "File";
"share.content_preview" = "Content";
"share.document_name" = "Document name";
"share.document_name_placeholder" = "Enter document name";
"share.form.details" = "Details";
"share.form.title" = "Title";
"share.form.title_placeholder" = "Enter title";
"share.form.notes" = "Notes";
"share.saving" = "Saving...";
"share.error.save_failed" = "Failed to save";
"share.entity_type.note" = "Note";
"share.entity_type.bookmark" = "Bookmark";
"share.stub_notice" = "Share Extension is ready. Domain features coming soon.";
"Optional" = "Optional";
```

**Russian:**
```
/* Share Extension */
"share.title" = "Сохранить в CreativeHub";
"share.file_section" = "Файл";
"share.content_preview" = "Содержимое";
"share.document_name" = "Название документа";
"share.document_name_placeholder" = "Введите название";
"share.form.details" = "Детали";
"share.form.title" = "Заголовок";
"share.form.title_placeholder" = "Введите заголовок";
"share.form.notes" = "Заметки";
"share.saving" = "Сохранение...";
"share.error.save_failed" = "Не удалось сохранить";
"share.entity_type.note" = "Заметка";
"share.entity_type.bookmark" = "Закладка";
"share.stub_notice" = "Share Extension готов. Функции скоро появятся.";
"Optional" = "Необязательно";
```

**Kazakh:**
```
/* Share Extension */
"share.title" = "CreativeHub-қа сақтау";
"share.file_section" = "Файл";
"share.content_preview" = "Мазмұны";
"share.document_name" = "Құжат атауы";
"share.document_name_placeholder" = "Атауын енгізіңіз";
"share.form.details" = "Мәліметтер";
"share.form.title" = "Тақырып";
"share.form.title_placeholder" = "Тақырыпты енгізіңіз";
"share.form.notes" = "Жазбалар";
"share.saving" = "Сақталуда...";
"share.error.save_failed" = "Сақтау сәтсіз аяқталды";
"share.entity_type.note" = "Жазба";
"share.entity_type.bookmark" = "Бетбелгі";
"share.stub_notice" = "Share Extension дайын. Функциялар жақында қосылады.";
"Optional" = "Міндетті емес";
```

### 5.2 Add Localization Files to Target

In Xcode, select each `.lproj` folder and add ShareExtension to target membership.

---

## Phase 6: Target Membership

### 6.1 BusinessLogic Files for Extension

Add these files to ShareExtension target:

**Required:**
- `BusinessLogic/Helpers/AppGroupContainer.swift`
- `BusinessLogic/Services/LocalizationManager.swift`
- `BusinessLogic/Models/UserSettings.swift` (for AppLanguage)
- `BusinessLogic/Errors/RuntimeError.swift`
- `BusinessLogic/Errors/GlobalLogger.swift`

**Localization:**
- All `*.lproj/Localizable.strings` files

### 6.2 Excluded Files (Not Compatible with Extension)

Do NOT add to ShareExtension target:
- `AnalyticsService.swift` (requires Firebase)
- `BackgroundTaskManager.swift` (uses BGTaskScheduler)
- `BackupService.swift`
- `NetworkMonitor.swift`
- `NotificationManager.swift`
- `DatabaseManager.swift` (full version - extension uses simplified access)
- Any Firebase-related code

---

## Phase 7: Embed Extension

### 7.1 Add to Main App Target

1. Select CreativeHub target
2. Go to General → Frameworks, Libraries, and Embedded Content
3. Click + and add ShareExtension.appex
4. Set Embed to "Embed Without Signing"

### 7.2 Verify Embedding

In Build Phases, ensure "Embed App Extensions" contains ShareExtension.

---

## Phase 8: Testing

### 8.1 Build Verification

```bash
xcodebuild -project CreativeHub.xcodeproj -scheme CreativeHub \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### 8.2 Test Checklist

**Basic Functionality:**
- [ ] Extension appears in Share sheet as "CreativeHub"
- [ ] Can share PDF from Files app
- [ ] Can share image from Photos app
- [ ] Can share URL from Safari
- [ ] Can share text from Notes app
- [ ] Cancel button works
- [ ] Save button works

**File Sharing:**
- [ ] File icon shows correctly for PDF
- [ ] File icon shows correctly for images
- [ ] Custom name field works
- [ ] Empty custom name uses original filename

**Text/URL Sharing:**
- [ ] URL preview shows host
- [ ] Title field pre-populates
- [ ] Notes field shows full content

**Edge Cases:**
- [ ] Multiple files at once
- [ ] Large files (>10MB)
- [ ] Very long filenames
- [ ] Special characters in filenames

---

## Implementation Summary

| Phase | Description | Files Count |
|-------|-------------|-------------|
| 1 | Xcode Target Setup | Configuration |
| 2 | Configuration Files | 4 files |
| 3 | Models | 3 files |
| 4 | Share Extension Views | 4 files |
| 5 | Localization | Updates to 3 files |
| 6 | Target Membership | Configuration |
| 7 | Embed Extension | Configuration |
| 8 | Testing | Validation |

**Total new files:** ~11 files

---

## Future Enhancements

When domain features are added to CreativeHub, expand the Share Extension:

1. **Add domain entity types** to `ShareEntityType`
2. **Implement saving logic** in `ShareViewModel.save()`
3. **Add entity picker** similar to Journey Wallet's journey picker
4. **Connect to DatabaseManager** for persistent storage
5. **Add DocumentService** for file storage in shared container

---

## Troubleshooting

### Extension doesn't appear in Share sheet

1. Ensure extension is embedded in main app
2. Check bundle ID prefix matches parent app
3. Rebuild and reinstall app

### "Could not access database" error

1. Verify App Group in both entitlements
2. Check `AppGroupIdentifier` in Info.plist
3. Ensure correct entitlements file for build configuration

### Localization not working

1. Add all `.lproj` folders to ShareExtension target
2. Ensure `LocalizationManager.swift` is in extension target
