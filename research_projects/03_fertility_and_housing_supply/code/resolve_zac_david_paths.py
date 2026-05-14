from __future__ import annotations

import os
from pathlib import Path


def candidate_zac_david_roots() -> list[Path]:
    candidates: list[Path] = []

    env_root = os.environ.get("ZAC_DAVID_EXTERNAL_ROOT", "").strip()
    if env_root:
        candidates.append(Path(env_root))

    candidates.append(Path(r"D:\research_data\zac_and_david"))

    userprofile = os.environ.get("USERPROFILE", "").strip()
    if userprofile:
        candidates.append(Path(userprofile) / "Dropbox" / "Zac and David")

    home_dropbox = Path.home() / "Dropbox" / "Zac and David"
    candidates.append(home_dropbox)

    deduped: list[Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        key = str(candidate).lower()
        if key in seen:
            continue
        deduped.append(candidate)
        seen.add(key)
    return deduped


def resolve_zac_david_path(*parts: str | Path) -> Path:
    relative = Path()
    for part in parts:
        relative /= Path(part)

    for root in candidate_zac_david_roots():
        candidate = root / relative
        if candidate.exists():
            return candidate

    searched = ", ".join(str(root / relative) for root in candidate_zac_david_roots())
    raise FileNotFoundError(f"Could not find Zac and David asset at any known root: {searched}")
