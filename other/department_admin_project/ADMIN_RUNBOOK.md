# Administrator Runbook: Private Promotion Folders

## Outcome

Each person in the department gets one private folder.

Only these people can access each folder:
- That specific person
- Administrator(s)

## Before You Start (10 minutes)

1. Confirm admin emails.
2. Confirm staff email list is complete.
3. Confirm access type for staff:
   - `Can edit` (recommended for application uploads)
   - `Can view` (if admin uploads only)

## Step 1: Create SharePoint Location

1. Create or open site: `AcademicAdmin`.
2. Create document library: `PromotionFiles`.
3. Create SharePoint list: `FacultyFolderMap`.

Required list columns:
- `Title` (full name)
- `Email` (single line text)
- `FolderName` (single line text, e.g., `Smith_Alice`)
- `FolderLink` (hyperlink)

## Step 2: Load Staff List

1. Open `templates/faculty_folder_map_example.csv`.
2. Replace sample names/emails with real staff.
3. Import rows into `FacultyFolderMap`.

## Step 3: Build Flow A (Provision Folders)

Flow name: `Provision Faculty Folders`
Trigger: Manual

Actions:
1. `Get items` from `FacultyFolderMap`.
2. `Apply to each` row.
3. `Create new folder` in `PromotionFiles` using `FolderName`.
4. `Grant access to an item or a folder` to staff `Email`.
5. `Grant access to an item or a folder` to admin email(s).
6. `Create sharing link for a file or folder`.
7. `Update item` and save returned link into `FolderLink`.

If permissions leak from parent library:
- Add `Stop sharing an item or file` right after folder creation.
- Then grant only staff + admin.

## Step 4: Build Flow B (Email Each Person Their Own Link)

Flow name: `Email Folder Links`
Trigger: Manual

Actions:
1. `Get items` from `FacultyFolderMap`.
2. `Apply to each`.
3. `Send an email (V2)` to `Email` with folder link from `FolderLink`.

Use template in `templates/email_template.html`.

## Step 5 (Optional): Build Flow C (Route New Files)

Use this when admin wants easy distribution.

1. Create library: `AdminDropoff`.
2. Add metadata column in `AdminDropoff`: `TargetEmail`.
3. Flow trigger: `When a file is created` in `AdminDropoff`.
4. Lookup matching row in `FacultyFolderMap` by `TargetEmail`.
5. Copy file to `/PromotionFiles/<FolderName>`.

## Monthly Operating Routine (No AI Needed)

1. Add new staff row to `FacultyFolderMap`.
2. Run `Provision Faculty Folders`.
3. Run `Email Folder Links`.
4. Test one account for correct private access.

## Handover Checklist

- [ ] Library and list exist.
- [ ] All staff rows imported.
- [ ] Flow A created and tested.
- [ ] Flow B created and tested.
- [ ] Optional Flow C tested.
- [ ] Admin backup owner added to all flows.
- [ ] One-page SOP saved in team docs.

## Troubleshooting

- User cannot open folder:
  - Re-run Flow A for that user.
  - Confirm email in list exactly matches M365 account.
- User sees other folders:
  - Check inheritance was broken or sharing was reset.
- Email link missing:
  - Check Flow A wrote `FolderLink` before Flow B ran.
