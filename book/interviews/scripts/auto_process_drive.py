#!/usr/bin/env python3
"""Automatically process new interview files from a local Google Drive folder.

This script watches for new/updated transcript/audio/export files, matches them
to guest names from Interview list.xlsx, and runs process_from_excel.py.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import _interview_lib as lib

ALLOWED_EXTENSIONS = lib.AUDIO_EXTENSIONS | lib.TRANSCRIPT_EXTENSIONS | lib.EXPORT_EXTENSIONS
GENERIC_NAME_TOKENS = {
    "a",
    "an",
    "the",
    "former",
    "minister",
    "university",
    "ceo",
    "historian",
    "vc",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Watch local Google Drive folder and auto-process new interview files from Excel names.",
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
        "--drive-root",
        type=str,
        default=None,
        help="Local Google Drive sync folder to monitor.",
    )
    parser.add_argument(
        "--interval-seconds",
        type=int,
        default=90,
        help="Polling interval in seconds (default: 90).",
    )
    parser.add_argument(
        "--min-age-seconds",
        type=int,
        default=45,
        help="Only process files older than this many seconds (default: 45).",
    )
    parser.add_argument(
        "--max-per-cycle",
        type=int,
        default=5,
        help="Maximum files to process per scan cycle (default: 5).",
    )
    parser.add_argument(
        "--bootstrap-existing",
        action="store_true",
        help="Process existing files on first run. Default behavior starts tracking from now.",
    )
    parser.add_argument(
        "--include-done",
        action="store_true",
        help="Include rows marked Done in Excel matching.",
    )
    parser.add_argument(
        "--run-once",
        action="store_true",
        help="Run one scan cycle and exit.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show planned actions without running process_from_excel.py.",
    )
    parser.add_argument(
        "--state-file",
        type=Path,
        default=None,
        help="Optional state file path (default: interviews/_state/auto_process_state.json).",
    )
    return parser.parse_args()


def _now_utc_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _to_text(value: object) -> str:
    text = lib.normalize_whitespace(value)
    if text.lower() in {"nan", "none", "nat"}:
        return ""
    return text


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
    env_val = _to_text(os.environ.get("INTERVIEW_DRIVE_ROOT", ""))
    if env_val:
        candidates.append(Path(env_val))
    candidates.extend(_default_drive_root_candidates(interviews_root))

    seen = set()
    for candidate in candidates:
        key = str(candidate).lower()
        if key in seen:
            continue
        seen.add(key)
        if candidate.exists() and candidate.is_dir():
            return candidate
    return None


def _name_tokens(name: str) -> List[str]:
    raw_tokens = []
    word = []
    for ch in name.lower():
        if ch.isalnum():
            word.append(ch)
        else:
            if word:
                raw_tokens.append("".join(word))
                word = []
    if word:
        raw_tokens.append("".join(word))

    tokens = []
    for token in raw_tokens:
        if token in GENERIC_NAME_TOKENS:
            continue
        if len(token) < 2:
            continue
        tokens.append(token)
    return tokens


def _load_excel_entries(excel_path: Path, sheet: Optional[str], include_done: bool) -> Tuple[str, List[Dict[str, object]]]:
    try:
        import pandas as pd  # type: ignore
    except Exception as exc:
        raise RuntimeError("pandas/openpyxl required for auto mode.") from exc

    if sheet:
        df = pd.read_excel(excel_path, sheet_name=sheet, engine="openpyxl")
        sheet_name = sheet
    else:
        xls = pd.ExcelFile(excel_path, engine="openpyxl")
        sheet_name = xls.sheet_names[0]
        df = pd.read_excel(excel_path, sheet_name=sheet_name, engine="openpyxl")

    entries: List[Dict[str, object]] = []
    for idx, row in df.iterrows():
        name = _to_text(row.get("Name", ""))
        if not name:
            continue
        if (not include_done) and _is_done(row.get("Done", "")):
            continue

        tokens = _name_tokens(name)
        if len(tokens) == 0:
            continue
        if len(tokens) == 1 and len(tokens[0]) < 5:
            # Avoid weak matches like "Tom" or generic labels.
            continue

        chapter = _to_text(row.get("Chapter", ""))
        entries.append(
            {
                "row_index": int(idx),
                "name": name,
                "tokens": tokens,
                "full_norm": " ".join(tokens),
                "chapter": chapter,
            }
        )

    return sheet_name, entries


def _load_state(path: Path) -> Dict[str, object]:
    if not path.exists():
        return {"initialized": False, "last_scan_epoch": 0.0, "processed": {}}
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {"initialized": False, "last_scan_epoch": 0.0, "processed": {}}
    if not isinstance(state, dict):
        return {"initialized": False, "last_scan_epoch": 0.0, "processed": {}}
    state.setdefault("initialized", False)
    state.setdefault("last_scan_epoch", 0.0)
    state.setdefault("processed", {})
    if not isinstance(state["processed"], dict):
        state["processed"] = {}
    return state


def _save_state(path: Path, state: Dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def _candidate_ext_bonus(path: Path) -> int:
    ext = path.suffix.lower()
    if ext in {".txt", ".md"}:
        return 10
    if ext in {".docx", ".doc", ".rtf"}:
        return 9
    if ext in {".vtt", ".srt"}:
        return 8
    if ext in lib.AUDIO_EXTENSIONS:
        return 6
    return 1


def _match_score(path: Path, entry: Dict[str, object]) -> Tuple[int, int, bool]:
    blob = str(path).lower()
    tokens = [str(t) for t in entry.get("tokens", [])]
    full = str(entry.get("full_norm", ""))
    score = 0
    hits = 0
    full_match = False

    if full and full in blob:
        score += 50
        full_match = True

    for token in tokens:
        if token in blob:
            hits += 1
            score += 8

    if len(tokens) >= 2 and hits == len(tokens):
        score += 20
    if "interview" in blob or "transcript" in blob:
        score += 4
    score += _candidate_ext_bonus(path)
    return score, hits, full_match


def _choose_entry(path: Path, entries: List[Dict[str, object]]) -> Tuple[Optional[Dict[str, object]], int]:
    ranked: List[Tuple[int, Dict[str, object], int, bool]] = []
    for entry in entries:
        score, hits, full_match = _match_score(path, entry)
        token_count = len(entry.get("tokens", []))
        min_hits = 2 if token_count >= 2 else 1
        if not full_match and hits < min_hits:
            continue
        if score < 18:
            continue
        ranked.append((score, entry, hits, full_match))

    if not ranked:
        return None, 0

    ranked.sort(key=lambda item: (item[0], item[2], len(item[1].get("tokens", []))), reverse=True)
    best = ranked[0]
    if len(ranked) > 1:
        second = ranked[1]
        if second[0] >= best[0] - 2 and second[1].get("name") != best[1].get("name"):
            return None, 0
    return best[1], best[0]


def _iter_candidate_files(drive_root: Path) -> List[Path]:
    out: List[Path] = []
    for path in drive_root.rglob("*"):
        if not path.is_file():
            continue
        if path.name.startswith("~$"):
            continue
        if path.suffix.lower() not in ALLOWED_EXTENSIONS:
            continue
        out.append(path)
    return out


def _run(cmd: List[str], dry_run: bool) -> int:
    if dry_run:
        print("DRY-RUN:", " ".join(f'"{c}"' if " " in c else c for c in cmd))
        return 0
    return subprocess.run(cmd, check=False).returncode


def _process_one_file(
    process_script: Path,
    interviews_root: Path,
    excel_path: Path,
    sheet_name: str,
    row_index: int,
    source_file: Path,
    drive_root: Path,
    dry_run: bool,
) -> int:
    cmd = [
        sys.executable,
        str(process_script),
        "--interviews-root",
        str(interviews_root),
        "--excel",
        str(excel_path),
        "--sheet",
        sheet_name,
        "--row-index",
        str(row_index),
        "--drive-root",
        str(drive_root),
        "--source-file",
        str(source_file),
    ]
    return _run(cmd, dry_run)


def _cycle(
    args: argparse.Namespace,
    excel_path: Path,
    drive_root: Path,
    state_path: Path,
    state: Dict[str, object],
) -> Dict[str, object]:
    sheet_name, entries = _load_excel_entries(excel_path, args.sheet, args.include_done)
    if not entries:
        print("No usable interview names in Excel.")
        return {"processed": 0, "matched": 0, "seen": 0, "sheet": sheet_name}

    process_script = args.interviews_root / "scripts" / "process_from_excel.py"
    now = time.time()
    last_scan = float(state.get("last_scan_epoch", 0.0))
    processed_state = state.get("processed", {})
    if not isinstance(processed_state, dict):
        processed_state = {}
        state["processed"] = processed_state

    seen = 0
    matched = 0
    processed = 0

    files = _iter_candidate_files(drive_root)
    files.sort(key=lambda p: p.stat().st_mtime if p.exists() else 0.0, reverse=True)

    for path in files:
        try:
            stat = path.stat()
        except OSError:
            continue
        seen += 1

        if stat.st_mtime <= last_scan:
            continue
        if now - stat.st_mtime < max(args.min_age_seconds, 1):
            continue

        key = str(path).lower()
        prior = processed_state.get(key)
        if isinstance(prior, dict):
            if float(prior.get("mtime", -1)) == float(stat.st_mtime) and int(prior.get("size", -1)) == int(stat.st_size):
                continue

        entry, score = _choose_entry(path, entries)
        if entry is None:
            continue
        matched += 1

        name = str(entry.get("name", ""))
        row_index = int(entry.get("row_index", -1))
        print(f"Matched: {path.name} -> {name} (score={score})")

        rc = _process_one_file(
            process_script=process_script,
            interviews_root=args.interviews_root,
            excel_path=excel_path,
            sheet_name=sheet_name,
            row_index=row_index,
            source_file=path,
            drive_root=drive_root,
            dry_run=args.dry_run,
        )

        processed_state[key] = {
            "mtime": stat.st_mtime,
            "size": stat.st_size,
            "name": name,
            "row_index": row_index,
            "processed_at_utc": _now_utc_iso(),
            "status": "ok" if rc == 0 else f"error:{rc}",
        }
        processed += 1 if rc == 0 else 0

        if processed >= max(args.max_per_cycle, 1):
            break

    state["last_scan_epoch"] = now
    _save_state(state_path, state)
    return {"processed": processed, "matched": matched, "seen": seen, "sheet": sheet_name}


def main() -> int:
    args = parse_args()
    interviews_root = args.interviews_root.resolve()
    interviews_root.mkdir(parents=True, exist_ok=True)
    (interviews_root / "interview_raw").mkdir(parents=True, exist_ok=True)
    (interviews_root / "interview_notes").mkdir(parents=True, exist_ok=True)

    excel_path = lib.detect_global_excel(interviews_root, args.excel)
    if excel_path is None or not excel_path.exists():
        raise SystemExit("No Excel tracker found. Pass --excel or place Interview list.xlsx in a detected location.")

    drive_root = _detect_drive_root(args.drive_root, interviews_root)
    if drive_root is None:
        raise SystemExit("No local Google Drive folder found. Pass --drive-root.")

    state_path = args.state_file or (interviews_root / "_state" / "auto_process_state.json")
    state = _load_state(state_path)

    if not bool(state.get("initialized", False)):
        state["initialized"] = True
        if args.bootstrap_existing:
            state["last_scan_epoch"] = 0.0
            print("Auto mode initialized with bootstrap: existing files will be scanned.")
        else:
            state["last_scan_epoch"] = time.time()
            _save_state(state_path, state)
            print("Auto mode initialized. Starting from current time; only new files will be processed.")
            if args.run_once:
                return 0

    print(f"Watching drive root: {drive_root}")
    print(f"Excel source: {excel_path}")
    print(f"State file: {state_path}")

    while True:
        state = _load_state(state_path)
        try:
            result = _cycle(
                args=args,
                excel_path=excel_path,
                drive_root=drive_root,
                state_path=state_path,
                state=state,
            )
            print(
                f"Cycle done: seen={result['seen']}, matched={result['matched']}, processed={result['processed']} "
                f"(sheet={result['sheet']})"
            )
        except Exception as exc:
            print(f"Cycle error: {exc}")

        if args.run_once:
            return 0
        time.sleep(max(args.interval_seconds, 5))


if __name__ == "__main__":
    raise SystemExit(main())
