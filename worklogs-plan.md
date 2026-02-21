# Work Logs Feature Plan

## Goal

Add time logging to CreativityHub so users can log time spent on work, starting from checklist completion and also via Active Project "Add New".

## Requirements

- When a checklist item is marked done, user can optionally log time.
- Work log form has three fields: days, hours, and minutes (all integers).
- Work logs are stored in total minutes (`totalMinutes`, Int).
- Conversion rule: `totalMinutes = days * 1440 + hours * 60 + minutes`.
- Work log may be linked to a checklist item, but link is optional.
- Work logs list is visible from Active Project screen.
- Work log creation is available from Active Project "Add New" dialog.

## Implementation Plan

1. Data model and database migration
   - Add `WorkLog` model in `BusinessLogic/Models/WorkLog.swift`.
   - Fields: `id`, `projectId`, `linkedChecklistItemId?`, `totalMinutes` (Int), `createdAt`, `updatedAt`.
   - Add migration `BusinessLogic/Database/Migrations/Migration_202602XX_AddWorkLogsTable.swift` creating `work_logs`.
   - Update `BusinessLogic/Database/DatabaseManager.swift`:
     - bump schema version,
     - initialize `workLogRepository`,
     - include work log cleanup in `deleteAllData()` and project cascade delete.

2. Repository layer
   - Add `BusinessLogic/Database/Repositories/WorkLogRepository.swift`.
   - Implement:
     - `fetchByProjectId(projectId:)`,
     - `fetchByChecklistItemId(checklistItemId:)`,
     - `insert(_:)`, `update(_:)`, `delete(id:)`,
     - `deleteByProjectId(projectId:)`,
     - `countByProjectId(projectId:)`,
     - `totalMinutesByProjectId(projectId:)`,
     - `totalHoursByProjectId(projectId:)` — returns `totalMinutes / 60` as Int (whole hours).
   - Add helper to detach checklist links when checklist items are deleted (`linkedChecklistItemId = nil`).

3. Backup import/export
   - Extend `BusinessLogic/Models/ExportModels.swift` with `workLogs: [WorkLog]?`.
   - Update `CreativityHub/Services/BackupService.swift` to export/import work logs.

4. Checklist completion flow
   - Update `CreativityHub/Features/Checklists/ChecklistDetailView.swift` and `ChecklistDetailViewModel.swift`.
   - When toggling pending -> done, show options:
     - `Mark Done`
     - `Mark Done + Log Time`
   - If user selects logging, open WorkLog form prelinked to that checklist item.
   - Keep done -> pending toggle direct (no logging prompt).

5. Work logs UI
   - Add `CreativityHub/Features/WorkLogs/WorkLogFormView.swift`.
   - Form fields:
     - Days (Int),
     - Hours (Int),
     - Minutes (Int).
   - Convert to total minutes on save (`days * 1440 + hours * 60 + minutes`).
   - Validation:
     - days >= 0,
     - hours >= 0,
     - minutes >= 0,
     - total minutes > 0,
     - recommended: hours in `0...23`, minutes in `0...59`.
   - Include optional checklist item picker (`None` + project checklist items).

   - Add `CreativityHub/Features/WorkLogs/WorkLogsListView.swift`.
   - Show project work logs newest first, with:
     - formatted duration (e.g. "2d 3h 15m", "1h 30m", "45m"),
     - linked checklist item label if present,
     - created date/time.
   - Support delete (edit can be added later).

6. Active Project integration
   - Update `CreativityHub/Features/Projects/ProjectContentViewModel.swift`:
     - add work log count and preview list.
   - Update `CreativityHub/Features/Projects/ProjectContentView.swift`:
     - add `Work Logs` section,
     - add preview rows,
     - add navigation to full `WorkLogsListView`.

7. Add New integration
   - In `ProjectContentView.swift` Add New sheet, add a Work Log tile.
   - Suggested icon/color: `clock.fill` + indigo.
   - Open WorkLog form from this action.

8. Localization
   - Add keys in `en`, `ru`, `kk` for:
     - section titles,
     - form labels (days, hours, minutes),
     - action labels,
     - validation errors,
     - empty states.

9. QA and verification
   - Build app and verify:
     - checklist done -> optional logging flow,
     - Add New -> Work Log flow,
     - Active Project Work Logs section and list,
     - backup export/import includes work logs,
     - checklist item deletion correctly detaches link.

## Default decisions for V1

- Store work duration as total minutes (`Int`). User enters days/hours/minutes, stored as `days * 1440 + hours * 60 + minutes`.
- Display formatted as compact duration string (e.g. "2d 3h 15m", "1h 30m", "45m").
- Keep logs when linked checklist item is deleted; clear the link only.
- Support add/list/delete in V1, defer edit to later iteration.
