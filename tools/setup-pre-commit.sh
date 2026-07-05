#!/usr/bin/env bash
#
# setup-pre-commit.sh
# One-shot setup for pre-commit on a fresh Ubuntu/Debian host.
#
# What it does:
#   1. Installs pipx (via apt) if missing
#   2. Installs pre-commit (via pipx) if missing
#   3. Activates the git hooks for this repo (pre-commit install)
#   4. Optionally runs all hooks against the whole repo (--check-all)
#
# Usage (from anywhere inside the cloned repo):
#   ./tools/setup-pre-commit.sh
#   ./tools/setup-pre-commit.sh --check-all
#
set -euo pipefail

CHECK_ALL=false
if [[ "${1:-}" == "--check-all" ]]; then
    CHECK_ALL=true
fi

# --- 0. Make sure we're inside a git repo with a pre-commit config ---------
if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: not inside a git repository. Clone the repo first." >&2
    exit 1
fi
cd "${REPO_ROOT}"

if [[ ! -f .pre-commit-config.yaml ]]; then
    echo "ERROR: no .pre-commit-config.yaml found in ${REPO_ROOT}" >&2
    exit 1
fi

# --- 1. Install pipx if missing ---------------------------------------------
if ! command -v pipx >/dev/null 2>&1; then
    echo "==> Installing pipx (requires sudo)..."
    sudo apt-get update -qq
    sudo apt-get install -y pipx
    pipx ensurepath
    # Make pipx-installed tools visible in THIS shell session too
    export PATH="${HOME}/.local/bin:${PATH}"
else
    echo "==> pipx already installed, skipping."
fi

# --- 2. Install pre-commit if missing ---------------------------------------
if ! command -v pre-commit >/dev/null 2>&1; then
    echo "==> Installing pre-commit via pipx..."
    pipx install pre-commit
    export PATH="${HOME}/.local/bin:${PATH}"
else
    echo "==> pre-commit already installed: $(pre-commit --version)"
fi

# --- 3. Activate the git hooks for this clone -------------------------------
echo "==> Activating git hooks in ${REPO_ROOT}..."
pre-commit install

# --- 4. Optional: run every hook against every file -------------------------
if [[ "${CHECK_ALL}" == "true" ]]; then
    echo "==> Running all hooks against all files (first run may be slow)..."
    pre-commit run --all-files
else
    echo
    echo "Done. Hooks will now run automatically on 'git commit'."
    echo "Tip: run '${0##*/} --check-all' to validate the whole repo now."
fi
