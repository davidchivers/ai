from __future__ import annotations

import argparse
import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--remote-host", default="hfnt93@hamilton8.dur.ac.uk")
    parser.add_argument("--poll-minutes", type=int, default=5)
    parser.add_argument("--max-hours", type=float, default=48)
    return parser.parse_args()


def now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def write_status(path: Path, message: str) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(f"{now_str()} {message}\n")


def parse_key_value_file(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            out[key.strip()] = value.strip()
    return out


def run_command(
    args: list[str],
    *,
    max_attempts: int = 4,
    retry_delay_seconds: int = 20,
    allow_failure: bool = False,
) -> str:
    last_stdout = ""
    for attempt in range(1, max_attempts + 1):
        proc = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, check=False)
        last_stdout = proc.stdout or ""
        if proc.returncode == 0:
            return last_stdout
        if attempt < max_attempts:
            time.sleep(retry_delay_seconds)
    if allow_failure:
        return last_stdout
    return ""


def normalize_ssh_output(raw: str) -> str:
    lines: list[str] = []
    for line in raw.replace("\r", "").splitlines():
        stripped = line.strip()
        if stripped.startswith("Connection to ") and stripped.endswith(" closed."):
            continue
        if stripped.startswith("Shared connection to ") and stripped.endswith(" closed."):
            continue
        if stripped.startswith("client_loop: send disconnect:"):
            continue
        lines.append(line)
    return "\n".join(lines)


def ssh_capture(key_path: Path, remote_host: str, remote_cmd: str) -> str:
    raw = run_command(
        [
            "ssh",
            "-tt",
            "-F",
            "NUL",
            "-o",
            "IdentitiesOnly=yes",
            "-o",
            "ConnectTimeout=10",
            "-i",
            str(key_path),
            remote_host,
            remote_cmd,
        ],
        allow_failure=True,
    )
    return normalize_ssh_output(raw)


def get_job_record(key_path: Path, remote_host: str, job_id: str) -> dict[str, str] | None:
    if not job_id:
        return None
    raw = ssh_capture(
        key_path,
        remote_host,
        f"sacct -j {job_id} --format=JobID,State,ExitCode,Elapsed -n -P 2>/dev/null || true",
    )
    for line in raw.splitlines():
        parts = line.split("|")
        if len(parts) >= 4 and parts[0] == job_id:
            return {
                "job_id": parts[0],
                "state": parts[1],
                "exit_code": parts[2],
                "elapsed": parts[3],
            }
    return None


def get_remote_status_tail(key_path: Path, remote_host: str, remote_run_dir: str) -> list[str]:
    if not remote_run_dir:
        return []
    raw = ssh_capture(key_path, remote_host, f"tail -n 30 '{remote_run_dir}/status.txt' 2>/dev/null || true")
    return [line for line in raw.splitlines() if line.strip()]


def get_best_remote_case(status_lines: list[str]) -> tuple[str, str] | None:
    best_case = None
    best_val = None
    for line in status_lines:
        if " DONE " not in f" {line} " or "maxres=" not in line:
            continue
        try:
            _, rest = line.split(" DONE ", 1)
            label, rest = rest.split(" maxres=", 1)
            maxres = rest.split()[0]
        except ValueError:
            continue
        try:
            val = float(maxres)
        except ValueError:
            continue
        if best_val is None or val < best_val:
            best_val = val
            best_case = (label, maxres)
    return best_case


def write_live_note(
    note_path: Path,
    autopilot_map: dict[str, str],
    job_record: dict[str, str] | None,
    remote_status_lines: list[str],
    best_remote_case: tuple[str, str] | None,
    autopilot_last_line: str,
) -> None:
    lines: list[str] = []
    lines.append("# Bellman RE live progress")
    lines.append("")
    lines.append(f"Updated: {now_str()}")
    lines.append("")
    lines.append("## Runner")
    lines.append("")
    lines.append(f"- state: {autopilot_map.get('state', '')}")
    lines.append(f"- horizon: {autopilot_map.get('current_horizon', '')}")
    lines.append(f"- job id: {autopilot_map.get('current_job_id', '')}")
    lines.append(f"- remote run dir: {autopilot_map.get('current_remote_run_dir', '')}")
    lines.append(f"- profile: {autopilot_map.get('current_profile_name', '')}")
    lines.append(f"- attempt index: {autopilot_map.get('current_attempt_index', '')}")
    if autopilot_map.get("best_case"):
        lines.append(f"- latest promoted best case: {autopilot_map['best_case']}")
    if autopilot_map.get("best_maxres"):
        lines.append(f"- latest promoted best maxres: {autopilot_map['best_maxres']}")
    lines.append("")
    lines.append("## Remote job")
    lines.append("")
    if job_record is None:
        lines.append("- No remote job record is currently visible.")
    else:
        lines.append(f"- state: {job_record['state']}")
        lines.append(f"- exit code: {job_record['exit_code']}")
        lines.append(f"- elapsed: {job_record['elapsed']}")
    lines.append("")
    lines.append("## Current remote status")
    lines.append("")
    if remote_status_lines:
        lines.append(f"- latest event: {remote_status_lines[-1]}")
        if best_remote_case is not None:
            lines.append(f"- best completed case in current remote run: {best_remote_case[0]} with maxres {best_remote_case[1]}")
        lines.append("")
        lines.append("```text")
        lines.extend(remote_status_lines)
        lines.append("```")
    else:
        lines.append("- Remote status tail is not available yet.")
    lines.append("")
    lines.append("## Autopilot log")
    lines.append("")
    if autopilot_last_line:
        lines.append(f"- latest runner event: {autopilot_last_line}")
    else:
        lines.append("- No autopilot status line is available yet.")
    note_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()

    project_root = Path(__file__).resolve().parent.parent
    logs_root = project_root / "notes" / "build" / "logs"
    logs_root.mkdir(parents=True, exist_ok=True)

    key_path = Path.home() / ".ssh" / "id_ed25519"
    if not key_path.exists():
        raise FileNotFoundError(f"SSH key not found: {key_path}")

    run_stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = logs_root / f"bellman_re_horizon_update_reporter_{run_stamp}"
    run_dir.mkdir(parents=True, exist_ok=True)

    status_path = run_dir / "status.txt"
    manifest_path = run_dir / "manifest.txt"
    latest_pointer_path = logs_root / "latest_bellman_re_horizon_update_reporter.txt"
    active_pointer_path = logs_root / "active_bellman_re_horizon_update_reporter.txt"
    autopilot_pointer_path = logs_root / "active_bellman_re_horizon_autopilot.txt"
    live_note_path = project_root / "notes" / "build" / "compiled_sidecar_bellman_re_live_progress.md"

    manifest_path.write_text(
        "\n".join(
            [
                "Objective: follow the Bellman RE horizon autopilot and keep a live human-readable progress note updated.",
                f"Project root: {project_root}",
                f"Autopilot pointer: {autopilot_pointer_path}",
                f"Live note: {live_note_path}",
                f"Remote host: {args.remote_host}",
                f"Poll minutes: {args.poll_minutes}",
                f"Max hours: {args.max_hours}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    pointer_payload = "\n".join(
        [
            f"started_at={now_str()}",
            f"run_dir={run_dir}",
            f"status_path={status_path}",
            f"manifest_path={manifest_path}",
            f"live_note_path={live_note_path}",
            f"autopilot_pointer_path={autopilot_pointer_path}",
        ]
    ) + "\n"
    latest_pointer_path.write_text(pointer_payload, encoding="utf-8")
    active_pointer_path.write_text(pointer_payload, encoding="utf-8")

    deadline = datetime.now() + timedelta(hours=args.max_hours)
    last_fingerprint = ""
    write_status(status_path, "START reporter")

    while datetime.now() < deadline:
        autopilot_map = parse_key_value_file(autopilot_pointer_path)
        if not autopilot_map:
            write_status(status_path, "WAIT no_autopilot_pointer")
            time.sleep(args.poll_minutes * 60)
            continue

        autopilot_status_raw = autopilot_map.get("status_path", "").strip()
        autopilot_last_line = ""
        if autopilot_status_raw:
            autopilot_status_path = Path(autopilot_status_raw)
        else:
            autopilot_status_path = None
        if autopilot_status_path is not None and autopilot_status_path.is_file():
            lines = autopilot_status_path.read_text(encoding="utf-8", errors="replace").splitlines()
            if lines:
                autopilot_last_line = lines[-1]

        current_job_id = autopilot_map.get("current_job_id", "")
        current_remote_run_dir = autopilot_map.get("current_remote_run_dir", "")
        runner_state = autopilot_map.get("state", "")
        current_horizon = autopilot_map.get("current_horizon", "")

        job_record = get_job_record(key_path, args.remote_host, current_job_id)
        remote_status_lines = get_remote_status_tail(key_path, args.remote_host, current_remote_run_dir)
        best_remote_case = get_best_remote_case(remote_status_lines)
        latest_remote_line = remote_status_lines[-1] if remote_status_lines else ""

        best_remote_label = best_remote_case[0] if best_remote_case else ""
        best_remote_maxres = best_remote_case[1] if best_remote_case else ""

        fingerprint = "|".join(
            [
                runner_state,
                current_horizon,
                current_job_id,
                current_remote_run_dir,
                autopilot_last_line,
                latest_remote_line,
                best_remote_label,
                best_remote_maxres,
            ]
        )

        if fingerprint != last_fingerprint:
            write_live_note(
                live_note_path,
                autopilot_map,
                job_record,
                remote_status_lines,
                best_remote_case,
                autopilot_last_line,
            )
            write_status(status_path, f"UPDATE horizon={current_horizon} job={current_job_id} runner_state={runner_state}")
            last_fingerprint = fingerprint

        if runner_state == "STOPPED":
            write_status(status_path, "STOP reporter reason=autopilot_stopped")
            break

        time.sleep(args.poll_minutes * 60)

    active_pointer_path.write_text(
        "\n".join(
            [
                f"stopped_at={now_str()}",
                f"run_dir={run_dir}",
                f"status_path={status_path}",
                f"live_note_path={live_note_path}",
                f"autopilot_pointer_path={autopilot_pointer_path}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
