#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$ROOT_DIR/demos"

if [[ ! -d "$DEMO_DIR" ]]; then
  echo "No demos/ directory found. Nothing to clean."
  exit 0
fi

rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR"
echo "Cleaned demo files. demos/ has been reset."
