#!/usr/bin/env bash
# Materialize symlinked skills into real-content snapshots for Vercel deploy.
#
# Vercel does NOT follow cross-repo symlinks at build time. Run this BEFORE
# pushing to gecko-claude so the deploy publishes real files.
#
# Usage:
#   ./skills/sync.sh          # sync all skills referenced by symlinks
#   ./skills/sync.sh --check  # exit 1 if symlinks aren't materialized
#
# Idempotent. Preserves SKILL.md, grader.py, examples/, tests/ —
# everything but __pycache__/ and out/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
fi

# Find all symlinked skill dirs
mapfile -t SKILLS < <(find . -maxdepth 1 -type l)

if [[ ${#SKILLS[@]} -eq 0 ]]; then
    echo "  (no symlinked skills to sync)"
    exit 0
fi

for SKILL_LINK in "${SKILLS[@]}"; do
    SKILL_NAME="$(basename "$SKILL_LINK")"
    SRC_DIR="$(readlink -f "$SKILL_LINK")"
    DST_DIR="$SCRIPT_DIR/$SKILL_NAME"

    if [[ ! -d "$SRC_DIR" ]]; then
        echo "ERROR: symlink target missing for $SKILL_NAME: $SRC_DIR"
        exit 1
    fi

    if $CHECK_ONLY; then
        if [[ -L "$SKILL_LINK" ]]; then
            echo "  $SKILL_NAME: still a symlink (run without --check to materialize)"
            exit 1
        fi
        continue
    fi

    echo "  Syncing $SKILL_NAME from $SRC_DIR"
    # Remove the symlink, copy contents
    rm "$SKILL_LINK"
    mkdir -p "$DST_DIR"
    rsync -a --delete \
        --exclude='__pycache__/' --exclude='*.pyc' \
        --exclude='out/' --exclude='.pytest_cache/' \
        "$SRC_DIR/" "$DST_DIR/"
    echo "    done"
done

echo ""
echo "Sync complete. Verify with:  git status skills/"
echo "Then:                        git add skills/ && git commit -m 'chore(skills): sync $(date +%F)'"
