#!/usr/bin/env python3
"""Create a new interview folder scaffold and update the master index."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict

import _interview_lib as lib


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a new interview folder scaffold with metadata and templates.",
    )
    parser.add_argument(
        "--interviews-root",
        type=Path,
        default=lib.default_interviews_root(__file__),
        help="Path to interviews root (default: parent of scripts directory).",
    )
    parser.add_argument(
        "--date",
        type=str,
        default=lib.utc_today(),
        help="Interview date in UTC format YYYY-MM-DD (default: today UTC).",
    )
    parser.add_argument("--guest-name", required=True, help="Guest full name.")
    parser.add_argument("--topic", required=True, help="Main interview topic.")
    parser.add_argument("--guest-role", default=None, help="Guest role/title.")
    parser.add_argument("--org", default=None, help="Guest organization.")
    parser.add_argument("--platform", default=None, help="Interview platform (Zoom/Meet/Teams/etc).")
    parser.add_argument("--recording-link", default=None, help="Recording link if available.")
    parser.add_argument(
        "--status",
        default="planned",
        choices=lib.STATUS_ORDER,
        help="Initial status (default: planned).",
    )
    parser.add_argument(
        "--tags",
        nargs="*",
        default=None,
        help="Optional tags list (space separated).",
    )
    parser.add_argument(
        "--chapter-candidates",
        nargs="*",
        default=None,
        help="Optional chapter candidate list (space separated).",
    )
    parser.add_argument(
        "--confidentiality",
        default="mixed",
        choices=["on_record", "off_record", "mixed"],
        help="Confidentiality setting (default: mixed).",
    )
    parser.add_argument(
        "--excel",
        type=str,
        default=None,
        help="Optional Excel tracker path override.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite generated packet/output files if they already exist.",
    )
    parser.add_argument(
        "--no-index-update",
        action="store_true",
        help="Skip update_index.py call at the end.",
    )
    return parser.parse_args()


def _validate_date(date_str: str) -> None:
    if not re.match(r"^\d{4}-\d{2}-\d{2}$", date_str):
        raise ValueError(f"Invalid --date '{date_str}'. Expected YYYY-MM-DD.")


def _render(template: str, context: Dict[str, str]) -> str:
    rendered = template
    for key, value in context.items():
        rendered = rendered.replace(f"{{{{{key}}}}}", value)
    return rendered


def _read_template(template_path: Path, fallback: str) -> str:
    if template_path.exists():
        return template_path.read_text(encoding="utf-8")
    return fallback


def _write_if_needed(path: Path, content: str, force: bool) -> bool:
    if path.exists() and not force:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def _update_links_md(path: Path, metadata: Dict[str, object], force: bool) -> bool:
    if path.exists() and not force:
        return False

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
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8")
    return True


def _populate_templates(interviews_root: Path, interview_dir: Path, metadata: Dict[str, object], force: bool) -> int:
    template_dir = interviews_root / "templates"
    context = {
        "INTERVIEW_ID": lib.normalize_whitespace(metadata.get("interview_id", "")),
        "DATE": lib.normalize_whitespace(metadata.get("date", "")),
        "GUEST_NAME": lib.normalize_whitespace(metadata.get("guest_name", "")),
        "GUEST_ROLE": lib.normalize_whitespace(metadata.get("guest_role", "")),
        "ORG": lib.normalize_whitespace(metadata.get("org", "")),
        "TOPIC": lib.normalize_whitespace(metadata.get("topic", "")),
        "PLATFORM": lib.normalize_whitespace(metadata.get("platform", "")),
        "CONFIDENTIALITY": lib.normalize_whitespace(metadata.get("confidentiality", "")),
        "RECORDING_LINK": lib.normalize_whitespace(metadata.get("recording_link", "")),
    }

    targets = [
        (
            template_dir / "interview_packet.md",
            interview_dir / "interview_packet.md",
            "# Interview Packet\n\nFill this packet before the interview.\n",
        ),
        (
            template_dir / "notes_pass1_index.md",
            interview_dir / "outputs" / "notes_pass1_index.md",
            "# Pass 1 Notes\n",
        ),
        (
            template_dir / "notes_pass2_booknotes.md",
            interview_dir / "outputs" / "notes_pass2_booknotes.md",
            "# Pass 2 Notes\n",
        ),
        (
            template_dir / "notes_pass3_quotes.md",
            interview_dir / "outputs" / "notes_pass3_quotes.md",
            "# Pass 3 Quotes\n",
        ),
        (
            template_dir / "fact_check.md",
            interview_dir / "outputs" / "fact_checks.md",
            "# Fact Checks\n",
        ),
    ]

    created = 0
    for src, dst, fallback in targets:
        content = _render(_read_template(src, fallback), context)
        if _write_if_needed(dst, content, force=force):
            created += 1
    return created


def _apply_explicit_args(metadata: Dict[str, object], args: argparse.Namespace) -> bool:
    changed = False
    changed = lib.set_if_different(metadata, "date", args.date) or changed
    changed = lib.set_if_different(metadata, "guest_name", args.guest_name) or changed
    changed = lib.set_if_different(metadata, "topic", args.topic) or changed
    changed = lib.set_if_different(metadata, "status", args.status) or changed
    changed = lib.set_if_different(metadata, "confidentiality", args.confidentiality) or changed

    if args.guest_role is not None:
        changed = lib.set_if_different(metadata, "guest_role", args.guest_role) or changed
    if args.org is not None:
        changed = lib.set_if_different(metadata, "org", args.org) or changed
    if args.platform is not None:
        changed = lib.set_if_different(metadata, "platform", args.platform) or changed
    if args.recording_link is not None:
        changed = lib.set_if_different(metadata, "recording_link", args.recording_link) or changed
    if args.tags is not None:
        changed = lib.set_if_different(metadata, "tags", args.tags) or changed
    if args.chapter_candidates is not None:
        changed = lib.set_if_different(metadata, "chapter_candidates", args.chapter_candidates) or changed

    return changed


def main() -> int:
    args = parse_args()
    _validate_date(args.date)

    interviews_root = args.interviews_root.resolve()
    interviews_root.mkdir(parents=True, exist_ok=True)

    topic_slug = lib.slugify_topic(args.topic, max_len=40)
    guest_token = lib.guest_folder_token(args.guest_name)
    folder_name = f"{args.date}__{guest_token}__{topic_slug}"
    interview_dir = interviews_root / folder_name

    subdirs = [
        interview_dir / "_meta",
        interview_dir / "audio",
        interview_dir / "transcript" / "raw",
        interview_dir / "transcript" / "raw" / "exports",
        interview_dir / "transcript" / "cleaned",
        interview_dir / "transcript" / "chunks",
        interview_dir / "outputs",
        interview_dir / "consent",
        interview_dir / "attachments",
    ]
    for path in subdirs:
        path.mkdir(parents=True, exist_ok=True)

    metadata_path = interview_dir / "_meta" / "metadata.yml"
    metadata = lib.load_metadata(metadata_path) if metadata_path.exists() else {}
    defaults = lib.metadata_defaults(
        date_str=args.date,
        guest_name=args.guest_name,
        topic=args.topic,
        drive_folder=folder_name,
        interview_id=lib.interview_id_from_parts(args.date, args.guest_name, topic_slug),
    )
    changed = not metadata_path.exists()
    changed = lib.merge_missing(metadata, defaults) or changed
    changed = _apply_explicit_args(metadata, args) or changed
    changed = lib.set_if_different(metadata, "drive_folder", folder_name) or changed

    if not lib.normalize_whitespace(metadata.get("interview_id", "")):
        changed = (
            lib.set_if_different(
                metadata,
                "interview_id",
                lib.interview_id_from_parts(args.date, args.guest_name, topic_slug),
            )
            or changed
        )

    global_excel = lib.detect_global_excel(interviews_root, args.excel)
    if global_excel:
        changed = lib.set_if_different(
            metadata,
            "excel_link",
            lib.relative_posix(global_excel, interviews_root),
        ) or changed
        prefill, message = lib.prefill_from_excel(global_excel, metadata)
        changed = lib.merge_missing(metadata, prefill) or changed
        if message:
            print(f"Excel: {message}")

    # Normalize lists and controlled fields.
    metadata["source_files"] = lib.ensure_list(metadata.get("source_files", []))
    metadata["tags"] = lib.ensure_list(metadata.get("tags", []))
    metadata["chapter_candidates"] = lib.ensure_list(metadata.get("chapter_candidates", []))
    metadata["status"] = lib.normalize_status(metadata.get("status", "")) or "planned"
    metadata["confidentiality"] = lib.normalize_confidentiality(metadata.get("confidentiality", "")) or "mixed"

    if changed:
        lib.write_metadata(metadata_path, metadata)

    links_path = interview_dir / "_meta" / "links.md"
    links_written = _update_links_md(links_path, metadata, force=args.force)
    created_templates = _populate_templates(interviews_root, interview_dir, metadata, force=args.force)

    print(f"Interview folder: {interview_dir}")
    print(f"Metadata: {'updated' if changed else 'unchanged'} -> {metadata_path}")
    print(f"Links: {'written' if links_written else 'kept'} -> {links_path}")
    print(f"Template files written: {created_templates}")

    if not args.no_index_update:
        update_script = interviews_root / "scripts" / "update_index.py"
        cmd = [sys.executable, str(update_script), "--interviews-root", str(interviews_root)]
        if args.excel:
            cmd.extend(["--excel", args.excel])
        subprocess.run(cmd, check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

