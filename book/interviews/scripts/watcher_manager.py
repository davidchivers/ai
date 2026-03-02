#!/usr/bin/env python3
"""Manage the background auto-process watcher for interview files."""

from __future__ import annotations

import argparse
import json
import os
import signal
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Optional

import _interview_lib as lib


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Start/stop/status for the interview auto-process watcher.",
    )
    parser.add_argument(
        "action",
        choices=["start", "stop", "status", "restart"],
        help="Watcher action.",
    )
    parser.add_argument(
        "--interviews-root",
        type=Path,
        default=lib.default_interviews_root(__file__),
        help="Path to interviews root (default: parent of scripts directory).",
    )
    parser.add_argument(
        "--drive-root",
        type=str,
        default=None,
        help="Optional input folder to watch (default: Google Drive Interviews/Raw if present).",
    )
    parser.add_argument(
        "--excel",
        type=str,
        default=None,
        help="Optional Excel path override.",
    )
    parser.add_argument(
        "--sheet",
        type=str,
        default=None,
        help="Optional Excel sheet name.",
    )
    parser.add_argument(
        "--interval-seconds",
        type=int,
        default=60,
        help="Polling interval seconds (default: 60).",
    )
    parser.add_argument(
        "--min-age-seconds",
        type=int,
        default=30,
        help="Only process files older than this many seconds (default: 30).",
    )
    parser.add_argument(
        "--max-per-cycle",
        type=int,
        default=5,
        help="Max files processed per cycle (default: 5).",
    )
    parser.add_argument(
        "--bootstrap-existing",
        action="store_true",
        help="On start, allow initial scan of existing files.",
    )
    parser.add_argument(
        "--include-done",
        action="store_true",
        help="Include Done rows from Excel.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Start watcher in dry-run mode.",
    )
    return parser.parse_args()


def _runtime_dir(interviews_root: Path) -> Path:
    path = interviews_root / "_runtime"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _pid_file(interviews_root: Path) -> Path:
    return _runtime_dir(interviews_root) / "auto_process_watcher.json"


def _log_file(interviews_root: Path) -> Path:
    return _runtime_dir(interviews_root) / "auto_process_watcher.log"


def _now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _load_pid(path: Path) -> Dict[str, object]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}


def _save_pid(path: Path, payload: Dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def _is_pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        result = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}", "/FO", "CSV", "/NH"],
            check=False,
            capture_output=True,
            text=True,
        )
        line = (result.stdout or "").strip()
        if not line:
            return False
        if "No tasks are running" in line:
            return False
        return f'"{pid}"' in line or f",{pid}," in line
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    return True


def _terminate_pid(pid: int) -> bool:
    if not _is_pid_alive(pid):
        return False
    if os.name == "nt":
        subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
    return True


def _default_drive_root(interviews_root: Path) -> Path:
    preferred = Path(r"G:/My Drive/The Target Trap (Book Project)/Interviews/Raw")
    if preferred.exists() and preferred.is_dir():
        return preferred
    return interviews_root / "interview_raw"


def _build_cmd(args: argparse.Namespace, interviews_root: Path) -> list[str]:
    script = interviews_root / "scripts" / "auto_process_drive.py"
    drive_root = Path(args.drive_root).expanduser() if args.drive_root else _default_drive_root(interviews_root)
    if not drive_root.is_absolute():
        drive_root = (Path.cwd() / drive_root).resolve()

    cmd = [
        sys.executable,
        str(script),
        "--interviews-root",
        str(interviews_root),
        "--drive-root",
        str(drive_root),
        "--interval-seconds",
        str(max(args.interval_seconds, 5)),
        "--min-age-seconds",
        str(max(args.min_age_seconds, 1)),
        "--max-per-cycle",
        str(max(args.max_per_cycle, 1)),
    ]
    if args.excel:
        cmd.extend(["--excel", args.excel])
    if args.sheet:
        cmd.extend(["--sheet", args.sheet])
    if args.bootstrap_existing:
        cmd.append("--bootstrap-existing")
    if args.include_done:
        cmd.append("--include-done")
    if args.dry_run:
        cmd.append("--dry-run")
    return cmd


def _start(args: argparse.Namespace, interviews_root: Path) -> int:
    pid_path = _pid_file(interviews_root)
    log_path = _log_file(interviews_root)
    existing = _load_pid(pid_path)
    existing_pid = int(existing.get("pid", 0) or 0)

    if existing_pid and _is_pid_alive(existing_pid):
        print(f"Watcher already running (pid={existing_pid}).")
        print(f"Log: {log_path}")
        return 0

    cmd = _build_cmd(args, interviews_root)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_handle = log_path.open("a", encoding="utf-8")
    log_handle.write(f"\n[{_now_utc()}] Starting watcher\n")
    log_handle.flush()

    creationflags = 0
    if os.name == "nt":
        creationflags = subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.DETACHED_PROCESS

    proc = subprocess.Popen(
        cmd,
        cwd=str(interviews_root),
        stdout=log_handle,
        stderr=subprocess.STDOUT,
        stdin=subprocess.DEVNULL,
        creationflags=creationflags,
        close_fds=True,
    )

    payload = {
        "pid": proc.pid,
        "started_utc": _now_utc(),
        "command": cmd,
        "log_file": str(log_path),
    }
    _save_pid(pid_path, payload)

    print(f"Watcher started (pid={proc.pid}).")
    print(f"Log: {log_path}")
    return 0


def _stop(interviews_root: Path) -> int:
    pid_path = _pid_file(interviews_root)
    data = _load_pid(pid_path)
    pid = int(data.get("pid", 0) or 0)
    if not pid:
        print("Watcher is not running (no pid file).")
        return 0

    stopped = _terminate_pid(pid)
    if pid_path.exists():
        try:
            pid_path.unlink()
        except OSError:
            pass

    if stopped:
        print(f"Watcher stopped (pid={pid}).")
    else:
        print("Watcher was not running.")
    return 0


def _status(interviews_root: Path) -> int:
    pid_path = _pid_file(interviews_root)
    log_path = _log_file(interviews_root)
    data = _load_pid(pid_path)
    pid = int(data.get("pid", 0) or 0)
    alive = _is_pid_alive(pid) if pid else False

    print(f"Running: {'yes' if alive else 'no'}")
    if pid:
        print(f"PID: {pid}")
    if data:
        started = data.get("started_utc")
        if started:
            print(f"Started UTC: {started}")
        cmd = data.get("command")
        if cmd:
            print(f"Command: {' '.join(str(x) for x in cmd)}")
    print(f"Log: {log_path}")
    return 0


def main() -> int:
    args = parse_args()
    interviews_root = args.interviews_root.resolve()
    interviews_root.mkdir(parents=True, exist_ok=True)
    (interviews_root / "interview_raw").mkdir(parents=True, exist_ok=True)
    (interviews_root / "interview_notes").mkdir(parents=True, exist_ok=True)

    if args.action == "start":
        return _start(args, interviews_root)
    if args.action == "stop":
        return _stop(interviews_root)
    if args.action == "status":
        return _status(interviews_root)
    if args.action == "restart":
        _stop(interviews_root)
        return _start(args, interviews_root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
