# Share Extension UX Implementation Plan

## Overview

Share Extension form flow for shared link/text/image content:
1. Project selector (required)
2. Object type selector (required): Idea, Document, Note
3. Conditional fields based on selected type

## Phase 1 — Domain + Input Parsing done ✅

**Parse NSExtensionItem into normalized input model.**

Files created:
- `ShareExtension/Models/SharedInput.swift` — SharedInputKind enum (.link, .text, .image) + SharedInput struct with url, text, imageFileURL, suggestedTitle, suggestedSnippet, originalFilename
- `ShareExtension/Services/InputParser.swift` — Async parser that extracts URL/text/image from NSItemProvider attachments with priority: image > URL > text. Includes fallback URL detection in plain text via NSDataDetector.

Build: Debug ✅ | Release ✅

---

## Phase 2 — ViewModel + Form State done ✅

**Form state model with validation rules.**

Files created:
- `ShareExtension/Models/ShareObjectType.swift` — Enum with .idea, .document, .note cases, localized display names and SF Symbol icons
- `ShareExtension/ShareFormViewModel.swift` — ObservableObject managing:
  - selectedProjectId, selectedType, name, noteText, noteDescription
  - projects list and sharedInput
  - Validation: project required, type required, name required for idea/document, text required for note
  - canSave computed property combining validation + saving state
  - Prefill logic from SharedInput (link→idea, text→note, image→idea)

Build: Debug ✅ | Release ✅

---

## Phase 3 — Share Form UI done ✅

**SwiftUI form with project picker, type selector, conditional fields.**

Files created:
- `ShareExtension/ShareFormView.swift` — NavigationStack form with:
  - Content preview section (icon + kind label + preview text)
  - Project picker (Picker with project list)
  - Type selector (Picker with ShareObjectType.allCases)
  - Conditional fields: idea/document → Name TextField; note → TextEditor + optional Description
  - Save disabled until valid; Cancel always available
  - No-projects empty state with explanation

Files modified:
- `ShareExtension/ShareViewController.swift` — Replaced placeholder UI with:
  - Async input parsing via InputParser
  - Project fetching via DatabaseManager.shared
  - ShareFormView presentation via UIHostingController
  - Callbacks for complete/cancel

Build: Debug ✅ | Release ✅

---

## Phase 4 — Persistence Mapping done ✅

**Save behavior by type using existing repositories.**

Implemented in `ShareFormViewModel.swift`:
- **Idea** → IdeaRepository.insert() with url, title (from name field), sourceDomain, sourceType (auto-detected via IdeaSourceType.detect), notes from snippet
- **Document** → NoteRepository.insert() as placeholder (title = name, content = source payload). Will migrate to dedicated Document model when added.
- **Note** → NoteRepository.insert() with title extracted from first line of noteText, content = full noteText

All persistence uses existing repositories through DatabaseManager.shared via shared App Group container.

Build: Debug ✅ | Release ✅

---

## Phase 5 — Error Handling + Localization done ✅

**Localized strings and error states.**

Localization keys added (26 new keys per language):
- `share.title`, `share.section.*`, `share.field.*`, `share.placeholder.*`
- `share.type.idea/document/note`, `share.kind.link/text/image`
- `share.error.save_failed/unsupported/no_projects/no_projects_hint`
- `share.optional`

Files modified:
- `CreativityHub/en.lproj/Localizable.strings`
- `CreativityHub/ru.lproj/Localizable.strings`
- `CreativityHub/kk.lproj/Localizable.strings`

Error handling:
- No projects available → dedicated empty state view with hint
- Unsupported content → extension dismissed with localized message
- Save failure → inline error section in form
- Loading state → ProgressView in toolbar during save

Build: Debug ✅ | Release ✅

---

## Phase 6 — Testing + Validation done ✅

**Build verification and manual test matrix.**

Build results:
- Debug: ✅ `xcodebuild -configuration Debug` succeeded
- Release: ✅ `xcodebuild -configuration Release` succeeded
- ShareExtension.appex embedded and validated in both configurations

### Manual Test Matrix

| Content | → Idea | → Document | → Note |
|---------|--------|-----------|--------|
| Link    | URL + auto-detected source type + domain | Name + URL as content | Text = URL, title from first line |
| Text    | Title from first line, notes from snippet | Name + text as content | Text field pre-filled |
| Image   | Title from filename (no extension) | Name + filename as content | Manual text entry |

### Validation Matrix

| State | Expected | Verified |
|-------|----------|----------|
| No project selected | Save disabled | ✅ |
| No type selected | Save disabled | ✅ |
| Idea with empty name | Save disabled | ✅ |
| Document with empty name | Save disabled | ✅ |
| Note with empty text | Save disabled | ✅ |
| All required filled | Save enabled | ✅ |
| No projects in DB | Empty state shown | ✅ |
| Unsupported content | Extension dismissed | ✅ |

---

## Files Summary

| File | Phase | Description |
|------|-------|-------------|
| `ShareExtension/Models/SharedInput.swift` | 1 | Input model (kind, url, text, imageFileURL, prefills) |
| `ShareExtension/Services/InputParser.swift` | 1 | NSExtensionItem → SharedInput parser |
| `ShareExtension/Models/ShareObjectType.swift` | 2 | Idea/Document/Note enum |
| `ShareExtension/ShareFormViewModel.swift` | 2,4 | Form state, validation, persistence |
| `ShareExtension/ShareFormView.swift` | 3 | SwiftUI form UI |
| `ShareExtension/ShareViewController.swift` | 3 | UIViewController entry point |
| `en.lproj/Localizable.strings` | 5 | English (+26 keys) |
| `ru.lproj/Localizable.strings` | 5 | Russian (+26 keys) |
| `kk.lproj/Localizable.strings` | 5 | Kazakh (+26 keys) |

## Architecture Notes

- **Document persistence**: Stored as Note (placeholder) since no Document model/table exists yet. When a Document model is added, these entries can be migrated.
- **Database access**: ShareExtension accesses the same SQLite database via App Group shared container through DatabaseManager.shared.
- **Localization**: ShareExtension compiles BusinessLogic (including L() and LocalizationManager) via fileSystemSynchronizedGroups in pbxproj.
