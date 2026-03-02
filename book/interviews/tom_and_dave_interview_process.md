# Tom and Dave Interview Process (Simple)

This is for friendly book interviews. Keep it simple.

## Step 1: Keep the Excel list up to date

In Interview list.xlsx, make sure each interview has:
- Name
- Chapter
- Interview Date
- Tom / Dave

That is the source of truth.

## Step 2: Save interview files in Google Drive

After each interview, save the recording/transcript in:
G:\My Drive\The Target Trap (Book Project)\Interviews\Raw

Put the guest name in the filename so it is easy to find.

Example filenames:
- Jonathan Wilson interview transcript.docx
- Daisy Christodoulou interview.m4a

## Step 3: Ask Codex to do the rest

You do not need to run scripts manually.

Just ask Codex:

"Process the interview for [Guest Name] from Interview list.xlsx, use files in G:\My Drive\The Target Trap (Book Project)\Interviews\Raw, and draft notes."

What Codex will do:
- read interview details from Excel
- create/update the interview folder
- find matching source files in Google Drive Interviews/Raw
- import files and update the index
- draft notes for the interview and paste the final note file into Google Drive Interviews folder

Codex will fill:
- pass 1 index notes
- pass 2 book notes
- pass 3 quote bank
- and a simple final notes file in Google Drive Interviews named like:
  Chapter 2 - Daisy Christodoulou.md
