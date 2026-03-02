#!/usr/bin/env python3
"""Simple Excel-first interview workflow for book interviews.

Flow:
1) Read interview row from Excel.
2) Create/update interview folder.
3) Find matching source file(s) in local Google Drive synced folder.
4) Ingest files and update index.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import _interview_lib as lib


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Excel-first interview processor: create folder, find matching files, ingest, and update index.",
    )
    parser.add_argument(
        "--interviews-root",
        type=Path,
        default=lib.default_interviews_root(__file__),
        help="Path to interviews root (default: parent of scripts directory).",
    )
    parser.add_argument(
        "--excel",
        type=str,
        default=None,
        help="Interview tracker workbook path. Defaults to auto-detection.",
    )
    parser.add_argument(
        "--sheet",
        type=str,
        default=None,
        help="Optional sheet name. Defaults to first sheet.",
    )
    parser.add_argument(
        "--name",
        type=str,
        default=None,
        help="Guest name to match from Excel (recommended).",
    )
    parser.add_argument(
        "--row-index",
        type=int,
        default=None,
        help="Zero-based DataFrame row index in Excel sheet.",
    )
    parser.add_argument(
        "--drive-root",
        type=str,
        default=None,
        help="Local Google Drive sync folder to search for interview files.",
    )
    parser.add_argument(
        "--source-file",
        dest="source_files",
        action="append",
        default=None,
        help="Specific source file to ingest (repeat for multiple). If set, drive searching is skipped.",
    )
    parser.add_argument(
        "--max-files",
        type=int,
        default=3,
        help="Max matching files to ingest from drive search (default: 3).",
    )
    parser.add_argument(
        "--mode",
        choices=["copy", "move"],
        default="copy",
        help="Ingest mode for found files (default: copy).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned actions without running new_interview/ingest.",
    )
    return parser.parse_args()


def _now_utc_date() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def _to_text(value: object) -> str:
    text = lib.normalize_whitespace(value)
    if text.lower() in {"nan", "none", "nat"}:
        return ""
    return text


def _to_date_text(value: object) -> str:
    text = _to_text(value)
    if not text:
        return ""
    # Handle pandas timestamps and common date strings.
    for fmt in ("%Y-%m-%d", "%m/%d/%Y", "%d/%m/%Y", "%d-%m-%Y", "%m-%d-%Y", "%Y/%m/%d"):
        try:
            return datetime.strptime(text[:10], fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    if len(text) >= 10 and text[4] == "-" and text[7] == "-":
        return text[:10]
    return ""


def _is_done(value: object) -> bool:
    v = _to_text(value).lower()
    return v in {"y", "yes", "done", "true", "1"}


def _default_drive_root_candidates(interviews_root: Path) -> List[Path]:
    return [
        Path(r"G:/My Drive/The Target Trap (Book Project)/Interviews/Raw"),
        interviews_root / "interview_raw",
        Path(r"G:/My Drive/The Target Trap (Book Project)"),
        Path(r"G:/My Drive"),
        Path(r"C:/Users/Dave_/OneDrive/Desktop/Economics/projects/book"),
    ]


def _detect_drive_root(explicit: Optional[str], interviews_root: Path) -> Optional[Path]:
    candidates: List[Path] = []
    if explicit:
        p = Path(explicit).expanduser()
        if not p.is_absolute():
            p = (Path.cwd() / p).resolve()
        candidates.append(p)
    env_val = _to_text(__import__("os").environ.get("INTERVIEW_DRIVE_ROOT", ""))
    if env_val:
        candidates.append(Path(env_val))
    candidates.extend(_default_drive_root_candidates(interviews_root))

    seen = set()
    for c in candidates:
        key = str(c).lower()
        if key in seen:
            continue
        seen.add(key)
        if c.exists() and c.is_dir():
            return c
    return None


def _detect_shared_interviews_folder(interviews_root: Path) -> Optional[Path]:
    candidates: List[Path] = []
    env_val = _to_text(os.environ.get("INTERVIEWS_SHARED_FOLDER", ""))
    if env_val:
        candidates.append(Path(env_val))
    candidates.append(Path(r"G:/My Drive/The Target Trap (Book Project)/Interviews"))
    candidates.append(interviews_root)

    seen = set()
    for c in candidates:
        key = str(c).lower()
        if key in seen:
            continue
        seen.add(key)
        if c.exists() and c.is_dir():
            return c
    return None


def _load_excel_rows(excel_path: Path, sheet: Optional[str]) -> Tuple[List[Dict[str, object]], str]:
    import pandas as pd  # type: ignore

    if sheet:
        df = pd.read_excel(excel_path, sheet_name=sheet, engine="openpyxl")
        sheet_name = sheet
    else:
        xls = pd.ExcelFile(excel_path, engine="openpyxl")
        sheet_name = xls.sheet_names[0]
        df = pd.read_excel(excel_path, sheet_name=sheet_name, engine="openpyxl")

    records: List[Dict[str, object]] = []
    for idx, row in df.iterrows():
        record = dict(row)
        record["_row_index"] = int(idx)
        records.append(record)
    return records, sheet_name


def _select_row(records: List[Dict[str, object]], name: Optional[str], row_index: Optional[int]) -> Dict[str, object]:
    if row_index is not None:
        for record in records:
            if int(record.get("_row_index", -1)) == row_index:
                return record
        raise ValueError(f"Row index {row_index} not found in sheet.")

    if name:
        name_key = _to_text(name).lower()
        matches = []
        for record in records:
            guest = _to_text(record.get("Name", ""))
            if guest and name_key in guest.lower():
                matches.append(record)
        if not matches:
            raise ValueError(f"No Excel row found for name containing '{name}'.")
        if len(matches) == 1:
            return matches[0]
        # Prefer row with interview date if ambiguous.
        dated = [r for r in matches if _to_date_text(r.get("Interview Date", ""))]
        if len(dated) == 1:
            return dated[0]
        choices = ", ".join(_to_text(r.get("Name", "")) for r in matches[:5])
        raise ValueError(f"Multiple matches for '{name}'. Try --row-index. Matches: {choices}")

    # Default: next row with name + interview date and not done.
    candidates = [
        r
        for r in records
        if _to_text(r.get("Name", "")) and _to_date_text(r.get("Interview Date", "")) and not _is_done(r.get("Done", ""))
    ]
    if candidates:
        candidates.sort(key=lambda r: _to_date_text(r.get("Interview Date", "")))
        return candidates[0]

    # Fallback: first row with a name.
    for record in records:
        if _to_text(record.get("Name", "")):
            return record
    raise ValueError("No usable rows found in Excel.")


def _build_interview_fields(row: Dict[str, object]) -> Dict[str, object]:
    guest_name = _to_text(row.get("Name", "")) or "Unknown Guest"
    chapter = _to_text(row.get("Chapter", "")) or "book-interview"
    interview_date = _to_date_text(row.get("Interview Date", "")) or _now_utc_date()
    interviewer = _to_text(row.get("Tom / Dave", ""))
    response = _to_text(row.get("Response", ""))
    done = _is_done(row.get("Done", ""))

    tags = []
    if interviewer:
        tags.append(interviewer.lower())
    tags.append("friendly_interview")
    if response:
        tags.append(f"response:{response.lower()}")

    status = "notes_done" if done else "planned"
    topic = chapter
    topic_slug = lib.slugify_topic(topic)
    folder_name = f"{interview_date}__{lib.guest_folder_token(guest_name)}__{topic_slug}"
    return {
        "date": interview_date,
        "guest_name": guest_name,
        "topic": topic,
        "chapter": chapter,
        "tags": lib.dedupe_preserve_order(tags),
        "status": status,
        "folder_name": folder_name,
    }


def _ext_weight(ext: str) -> int:
    ext = ext.lower()
    if ext in {".txt", ".md"}:
        return 9
    if ext in {".docx", ".doc", ".rtf"}:
        return 8
    if ext in {".vtt", ".srt"}:
        return 7
    if ext in {".mp3", ".m4a", ".wav", ".flac", ".aac"}:
        return 5
    if ext in {".pdf"}:
        return 2
    return 1


def _candidate_score(path: Path, guest_name: str, interview_date: str) -> Tuple[int, int, bool]:
    stem = path.stem.lower()
    blob = str(path).lower()
    full_name = guest_name.lower().strip()
    tokens = [t for t in full_name.replace("-", " ").split() if t and len(t) >= 2]
    score = 0
    matched_tokens = 0
    full_match = False
    if full_name and full_name in stem:
        score += 20
        full_match = True
    for token in tokens:
        if token in blob:
            score += 5
            matched_tokens += 1
    date_token = interview_date
    if date_token and date_token in blob:
        score += 8
    if "interview" in stem:
        score += 2
    score += _ext_weight(path.suffix)
    return score, matched_tokens, full_match


def _find_matching_files(
    drive_root: Path,
    guest_name: str,
    interview_date: str,
    max_files: int,
) -> List[Path]:
    allowed_ext = lib.AUDIO_EXTENSIONS | lib.TRANSCRIPT_EXTENSIONS | lib.EXPORT_EXTENSIONS
    candidates: List[Tuple[int, Path]] = []
    for path in drive_root.rglob("*"):
        if not path.is_file():
            continue
        if path.name.startswith("~$"):
            continue
        if path.suffix.lower() not in allowed_ext:
            continue
        score, matched_tokens, full_match = _candidate_score(
            path, guest_name=guest_name, interview_date=interview_date
        )
        if not full_match and matched_tokens < 1:
            continue
        if score > 6:
            candidates.append((score, path))

    candidates.sort(key=lambda item: (item[0], str(item[1]).lower()), reverse=True)
    out: List[Path] = []
    seen = set()
    for score, path in candidates:
        key = str(path).lower()
        if key in seen:
            continue
        seen.add(key)
        out.append(path)
        if len(out) >= max_files:
            break
    return out


def _run(cmd: List[str], dry_run: bool) -> int:
    if dry_run:
        print("DRY-RUN:", " ".join(f'"{c}"' if " " in c else c for c in cmd))
        return 0
    return subprocess.run(cmd, check=False).returncode


def _resolve_source_files(values: Optional[List[str]]) -> List[Path]:
    out: List[Path] = []
    if not values:
        return out
    for raw in values:
        path = Path(raw).expanduser()
        if not path.is_absolute():
            path = (Path.cwd() / path).resolve()
        if path.exists() and path.is_file():
            out.append(path)
        else:
            print(f"Source file not found, skipped: {path}")
    deduped: List[Path] = []
    seen = set()
    for item in out:
        key = str(item).lower()
        if key in seen:
            continue
        seen.add(key)
        deduped.append(item)
    return deduped


def _safe_filename(text: str) -> str:
    cleaned = lib.normalize_whitespace(text)
    cleaned = re.sub(r"[<>:\"/\\\\|?*]+", "-", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .-")
    return cleaned or "Interview"


def _chapter_label(chapter_text: str) -> str:
    chapter = lib.normalize_whitespace(chapter_text)
    if not chapter:
        return "Interview"
    match = re.search(r"(?i)\bch(?:apter)?\s*([0-9]+)\b", chapter)
    if match:
        return f"Chapter {match.group(1)}"
    return chapter


def _write_notes_stub(
    interviews_root: Path,
    folder_name: str,
    guest_name: str,
    chapter: str,
    topic: str,
    date: str,
    dry_run: bool = False,
) -> List[Path]:
    notes_dir = interviews_root / "interview_notes"
    file_name = f"{_chapter_label(chapter)} - {_safe_filename(guest_name)}.md"
    local_note_path = notes_dir / file_name
    shared_root = _detect_shared_interviews_folder(interviews_root)
    shared_note_path = (shared_root / file_name) if shared_root else None

    interview_workspace = interviews_root / folder_name
    lines = [
        f"# {_chapter_label(chapter)} - {guest_name}",
        "",
        f"- Date: {date}",
        f"- Topic: {topic}",
        f"- Interview Workspace: `{interview_workspace}`",
        "",
        "## Draft Notes",
        "- Summary:",
        "- Key points:",
        "- Best moments:",
        "",
        "## Pull Quotes",
        "- Add best quotes here with timestamps.",
        "",
        "## Fact-Check Flags",
        "- Add claims that need checking.",
        "",
        "## Linked Working Files",
        f"- Pass 1: `{interview_workspace / 'outputs' / 'notes_pass1_index.md'}`",
        f"- Pass 2: `{interview_workspace / 'outputs' / 'notes_pass2_booknotes.md'}`",
        f"- Pass 3: `{interview_workspace / 'outputs' / 'notes_pass3_quotes.md'}`",
        f"- Fact checks: `{interview_workspace / 'outputs' / 'fact_checks.md'}`",
        "",
    ]
    content = "\n".join(lines)
    written_paths: List[Path] = []

    primary = shared_note_path if shared_note_path else local_note_path
    if dry_run:
        written_paths.append(primary)
        if shared_note_path and local_note_path != shared_note_path:
            written_paths.append(local_note_path)
        return written_paths

    if shared_note_path:
        shared_note_path.parent.mkdir(parents=True, exist_ok=True)
        if not shared_note_path.exists():
            shared_note_path.write_text(content, encoding="utf-8")
        written_paths.append(shared_note_path)

    notes_dir.mkdir(parents=True, exist_ok=True)
    if not local_note_path.exists():
        local_note_path.write_text(content, encoding="utf-8")
    written_paths.append(local_note_path)
    return written_paths


def main() -> int:
    args = parse_args()
    interviews_root = args.interviews_root.resolve()
    interviews_root.mkdir(parents=True, exist_ok=True)
    (interviews_root / "interview_raw").mkdir(parents=True, exist_ok=True)
    (interviews_root / "interview_notes").mkdir(parents=True, exist_ok=True)

    excel_path = lib.detect_global_excel(interviews_root, args.excel)
    if excel_path is None or not excel_path.exists():
        raise SystemExit("No Excel tracker found. Pass --excel or place Interview list.xlsx in a detected location.")

    try:
        records, sheet_name = _load_excel_rows(excel_path, args.sheet)
    except Exception as exc:
        raise SystemExit(f"Failed to read Excel: {exc}") from exc

    row = _select_row(records, args.name, args.row_index)
    fields = _build_interview_fields(row)

    guest_name = str(fields["guest_name"])
    topic = str(fields["topic"])
    interview_date = str(fields["date"])
    folder_name = str(fields["folder_name"])

    print(f"Excel: {excel_path}")
    print(f"Sheet: {sheet_name}")
    print(f"Selected row index: {row.get('_row_index')}")
    print(f"Guest: {guest_name}")
    print(f"Date: {interview_date}")
    print(f"Chapter/topic: {topic}")

    new_interview_script = interviews_root / "scripts" / "new_interview.py"
    cmd_new = [
        sys.executable,
        str(new_interview_script),
        "--interviews-root",
        str(interviews_root),
        "--date",
        interview_date,
        "--guest-name",
        guest_name,
        "--topic",
        topic,
        "--status",
        str(fields["status"]),
        "--confidentiality",
        "on_record",
        "--excel",
        str(excel_path),
    ]
    tags = fields["tags"]
    if isinstance(tags, list) and tags:
        cmd_new.append("--tags")
        cmd_new.extend(tags)
    chapter = str(fields.get("chapter", "")).strip()
    if chapter:
        cmd_new.extend(["--chapter-candidates", chapter])

    rc = _run(cmd_new, args.dry_run)
    if rc != 0:
        return rc

    explicit_sources = _resolve_source_files(args.source_files)
    if explicit_sources:
        matches = explicit_sources
        print("Using explicit source files:")
        for m in matches:
            print(f"  - {m}")
    else:
        drive_root = _detect_drive_root(args.drive_root, interviews_root)
        if drive_root is None:
            print(
                "No input folder found. Interview folder created; drop transcript/audio into "
                r"G:\My Drive\The Target Trap (Book Project)\Interviews\Raw "
                "or provide --source-file."
            )
            note_paths = _write_notes_stub(
                interviews_root=interviews_root,
                folder_name=folder_name,
                guest_name=guest_name,
                chapter=chapter,
                topic=topic,
                date=interview_date,
                dry_run=args.dry_run,
            )
            for p in note_paths:
                print(f"Notes file: {p}")
            return 0
        print(f"Drive root: {drive_root}")

        matches = _find_matching_files(
            drive_root=drive_root,
            guest_name=guest_name,
            interview_date=interview_date,
            max_files=max(args.max_files, 1),
        )

        if not matches:
            print(
                "No matching source files found. Drop file into "
                r"G:\My Drive\The Target Trap (Book Project)\Interviews\Raw "
                "(with guest name in filename) and run again."
            )
            note_paths = _write_notes_stub(
                interviews_root=interviews_root,
                folder_name=folder_name,
                guest_name=guest_name,
                chapter=chapter,
                topic=topic,
                date=interview_date,
                dry_run=args.dry_run,
            )
            for p in note_paths:
                print(f"Notes file: {p}")
            return 0

        print("Matched files:")
        for m in matches:
            print(f"  - {m}")

    ingest_script = interviews_root / "scripts" / "ingest_files.py"
    cmd_ingest = [
        sys.executable,
        str(ingest_script),
        "--interviews-root",
        str(interviews_root),
        "--interview",
        folder_name,
        "--mode",
        args.mode,
        "--excel",
        str(excel_path),
    ]
    for path in matches:
        cmd_ingest.extend(["--file", str(path)])

    rc = _run(cmd_ingest, args.dry_run)
    if rc != 0:
        return rc

    interview_dir = interviews_root / folder_name
    note_paths = _write_notes_stub(
        interviews_root=interviews_root,
        folder_name=folder_name,
        guest_name=guest_name,
        chapter=chapter,
        topic=topic,
        date=interview_date,
        dry_run=args.dry_run,
    )
    print(f"Done. Interview workspace ready at: {interview_dir}")
    for p in note_paths:
        print(f"Notes file: {p}")
    print("Next: ask Codex to draft Pass 1/2/3 notes from the ingested transcript.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
