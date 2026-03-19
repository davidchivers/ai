# Email app memory

## Purpose

Track design decisions and practical conventions for the student enquiry email workflow prototype.

## Current decisions

- Intake channel: Microsoft Forms.
- Automation layer: Power Automate cloud flow.
- Lookup source for version 1: Excel Online table stored in OneDrive or SharePoint.
- Main lookup key: normalized university email address.
- Identity capture model: signed-in Forms users with recorded responder identity; do not ask for username or email in the preferred build.
- Staff handling model: inbox/shared mailbox, not a case-management app.
- Routing model in version 1: advisory tags and suggested owner only.
- Banner integration in version 1: identifiers and deep links only, no live transactional integration.
- Reference number design for version 1: `DEPT-YYYY-######` using padded Forms response ID.

## Working conventions

- Keep this project plain-English and admin-facing.
- Prefer stable Markdown docs and copy/paste templates over low-level export files.
- Treat Excel as an enrichment source, not as the workflow engine.
- If lookup fails, the flow still sends the staff email and student acknowledgement.

## Open items

- Final department mailbox addresses.
- Final suggested-owner mapping by enquiry type.
- Whether mitigating circumstances and extension enquiries should stay on this form or be redirected to formal university processes.
- Website publishing under `davidshivers.co.uk/email_app` is handled by Tom Shutt / David Chivers, not by this repo rollout.

## Session notes

- 2026-03-18: Created the initial prototype pack under `other/email_app` with specification, build plan, flow notes, templates, and sample lookup schema.
- 2026-03-19: Shifted the preferred build to signed-in Forms users with recorded responder email as the primary lookup key, and noted that website deployment is handled separately by Tom Shutt / David Chivers.
