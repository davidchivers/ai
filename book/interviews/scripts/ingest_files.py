#!/usr/bin/env python3
"""Ingest files into an interview folder and sync metadata."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

import _interview_lib as lib


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copy/move source files into interview subfolders and update metadata.",
    )
    parser.add_argument(
        "--interviews-root",
        type=Path,
        default=lib.default_interviews_root(__file__),
        help="Path to interviews root (default: parent of scripts directory).",
    )
    parser.add_argument(
        "--interview",
        required=True,
        help="Interview folder path or folder name (YYYY-MM-DD__GuestName__topic-slug).",
    )
    parser.add_argument(
        "--file",
        dest="files",
        action="append",
        required=True,
        help="File to ingest. Repeat flag for multiple files.",
    )
    parser.add_argument(
        "--kind",
        choices=["auto", "audio", "transcript", "export", "excel", "attachment"],
        default="auto",
        help="Force file type or auto-detect from extension.",
    )
    parser.add_argument(
        "--mode",
        choices=["copy", "move"],
        default="copy",
        help="Ingest mode (default: copy).",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite destination file if it already exists.",
    )
    parser.add_argument(
        "--excel",
        type=str,
        default=None,
        help="Optional Excel tracker path override.",
    )
    parser.add_argument(
        "--no-index-update",
        action="store_true",
        help="Skip update_index.py call at the end.",
    )
    return parser.parse_args()


def _flatten_files(files: List[str]) -> List[str]:
    flattened: List[str] = []
    for item in files:
        if isinstance(item, str):
            flattened.append(item)
    return flattened


def _resolve_interview_dir(interviews_root: Path, interview_value: str) -> Path:
    direct = Path(interview_value).expanduser()
    if direct.exists() and direct.is_dir():
        return direct.resolve()

    candidate = interviews_root / interview_value
    if candidate.exists() and candidate.is_dir():
        return candidate.resolve()

    matches = [p for p in lib.discover_interview_dirs(interviews_root) if interview_value.lower() in p.name.lower()]
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        names = ", ".join(match.name for match in matches)
        raise ValueError(f"Ambiguous interview value '{interview_value}'. Matches: {names}")
    raise ValueError(f"Interview folder not found for '{interview_value}'.")


def _infer_kind(file_path: Path) -> str:
    ext = file_path.suffix.lower()
    if ext in lib.AUDIO_EXTENSIONS:
        return "audio"
    if ext in lib.EXPORT_EXTENSIONS:
        return "export"
    if ext in lib.TRANSCRIPT_EXTENSIONS:
        return "transcript"
    if ext in lib.EXCEL_EXTENSIONS:
        return "excel"
    return "attachment"


def _target_subdir(kind: str) -> Path:
    if kind == "audio":
        return Path("audio")
    if kind == "transcript":
        return Path("transcript") / "raw"
    if kind == "export":
        return Path("transcript") / "raw" / "exports"
    if kind == "excel":
        return Path("attachments")
    return Path("attachments")


def _ingest_one(source: Path, destination: Path, mode: str, overwrite: bool) -> str:
    if source.resolve() == destination.resolve():
        return "already_in_place"

    if destination.exists():
        if not overwrite:
            return "exists_skip"
        destination.unlink()

    destination.parent.mkdir(parents=True, exist_ok=True)
    if mode == "copy":
        shutil.copy2(source, destination)
    else:
        shutil.move(str(source), str(destination))
    return "ingested"


def _ensure_metadata(interview_dir: Path) -> Dict[str, object]:
    metadata_path = interview_dir / "_meta" / "metadata.yml"
    metadata = lib.load_metadata(metadata_path) if metadata_path.exists() else {}
    basics = lib.parse_folder_basics(interview_dir.name)
    defaults = lib.metadata_defaults(
        date_str=basics.get("date", ""),
        guest_name=basics.get("guest_name", ""),
        topic=basics.get("topic", ""),
        drive_folder=interview_dir.name,
        interview_id=basics.get("interview_id", "") or None,
    )
    lib.merge_missing(metadata, defaults)
    metadata["source_files"] = lib.ensure_list(metadata.get("source_files", []))
    metadata["tags"] = lib.ensure_list(metadata.get("tags", []))
    metadata["chapter_candidates"] = lib.ensure_list(metadata.get("chapter_candidates", []))
    metadata["status"] = lib.normalize_status(metadata.get("status", "")) or "planned"
    metadata["confidentiality"] = lib.normalize_confidentiality(metadata.get("confidentiality", "")) or "mixed"
    return metadata


def _update_links_md(interview_dir: Path, metadata: Dict[str, object]) -> None:
    links_path = interview_dir / "_meta" / "links.md"
    source_files = lib.ensure_list(metadata.get("source_files", []))
    source_lines = "\n".join(f"- `{item}`" for item in source_files) if source_files else "- (none yet)"
    body = "\n".join(
        [
            "# Links",
            "",
            "- Metadata: `metadata.yml`",
            f"- Excel tracker: `{lib.normalize_whitespace(metadata.get('excel_link', '')) or '(not linked)'}`",
            f"- Recording link: {lib.normalize_whitespace(metadata.get('recording_link', '')) or '(none)'}",
            "",
            "## Source Files",
            source_lines,
            "",
        ]
    )
    links_path.parent.mkdir(parents=True, exist_ok=True)
    links_path.write_text(body, encoding="utf-8")


def main() -> int:
    args = parse_args()

    interviews_root = args.interviews_root.resolve()
    interviews_root.mkdir(parents=True, exist_ok=True)
    interview_dir = _resolve_interview_dir(interviews_root, args.interview)
    metadata_path = interview_dir / "_meta" / "metadata.yml"
    metadata = _ensure_metadata(interview_dir)
    changed = not metadata_path.exists()

    input_files = _flatten_files(args.files)
    if not input_files:
        raise ValueError("No --file values supplied.")

    global_excel = lib.detect_global_excel(interviews_root, args.excel)
    ingested_count = 0

    for raw_file in input_files:
        source = Path(raw_file).expanduser()
        if not source.exists() or not source.is_file():
            print(f"Missing file, skipped: {source}")
            continue

        kind = args.kind if args.kind != "auto" else _infer_kind(source)
        target_dir = interview_dir / _target_subdir(kind)
        destination = target_dir / source.name
        outcome = _ingest_one(source=source, destination=destination, mode=args.mode, overwrite=args.overwrite)

        if outcome == "exists_skip":
            print(f"Exists, skipped (use --overwrite): {destination}")
        elif outcome == "already_in_place":
            print(f"Already in place: {destination}")
        else:
            ingested_count += 1
            print(f"Ingested ({kind}): {destination}")

        rel_path = lib.relative_posix(destination, interview_dir)
        source_files = lib.ensure_list(metadata.get("source_files", []))
        if rel_path not in source_files:
            source_files.append(rel_path)
            metadata["source_files"] = source_files
            changed = True

        if kind == "audio":
            next_status = lib.advance_status(metadata.get("status", ""), "recorded")
            changed = lib.set_if_different(metadata, "status", next_status) or changed
        elif kind in {"transcript", "export"}:
            next_status = lib.advance_status(metadata.get("status", ""), "transcribed")
            changed = lib.set_if_different(metadata, "status", next_status) or changed
        elif kind == "excel":
            excel_link = lib.relative_posix(destination, interviews_root)
            changed = lib.set_if_different(metadata, "excel_link", excel_link) or changed
            prefill, message = lib.prefill_from_excel(destination, metadata)
            changed = lib.merge_missing(metadata, prefill) or changed
            print(f"Excel: {message}")

    if not lib.normalize_whitespace(metadata.get("excel_link", "")) and global_excel:
        changed = lib.set_if_different(
            metadata,
            "excel_link",
            lib.relative_posix(global_excel, interviews_root),
        ) or changed
        prefill, message = lib.prefill_from_excel(global_excel, metadata)
        changed = lib.merge_missing(metadata, prefill) or changed
        print(f"Excel: {message}")

    metadata["source_files"] = lib.ensure_list(metadata.get("source_files", []))
    metadata["tags"] = lib.ensure_list(metadata.get("tags", []))
    metadata["chapter_candidates"] = lib.ensure_list(metadata.get("chapter_candidates", []))
    metadata["status"] = lib.normalize_status(metadata.get("status", "")) or "planned"
    metadata["confidentiality"] = lib.normalize_confidentiality(metadata.get("confidentiality", "")) or "mixed"

    if changed:
        lib.write_metadata(metadata_path, metadata)
    _update_links_md(interview_dir, metadata)

    print(f"Interview: {interview_dir}")
    print(f"Files ingested this run: {ingested_count}")
    print(f"Metadata: {'updated' if changed else 'unchanged'} -> {metadata_path}")

    if not args.no_index_update:
        update_script = interviews_root / "scripts" / "update_index.py"
        cmd = [sys.executable, str(update_script), "--interviews-root", str(interviews_root)]
        if args.excel:
            cmd.extend(["--excel", args.excel])
        subprocess.run(cmd, check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

