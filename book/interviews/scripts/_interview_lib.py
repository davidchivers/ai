#!/usr/bin/env python3
"""Shared helpers for the interviews workflow scripts."""

from __future__ import annotations

import os
import re
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

METADATA_FIELD_ORDER = [
    "interview_id",
    "date",
    "guest_name",
    "guest_role",
    "org",
    "topic",
    "platform",
    "recording_link",
    "drive_folder",
    "source_files",
    "excel_link",
    "status",
    "tags",
    "chapter_candidates",
    "confidentiality",
]

LIST_FIELDS = {"source_files", "tags", "chapter_candidates"}
STATUS_ORDER = [
    "planned",
    "recorded",
    "transcribed",
    "notes_done",
    "quoted",
    "fact_checked",
]

AUDIO_EXTENSIONS = {".mp3", ".m4a", ".wav", ".aac", ".flac", ".ogg", ".wma"}
TRANSCRIPT_EXTENSIONS = {".txt", ".doc", ".docx", ".md", ".rtf", ".pdf"}
EXPORT_EXTENSIONS = {".vtt", ".srt"}
EXCEL_EXTENSIONS = {".xlsx", ".xlsm", ".xls"}

_FOLDER_REGEX = re.compile(r"^\d{4}-\d{2}-\d{2}__[^_]+__.+$")
_DATE_REGEX = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def utc_today() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def normalize_whitespace(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip()


def split_list_text(value: object) -> List[str]:
    text = normalize_whitespace(value)
    if not text:
        return []
    parts = re.split(r"[;,|]", text)
    cleaned: List[str] = []
    for part in parts:
        item = normalize_whitespace(part)
        if item:
            cleaned.append(item)
    return dedupe_preserve_order(cleaned)


def dedupe_preserve_order(items: Iterable[str]) -> List[str]:
    out: List[str] = []
    seen = set()
    for item in items:
        key = normalize_whitespace(item)
        if not key:
            continue
        key_lower = key.lower()
        if key_lower in seen:
            continue
        seen.add(key_lower)
        out.append(key)
    return out


def slugify_topic(topic: str, max_len: int = 40) -> str:
    text = normalize_whitespace(topic).lower()
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    text = text[:max_len].strip("-")
    return text or "general-topic"


def guest_folder_token(guest_name: str, max_len: int = 50) -> str:
    parts = re.findall(r"[A-Za-z0-9]+", normalize_whitespace(guest_name))
    if not parts:
        return "Guest"
    token = "".join(part[:1].upper() + part[1:] for part in parts)
    return token[:max_len] or "Guest"


def guest_slug(guest_name: str, max_len: int = 40) -> str:
    parts = re.findall(r"[A-Za-z0-9]+", normalize_whitespace(guest_name).lower())
    if not parts:
        return "guest"
    slug = "-".join(parts)
    return slug[:max_len].strip("-") or "guest"


def interview_id_from_parts(date_str: str, guest_name: str, topic_slug: str) -> str:
    safe_date = date_str if _DATE_REGEX.match(date_str or "") else utc_today()
    return f"{safe_date}__{guest_slug(guest_name, 30)}__{topic_slug}"


def default_interviews_root(current_file: str) -> Path:
    return Path(current_file).resolve().parents[1]


def _unquote_scalar(value: str) -> str:
    raw = value.strip()
    if not raw:
        return ""
    if raw in {"null", "~"}:
        return ""
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in {"'", '"'}:
        inner = raw[1:-1]
        if raw[0] == '"':
            inner = inner.replace('\\"', '"').replace("\\\\", "\\")
        return normalize_whitespace(inner)
    return normalize_whitespace(raw)


def _parse_inline_list(value: str) -> List[str]:
    raw = value.strip()
    if not raw or raw == "[]":
        return []
    if raw.startswith("[") and raw.endswith("]"):
        inner = raw[1:-1].strip()
        if not inner:
            return []
        parts = [item.strip() for item in inner.split(",")]
        return dedupe_preserve_order([_unquote_scalar(item) for item in parts if item.strip()])
    return split_list_text(_unquote_scalar(raw))


def ensure_list(value: object) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return dedupe_preserve_order([normalize_whitespace(v) for v in value if normalize_whitespace(v)])
    return split_list_text(value)


def load_metadata(path: Path) -> Dict[str, object]:
    data: Dict[str, object] = {}
    if not path.exists():
        return data

    current_list_key: Optional[str] = None
    lines = path.read_text(encoding="utf-8").splitlines()
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if line.startswith("  - ") and current_list_key in LIST_FIELDS:
            item = _unquote_scalar(line[4:])
            if item:
                data.setdefault(current_list_key, [])
                data[current_list_key].append(item)
            continue
        if line.startswith(" ") or ":" not in line:
            continue

        key, raw_val = line.split(":", 1)
        key = key.strip()
        val = raw_val.strip()
        if key in LIST_FIELDS:
            if not val:
                data[key] = []
                current_list_key = key
            else:
                data[key] = _parse_inline_list(val)
                current_list_key = None
        else:
            data[key] = _unquote_scalar(val)
            current_list_key = None

    for key in LIST_FIELDS:
        data[key] = ensure_list(data.get(key, []))
    return data


def _yaml_quote(value: object) -> str:
    text = normalize_whitespace(value)
    if text == "":
        return '""'
    # Keep simple values unquoted for readability; quote everything else.
    if re.fullmatch(r"[A-Za-z0-9._/\-]+", text) and text.lower() not in {
        "yes",
        "no",
        "true",
        "false",
        "null",
    }:
        return text
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def write_metadata(path: Path, metadata: Dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    merged = dict(metadata)
    for key in LIST_FIELDS:
        merged[key] = ensure_list(merged.get(key, []))
    for key in METADATA_FIELD_ORDER:
        if key in LIST_FIELDS:
            merged.setdefault(key, [])
        else:
            merged.setdefault(key, "")

    lines: List[str] = []
    for key in METADATA_FIELD_ORDER:
        value = merged.get(key)
        if key in LIST_FIELDS:
            items = ensure_list(value)
            if not items:
                lines.append(f"{key}: []")
            else:
                lines.append(f"{key}:")
                for item in items:
                    lines.append(f"  - {_yaml_quote(item)}")
        else:
            lines.append(f"{key}: {_yaml_quote(value)}")

    extras = sorted(k for k in merged.keys() if k not in METADATA_FIELD_ORDER)
    for key in extras:
        value = merged[key]
        if key in LIST_FIELDS:
            items = ensure_list(value)
            if not items:
                lines.append(f"{key}: []")
            else:
                lines.append(f"{key}:")
                for item in items:
                    lines.append(f"  - {_yaml_quote(item)}")
        else:
            lines.append(f"{key}: {_yaml_quote(value)}")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def normalize_status(value: object) -> str:
    text = normalize_whitespace(value).lower().replace("-", "_").replace(" ", "_")
    aliases = {
        "notes": "notes_done",
        "notesdone": "notes_done",
        "note_done": "notes_done",
        "quoted_done": "quoted",
        "factchecked": "fact_checked",
        "fact_check": "fact_checked",
    }
    text = aliases.get(text, text)
    return text if text in STATUS_ORDER else ""


def normalize_confidentiality(value: object) -> str:
    text = normalize_whitespace(value).lower().replace("-", "_").replace(" ", "_")
    aliases = {
        "onrecord": "on_record",
        "offrecord": "off_record",
        "mixed_record": "mixed",
    }
    text = aliases.get(text, text)
    if text in {"on_record", "off_record", "mixed"}:
        return text
    return ""


def metadata_defaults(
    date_str: str,
    guest_name: str,
    topic: str,
    drive_folder: str,
    interview_id: Optional[str] = None,
) -> Dict[str, object]:
    topic_slug = slugify_topic(topic)
    return {
        "interview_id": interview_id or interview_id_from_parts(date_str, guest_name, topic_slug),
        "date": date_str,
        "guest_name": normalize_whitespace(guest_name),
        "guest_role": "",
        "org": "",
        "topic": normalize_whitespace(topic),
        "platform": "",
        "recording_link": "",
        "drive_folder": normalize_whitespace(drive_folder),
        "source_files": [],
        "excel_link": "",
        "status": "planned",
        "tags": [],
        "chapter_candidates": [],
        "confidentiality": "mixed",
    }


def merge_missing(metadata: Dict[str, object], prefill: Dict[str, object]) -> bool:
    changed = False
    for key, incoming in prefill.items():
        if key in LIST_FIELDS:
            current = ensure_list(metadata.get(key, []))
            if not current:
                new_value = ensure_list(incoming)
                if new_value:
                    metadata[key] = new_value
                    changed = True
            continue
        current_text = normalize_whitespace(metadata.get(key, ""))
        incoming_text = normalize_whitespace(incoming)
        if not current_text and incoming_text:
            metadata[key] = incoming_text
            changed = True
    return changed


def set_if_different(metadata: Dict[str, object], key: str, value: object) -> bool:
    old = metadata.get(key)
    if key in LIST_FIELDS:
        old_list = ensure_list(old)
        new_list = ensure_list(value)
        if old_list != new_list:
            metadata[key] = new_list
            return True
        return False
    old_text = normalize_whitespace(old)
    new_text = normalize_whitespace(value)
    if old_text != new_text:
        metadata[key] = new_text
        return True
    return False


def advance_status(current: object, target: str) -> str:
    cur = normalize_status(current)
    tgt = normalize_status(target)
    if not tgt:
        return cur or "planned"
    if not cur:
        return tgt
    if STATUS_ORDER.index(tgt) > STATUS_ORDER.index(cur):
        return tgt
    return cur


def relative_posix(path: Optional[Path], base: Path) -> str:
    if path is None:
        return ""
    try:
        rel = os.path.relpath(str(path), str(base))
        return Path(rel).as_posix()
    except Exception:
        return str(path)


def parse_folder_basics(folder_name: str) -> Dict[str, str]:
    parts = folder_name.split("__", 2)
    if len(parts) != 3:
        return {
            "date": "",
            "guest_name": "",
            "topic": "",
            "topic_slug": "",
            "interview_id": "",
        }
    date_part, guest_part, topic_slug = parts
    date_clean = date_part if _DATE_REGEX.match(date_part) else ""
    guest_name = re.sub(r"([a-z])([A-Z])", r"\1 \2", guest_part).replace("_", " ").strip()
    topic = topic_slug.replace("-", " ").strip()
    return {
        "date": date_clean,
        "guest_name": guest_name,
        "topic": topic,
        "topic_slug": topic_slug.strip(),
        "interview_id": interview_id_from_parts(
            date_clean or utc_today(),
            guest_name or "Guest",
            topic_slug.strip() or "general-topic",
        ),
    }


def discover_interview_dirs(interviews_root: Path) -> List[Path]:
    skip_names = {"templates", "skills", "agents", "scripts", "examples"}
    found: List[Path] = []
    if not interviews_root.exists():
        return found
    for child in sorted(interviews_root.iterdir(), key=lambda p: p.name.lower()):
        if not child.is_dir():
            continue
        if child.name in skip_names:
            continue
        if (child / "_meta" / "metadata.yml").exists() or _FOLDER_REGEX.match(child.name):
            found.append(child)
    return found


def detect_global_excel(interviews_root: Path, explicit: Optional[str] = None) -> Optional[Path]:
    candidates: List[Path] = []
    explicit_path: Optional[Path] = None

    if explicit:
        p = Path(explicit).expanduser()
        if not p.is_absolute():
            p = (Path.cwd() / p).resolve()
        explicit_path = p
        candidates.append(p)

    candidates.extend(
        [
            interviews_root / "interview_tracker.xlsx",
            interviews_root / "Interview list.xlsx",
            interviews_root.parent / "interview_tracker.xlsx",
            interviews_root.parent / "Interview list.xlsx",
        ]
    )

    for scan_dir in [interviews_root, interviews_root.parent]:
        if not scan_dir.exists():
            continue
        for workbook in sorted(scan_dir.glob("*.xlsx"), key=lambda p: p.name.lower()):
            if workbook.name.startswith("~$"):
                continue
            if "interview" in workbook.stem.lower():
                candidates.append(workbook)

    seen = set()
    ordered: List[Path] = []
    for candidate in candidates:
        key = str(candidate).lower()
        if key in seen:
            continue
        seen.add(key)
        ordered.append(candidate)

    for candidate in ordered:
        if candidate.exists():
            return candidate
    if explicit_path is not None:
        return explicit_path
    return None


def detect_per_interview_excel(interview_dir: Path) -> Optional[Path]:
    if not interview_dir.exists():
        return None
    workbooks: List[Path] = []
    for ext in ("*.xlsx", "*.xlsm", "*.xls"):
        for path in interview_dir.rglob(ext):
            if not path.is_file():
                continue
            if path.name.startswith("~$"):
                continue
            workbooks.append(path)
    if not workbooks:
        return None
    workbooks.sort(key=lambda p: str(p).lower())
    return workbooks[0]


def _cell_to_text(value: object) -> str:
    if value is None:
        return ""

    # datetime/date objects
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d")
    if isinstance(value, date):
        return value.strftime("%Y-%m-%d")

    text = str(value).strip()
    if not text or text.lower() in {"nan", "nat", "none"}:
        return ""

    # Timestamp-like string
    match = re.match(r"^(\d{4}-\d{2}-\d{2})", text)
    if match:
        return match.group(1)

    for fmt in ("%m/%d/%Y", "%d/%m/%Y", "%Y/%m/%d", "%d-%m-%Y", "%m-%d-%Y"):
        try:
            parsed = datetime.strptime(text, fmt)
            return parsed.strftime("%Y-%m-%d")
        except ValueError:
            pass

    return normalize_whitespace(text)


def _normalize_col_name(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.strip().lower()).strip("_")


def _pick_col(columns: Dict[str, str], aliases: List[str]) -> Optional[str]:
    for alias in aliases:
        if alias in columns:
            return columns[alias]
    return None


def prefill_from_excel(excel_path: Path, hints: Dict[str, object]) -> Tuple[Dict[str, object], str]:
    if excel_path is None:
        return {}, "No Excel path provided."
    if not excel_path.exists():
        return {}, "Excel file not found; path linked only."

    try:
        import pandas as pd  # type: ignore
    except Exception:
        return {}, "pandas/openpyxl unavailable; path linked only."

    try:
        frame = pd.read_excel(excel_path, engine="openpyxl")
    except Exception as exc:
        return {}, f"Excel read failed ({exc}); path linked only."

    if frame.empty:
        return {}, "Excel readable but empty."

    col_lookup = {_normalize_col_name(str(col)): str(col) for col in frame.columns}

    aliases = {
        "date": ["date", "interview_date", "recorded_date"],
        "guest_name": ["guest_name", "guest", "interviewee", "name"],
        "guest_role": ["guest_role", "role", "title"],
        "org": ["org", "organization", "organisation", "company", "institution"],
        "topic": ["topic", "subject", "theme"],
        "platform": ["platform", "meeting_platform", "tool"],
        "recording_link": ["recording_link", "recording", "link", "url"],
        "status": ["status"],
        "tags": ["tags", "keywords"],
        "chapter_candidates": ["chapter_candidates", "chapters", "chapter"],
        "confidentiality": ["confidentiality", "on_record", "record_status"],
    }

    guest_col = _pick_col(col_lookup, aliases["guest_name"])
    topic_col = _pick_col(col_lookup, aliases["topic"])
    date_col = _pick_col(col_lookup, aliases["date"])

    hint_guest = normalize_whitespace(hints.get("guest_name", "")).lower()
    hint_topic = normalize_whitespace(hints.get("topic", "")).lower()
    hint_date = normalize_whitespace(hints.get("date", ""))

    best_score = -1
    best_idx = None
    for idx, row in frame.iterrows():
        score = 0
        if guest_col and hint_guest:
            candidate = normalize_whitespace(row.get(guest_col, "")).lower()
            if hint_guest and hint_guest in candidate:
                score += 4
        if topic_col and hint_topic:
            candidate = normalize_whitespace(row.get(topic_col, "")).lower()
            if hint_topic and hint_topic in candidate:
                score += 3
        if date_col and hint_date:
            candidate = _cell_to_text(row.get(date_col, ""))
            if candidate == hint_date:
                score += 4
            elif hint_date and hint_date in candidate:
                score += 2
        if score > best_score:
            best_score = score
            best_idx = idx

    if best_idx is None or best_score <= 0:
        if len(frame.index) == 1:
            best_idx = frame.index[0]
        else:
            return {}, "No matching Excel row for this interview."

    row = frame.loc[best_idx]
    prefill: Dict[str, object] = {}
    for key, key_aliases in aliases.items():
        col = _pick_col(col_lookup, key_aliases)
        if not col:
            continue
        value = _cell_to_text(row.get(col, ""))
        if not value:
            continue
        if key in {"tags", "chapter_candidates"}:
            prefill[key] = split_list_text(value)
        elif key == "status":
            normalized = normalize_status(value)
            if normalized:
                prefill[key] = normalized
        elif key == "confidentiality":
            normalized = normalize_confidentiality(value)
            if normalized:
                prefill[key] = normalized
        else:
            prefill[key] = value

    if not prefill:
        return {}, "Excel row found but no usable metadata fields."
    return prefill, "Metadata prefill from Excel succeeded."

