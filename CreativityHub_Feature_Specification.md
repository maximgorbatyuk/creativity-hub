# CreativityHub

## iOS App Feature Specification

**Version 2026.1.1 | January 2026**

---

## Executive Summary

CreativityHub is an all-in-one iOS application designed for creative project planning. It combines task management, inspiration collection, budget tracking, and note-taking into a unified experience with powerful search capabilities. The app addresses a gap in the market where existing solutions require users to juggle multiple apps for different aspects of creative project planning.

---

## Target Users

- Event planners (weddings, parties, corporate events)
- DIY enthusiasts and home renovators
- Content creators planning shoots or campaigns
- Artists and designers managing creative projects
- Small business owners launching products or services
- Anyone planning a creative endeavor with multiple moving parts

---

## Core Features

### 1. Projects

Projects serve as containers for all related content. Each project groups checklists, ideas, budget items, and notes together.

#### Functionality

- Create unlimited projects with custom names and optional descriptions
- Assign cover images or colors for visual identification
- Set project status: Active, Completed, Archived
- Add optional start and target completion dates
- View overall progress percentage calculated from checklist completion
- Pin favorite projects for quick access
- Sort projects by date created, last modified, or custom order

---

### 2. Checklists & Task Tracking

Checklists help users track items to do or buy. Multiple checklists can exist within a single project, each with its own progress tracking.

#### Functionality

- Create multiple checklists per project (e.g., "Things to Buy", "Tasks to Complete")
- Add checklist items with optional details:
  - Due date
  - Priority level (High, Medium, Low)
  - Estimated cost (links to budget tracking)
  - Notes or description
  - Assignee (for collaborative projects)
- Mark items as complete with single tap
- Visual progress bar showing completion percentage
- Reorder items via drag and drop
- Filter view: All, Pending, Completed
- Batch actions: mark multiple as complete, delete selected
- Optional reminders and notifications for due dates

---

### 3. Ideas & Inspiration Library

A dedicated space to save and organize creative inspiration from across the web, with special support for social media content.

#### Functionality

- Save links from any source with automatic metadata extraction:
  - Title
  - Thumbnail/preview image
  - Source domain
- Native support for social media platforms:
  - Instagram Reels and posts
  - TikTok videos
  - Pinterest pins
  - YouTube videos
- iOS Share Sheet integration for easy saving from other apps
- Add personal notes to each saved idea
- Tag ideas with custom labels for organization
- Grid or list view options
- Filter by source type or tags
- Quick preview without leaving the app (embedded player for videos)

---

### 4. Budget & Expense Tracking

Comprehensive financial tracking to help users plan and monitor spending for their creative projects.

#### Functionality

- Set overall project budget
- Create budget categories (e.g., Materials, Services, Venue, Equipment)
- Track individual expenses with:
  - Amount
  - Category
  - Date
  - Vendor/payee
  - Payment status (Planned, Paid, Pending)
  - Receipt photo attachment
- Link expenses to checklist items
- Visual budget breakdown:
  - Pie chart by category
  - Progress bar: spent vs. remaining
  - Over-budget warnings
- Support for multiple currencies
- Export budget report as PDF or CSV

---

### 5. Notes

Flexible note-taking for capturing thoughts, meeting notes, vendor details, or any text-based information.

#### Functionality

- Create unlimited notes within each project
- Rich text formatting:
  - Bold, italic, underline
  - Headings
  - Bullet and numbered lists
  - Checklists within notes
- Attach images and files to notes
- Link notes to specific checklist items or ideas
- Pin important notes to top
- Sort by date created, date modified, or custom order
- Quick note creation from home screen widget

---

### 6. Universal Search

Powerful search functionality to find anything across all projects and content types.

#### Functionality

- Search across all content types simultaneously:
  - Project names and descriptions
  - Checklist item names and notes
  - Idea titles, notes, and tags
  - Expense descriptions and vendors
  - Note content
- Filter search results by content type
- Filter by project
- Filter by date range
- Recent searches history
- Spotlight integration for system-wide search on iOS
- Search suggestions and autocomplete

---

## Data Model Overview

| Entity | Key Attributes | Relationships |
|--------|----------------|---------------|
| **Project** | id, name, description, coverImage, status, startDate, targetDate, createdAt, updatedAt | Has many: Checklists, Ideas, Expenses, Notes |
| **Checklist** | id, projectId, name, sortOrder, createdAt | Belongs to: Project; Has many: ChecklistItems |
| **ChecklistItem** | id, checklistId, name, isCompleted, dueDate, priority, estimatedCost, notes, sortOrder | Belongs to: Checklist; Optional: linked Expense |
| **Idea** | id, projectId, url, title, thumbnailUrl, sourceDomain, sourceType, notes, createdAt | Belongs to: Project; Has many: Tags |
| **Tag** | id, name, color | Has many: Ideas |
| **Expense** | id, projectId, categoryId, amount, currency, date, vendor, status, receiptImageUrl, notes | Belongs to: Project, Category; Optional: linked ChecklistItem |
| **Category** | id, projectId, name, budgetLimit, color | Belongs to: Project; Has many: Expenses |
| **Note** | id, projectId, title, content (rich text), isPinned, sortOrder, createdAt, updatedAt | Belongs to: Project; Has many: Attachments |

---

## User Interface Structure

### Navigation

The app uses a tab-based navigation with five main sections:

1. **Today** — Search form, Top 3 due tasks (deadline), top 3 active projects
2. **Project page** - Page should contain sections with all Domain models that relates to the Project. Checklists, Ideas, Expenses, Notes, Documents, etc
3. **Projects** — Grid/list view of all projects with create button
4. **Settings** — App preferences, sync, and export options

### Project Detail View

When a user opens a project, they see a segmented view with four sections:

- **Checklists** — All checklists with progress indicators
- **Ideas** — Grid of saved inspiration for this project
- **Documents** — Grid of saved documents for this project
- **Notes** — List of notes with preview
- **Budget** — Financial overview and expense list

---

## Technical Requirements

### Platform

- iOS 18.0 and later
- iPhone
- SwiftUI for user interface

### Data Storage

- Local storage: Core Data or SwiftData
- Cloud sync: iCloud with CloudKit
- Image storage: Local with optional iCloud backup

### Integrations

- iOS Share Sheet extension for saving links
- Spotlight Search integration
- Local notifications for reminders
- Home Screen Widgets (WidgetKit) - optional, for future implementation
- Link metadata extraction (LinkPresentation framework) - optional, for future implementation

---

## MVP Scope (Version 2026.1.1)

### Must Have

- [ ] Project creation and management
- [ ] Basic checklist functionality with completion tracking
- [ ] Save links as ideas with automatic thumbnail extraction
- [ ] Simple budget tracking (total budget, add expenses, view balance)
- [ ] Basic notes with plain text
- [ ] Universal search across all content
- [ ] Local data storage

### Nice to Have (Post-MVP)

- [ ] iCloud sync
- [ ] Share Sheet extension
- [ ] Widgets
- [ ] Rich text notes
- [ ] Budget charts and reports
- [ ] Receipt photo attachments
- [ ] Due date reminders
- [ ] Collaboration features

---

## Future Considerations (Version 2.0+)

- Project templates (Wedding, Home Renovation, Content Campaign, etc.)
- Collaboration and sharing with other users
- AI-powered suggestions based on project type
- Integration with external services (Google Calendar, Apple Reminders)
- macOS companion app
- Export project as PDF report
- Vendor/contact management

---

## Competitive Advantages

1. **All-in-one solution** — No need to switch between multiple apps
2. **Social media integration** — First-class support for saving TikTok, Instagram, and Pinterest inspiration
3. **Budget-checklist linking** — Unique connection between tasks and expenses
4. **Universal search** — Find anything across all content types instantly
5. **Creative focus** — Designed for creative projects, not generic project management

---

## Appendix: User Stories

### Projects

- As a user, I want to create a new project so I can organize all planning for a specific endeavor
- As a user, I want to see my project progress at a glance so I know how much work remains
- As a user, I want to archive completed projects so my active list stays clean

### Checklists

- As a user, I want to create multiple checklists within a project so I can separate "to buy" from "to do"
- As a user, I want to set due dates on items so I don't miss deadlines
- As a user, I want to see a progress bar so I feel motivated as I complete tasks

### Ideas

- As a user, I want to save an Instagram Reel directly from the app so I can reference it later
- As a user, I want to tag my saved ideas so I can filter by theme or category
- As a user, I want to add notes to saved links so I remember why I saved them

### Budget

- As a user, I want to set a total budget so I can track if I'm overspending
- As a user, I want to categorize expenses so I can see where my money goes
- As a user, I want to link an expense to a checklist item so I can track costs per task

### Notes

- As a user, I want to jot down quick notes during vendor meetings
- As a user, I want to attach photos to notes for reference
- As a user, I want to pin important notes so they're always visible

### Search

- As a user, I want to search across all my projects to find something I saved months ago
- As a user, I want to filter search results by type so I can narrow down results quickly
