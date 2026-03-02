# Department Admin Project

## Purpose

Set up private SharePoint folders so each staff member can only access their own folder, while administrator(s) can access all folders.

This project is written for non-technical administrators and avoids research-specific workflow.

## What to Open First

1. `projects/department_admin_project/README.md` (this file)
2. `projects/department_admin_project/ADMIN_RUNBOOK.md`
3. `projects/department_admin_project/templates/faculty_folder_map_example.csv`

## Deliverable Format (Simple)

Use this communication format with administrators:

- One-page goal: what this system does and who can access what.
- Setup checklist: exact click-by-click steps.
- Copy/paste templates: email body + spreadsheet columns.
- Repeatable flows: one flow for setup, one for emailing links, one optional for file routing.
- Handover checklist: how to run monthly with no AI support.

## Next 3 Concrete Tasks

1. Create SharePoint site/library and the `FacultyFolderMap` list.
2. Import your real staff list into the template CSV and run `Provision Faculty Folders`.
3. Run `Email Folder Links` and confirm 2-3 users can access only their own folders.

## Files in This Project

- `projects/department_admin_project/ADMIN_RUNBOOK.md`: plain-English steps.
- `projects/department_admin_project/memory.md`: key decisions and local conventions.
- `projects/department_admin_project/templates/faculty_folder_map_example.csv`: starter data.
- `projects/department_admin_project/templates/email_template.html`: send-to-staff email template.
- `projects/department_admin_project/flows/power_automate_expressions.md`: copy/paste expressions used in flows.
