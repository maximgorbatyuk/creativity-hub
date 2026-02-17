# CreativityHub Master Plan

Version: 2026.1.2
Last updated: 2026-02-17

This document combines the original product feature specification and the base implementation plan into one source of truth.

## 1) Product Vision

CreativityHub is an iOS app for planning creative projects in one place. It combines project organization, task tracking, inspiration links, budget control, notes, and search.

## 2) Target Users

- Event planners (weddings, parties, corporate events)
- DIY enthusiasts and home renovators
- Cosplayers and roleplayers
- Content creators planning shoots or campaigns
- Artists and designers managing projects
- Small business owners launching products/services

## 3) Core Product Scope

### 3.1 Project Management

- Create unlimited projects with name and optional description
- Optional cover image/color
- Project status: active, completed, archived
- Optional start/target dates
- Progress percentage from checklist completion
- Pin favorites and sort projects

### 3.2 Checklists and Task Tracking

- Multiple checklists per project
- Items with due date, priority, estimated cost, notes
- One-tap completion
- Progress tracking and reorder support
- Filters: all, pending, completed
- Batch actions
- Optional reminders

### 3.3 Ideas and Inspiration

- Save links with metadata (title, preview image, source domain)
- Support social links (Instagram, TikTok, Pinterest, YouTube)
- iOS Share Sheet integration
- Notes and tags on ideas
- Grid/list layouts and filtering

### 3.4 Budget and Expenses

- Set project budget
- Categories per project
- Track expense amount, category, date, vendor, status, receipt photo
- Optional link from checklist item to expense
- Spent vs remaining, warnings, category breakdown
- Multi-currency support
- Export report (PDF/CSV in later phases)

### 3.5 Notes

- Unlimited project notes
- MVP starts with plain text notes
- Attachments and richer formatting are post-MVP
- Pin and sort notes

### 3.6 Universal Search

- Search across projects, checklist items, ideas, expenses, and notes
- Filter by content type, project, date range
- Recent searches and suggestions
- Spotlight integration as a later step

## 4) Technical Foundation (Agreed Direction)

- Platform: iOS 18.0+, iPhone
- Language/UI: Swift 5.9+, SwiftUI, NavigationStack
- Architecture: MVVM with Observable state patterns
- Storage: SQLite via SQLite.swift (App Group container)
- App Group identifier (Release): `group.dev.mgorbatyuk.creativityhub`
- Cloud/backup: iCloud backup support (sync can evolve later)
- Analytics: Firebase Analytics in Release builds only
- Localization: all user-facing strings via `L()` function
- Currency precision: use `Decimal` (never `Double`)

## 5) High-Level Data Model

- Project: id, name, description, cover, status, dates, timestamps
- Checklist: id, projectId, name, sortOrder, timestamps
- ChecklistItem: id, checklistId, name, completion, dueDate, priority, estimatedCost, notes, sortOrder
- Idea: id, projectId, url, title, thumbnailUrl, sourceDomain, sourceType, notes, timestamps
- Tag: id, name, color
- Expense: id, projectId, categoryId, amount, currency, date, vendor, status, receiptImageUrl, notes
- Category: id, projectId, name, budgetLimit, color
- Note: id, projectId, title, content, isPinned, sortOrder, timestamps

## 6) App Navigation

Tab structure:
1. Today (search, top due tasks, top active projects)
2. Project Detail (segmented content)
3. Projects (all projects grid/list)
4. Settings

Project Detail sections:
- Checklists
- Ideas
- Documents
- Notes
- Budget

## 7) MVP Definition

Must have:
- Project creation/management
- Basic checklist completion tracking
- Save links as ideas with metadata/thumbnail extraction
- Simple budget tracking (budget, expenses, balance)
- Basic plain-text notes
- Universal search across local data
- Local database persistence

Post-MVP:
- iCloud sync expansion
- Share extension
- Widgets
- Rich text notes
- Budget charts/reports
- Receipt attachments improvements
- Advanced reminders and collaboration

## 8) Implementation Roadmap

Status legend: completed, partial, pending.

| Phase | Description | Status |
|---|---|---|
| 1 | Project foundation (project setup, dependencies, configs, entitlements) | completed |
| 2 | Domain models | done ✅ |
| 3 | Error handling and logging | done ✅ |
| 4 | Database layer (repositories, migrations, manager) | done ✅ |
| 5 | Core services | done ✅ |
| 6 | Shared UI components | done ✅ |
| 7 | Localization setup (en/ru/kk) | done ✅ |
| 8 | Onboarding flow | done ✅ |
| 9 | Settings module | done ✅ |
| 10 | Tab navigation and feature stubs | done ✅ |
| 11 | App entry point wiring | done ✅ |
| 12 | Firebase scripts/setup | completed |
| 13 | Testing and validation | done ✅ |

## 9) Feature-to-Phase Mapping

- Projects: phases 2, 4, 10
- Checklists/task tracking: phases 2, 4, 10
- Ideas/inspiration: phases 2, 4, 10, optional share extension later
- Budget/expenses: phases 2, 4, 9, 10
- Notes: phases 2, 4, 10
- Search: phases 4, 10 (expand iteratively)
- Localization and user settings: phases 5, 7, 9

## 10) Dependency Order

1. Complete base app phases in order (1 to 13)
2. Ensure Firebase setup before analytics-dependent behavior in release
3. Add share extension only after base app is stable

Important dependency notes:
- App Group setup is already included in foundation for future extension support
- Use `group.dev.mgorbatyuk.creativityhub` as the canonical Release App Group identifier in all plans/docs
- If Firebase is skipped, remove analytics service wiring and Firebase init paths

## 11) Quality Gates and Acceptance Criteria

Build and quality checks:
- Project builds on iPhone simulator target
- Formatting and lint scripts pass
- Tests pass (`./run_tests.sh`)

Functional checks:
- App launches without crash
- Onboarding works end-to-end
- Tab navigation works
- Language change updates UI text
- Currency settings persist correctly
- Color scheme preferences apply correctly
- Notifications permission flow behaves correctly
- Export/import flows work when implemented

## 12) Implementation Rules

- No hardcoded user-facing strings; always use `L()`
- No force unwrap unless provably safe
- No `print()` for runtime logging
- No `AnyView`
- Keep views small and composable
- Use async/await where appropriate

## 13) Future Extensions (After MVP)

- Share extension for saving links from external apps
- Spotlight integration
- WidgetKit quick actions
- Rich note editor and attachment workflows
- Advanced reporting and export enhancements
- Collaboration and cross-platform roadmap

## 14) Competitive Positioning

1. One app for planning + inspiration + budget + notes
2. Strong social-media link capture workflow
3. Connection between tasks and spending
4. Unified search across all planning artifacts
5. Built specifically for creative planning use cases
