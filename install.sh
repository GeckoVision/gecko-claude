#!/usr/bin/env bash
# =============================================================================
# Gecko one-line installer
#
#   curl -fsSL https://app.geckovision.tech/install.sh | bash
#
# What this does:
#   1. Verifies prereqs (Python 3.11+, uv, Claude Code CLI).
#   2. Installs `gecko-mcp` via `uv tool install` (PyPI; fall back to GitHub
#      subdirectory pre-publish via GECKO_MCP_REPO override).
#   3. Fetches the gecko-claude .claude/ + CLAUDE.md + .mcp.json.template into
#      the current directory (skips if .claude/ already exists, unless --force).
#   4. Registers the gecko MCP server with Claude Code.
#   5. Prints next steps — wallet onboarding happens INSIDE Claude Code.
#
# Flags:
#   --force                   Overwrite existing .claude/ directory.
#   --no-mcp-register         Skip the `claude mcp add` step.
#
# Env overrides for development (not for end users):
#   GECKO_MCP_REPO            git URL for `uv tool install` of gecko-mcp.
#                             Default: PyPI.
#   GECKO_MCP_VERSION         Version tag to install from PyPI. Pinned to a
#                             concrete release — never `latest`, never `main`.
#                             See packages/gecko-mcp/pyproject.toml in
#                             gecko-mcpay-api for the source of truth.
#   GECKO_CLAUDE_REPO_LOCAL   Local path to the gecko-claude repo to copy
#                             from (skips the tarball fetch). Used when
#                             developing the scaffold itself.
#   GECKO_CLAUDE_REPO         GitHub repo for the tarball.
#                             Default: ernanibmurtinho/gecko-claude.
#   GECKO_CLAUDE_REF          Git ref for the tarball. Default: main.
# =============================================================================
set -euo pipefail

# Pinned release tag. Bump in lockstep with packages/gecko-mcp/pyproject.toml
# in gecko-mcpay-api when a new release is published. Do NOT use `latest` or
# `main` — pipe-to-bash installers must be reproducible.
GECKO_MCP_VERSION="${GECKO_MCP_VERSION:-0.2.25}"

GECKO_MCP_REPO="${GECKO_MCP_REPO:-}"
GECKO_CLAUDE_REPO="${GECKO_CLAUDE_REPO:-ernanibmurtinho/gecko-claude}"
GECKO_CLAUDE_REF="${GECKO_CLAUDE_REF:-main}"
GECKO_CLAUDE_REPO_LOCAL="${GECKO_CLAUDE_REPO_LOCAL:-}"
FORCE=false
SKIP_MCP_REGISTER=false

while [ $# -gt 0 ]; do
  case "$1" in
    --force)              FORCE=true; shift ;;
    --no-mcp-register)    SKIP_MCP_REGISTER=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

c_red()    { printf "\033[31m%s\033[0m" "$*"; }
c_green()  { printf "\033[32m%s\033[0m" "$*"; }
c_yellow() { printf "\033[33m%s\033[0m" "$*"; }
c_bold()   { printf "\033[1m%s\033[0m" "$*"; }

ok()    { echo "  $(c_green ✓) $*"; }
warn()  { echo "  $(c_yellow !) $*"; }
fail()  { echo "  $(c_red ✗) $*" >&2; }
hdr()   { echo; echo "$(c_bold "▸ $*")"; }

# -----------------------------------------------------------------------------

hdr "1/4  Prereqs"

case "$(uname -s)" in
  Darwin)  ok "macOS" ;;
  Linux)   ok "Linux" ;;
  *)       fail "Windows is not supported. Use WSL2: https://learn.microsoft.com/en-us/windows/wsl/install"
           exit 1 ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 not found — install Python 3.11+ first (https://www.python.org)"
  exit 1
fi
PY_VER=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 11 ]; }; then
  fail "Python 3.11+ required (found $PY_VER)"
  exit 1
fi
ok "Python $PY_VER"

if ! command -v uv >/dev/null 2>&1; then
  warn "uv not found — installing"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
ok "uv $(uv --version 2>/dev/null | awk '{print $2}')"

if ! command -v claude >/dev/null 2>&1; then
  fail "Claude Code CLI not found — install at https://docs.anthropic.com/claude/claude-code"
  exit 1
fi
ok "Claude Code CLI present"

# -----------------------------------------------------------------------------

hdr "2/4  Install gecko-mcp"

# Idempotency: if `bb` already resolves to the pinned version, skip the
# install entirely. uv tool install --force would otherwise re-download and
# rebuild on every pipe-to-bash, which is wasteful and noisy.
INSTALLED_VERSION=""
if command -v bb >/dev/null 2>&1; then
  INSTALLED_VERSION="$(uv tool list 2>/dev/null | awk '/^gecko-mcp /{print $2; exit}')"
fi

if [ -n "$GECKO_MCP_REPO" ]; then
  echo "  source: $GECKO_MCP_REPO"
  uv tool install --force "$GECKO_MCP_REPO"
  ok "gecko-mcp installed (from override)"
elif [ "$INSTALLED_VERSION" = "v${GECKO_MCP_VERSION}" ] || [ "$INSTALLED_VERSION" = "${GECKO_MCP_VERSION}" ]; then
  ok "gecko-mcp ${GECKO_MCP_VERSION} already installed"
else
  # PyPI default. Pin a concrete version — never `latest` — so a re-run on
  # day N installs the exact same code as day 1. --reinstall-package
  # gecko-core forces a fresh resolve of the workspace dep so users with a
  # stale gecko-core cached locally don't get an import-mismatch.
  # See docs/v1.1-backlog.md V11-07 for the original observed failure mode.
  echo "  source: PyPI (gecko-mcp==${GECKO_MCP_VERSION})"
  if ! uv tool install --force --reinstall-package gecko-core "gecko-mcp==${GECKO_MCP_VERSION}" 2>/dev/null; then
    warn "PyPI install failed (gecko-mcp==${GECKO_MCP_VERSION} not yet published?)"
    echo "    falling back to GitHub source at the pinned tag"
    uv tool install --force "git+https://github.com/ernanibmurtinho/gecko-mcpay-api.git@v${GECKO_MCP_VERSION}#subdirectory=packages/gecko-mcp"
  fi
  ok "gecko-mcp installed (${GECKO_MCP_VERSION})"
fi

# -----------------------------------------------------------------------------

hdr "3/4  Install scaffolding into $(pwd)"

if [ -d ".claude" ] && [ "$FORCE" != "true" ]; then
  fail ".claude/ already exists in this directory. Re-run with --force to overwrite."
  exit 1
fi

if [ -n "$GECKO_CLAUDE_REPO_LOCAL" ]; then
  if [ ! -d "$GECKO_CLAUDE_REPO_LOCAL" ]; then
    fail "GECKO_CLAUDE_REPO_LOCAL=$GECKO_CLAUDE_REPO_LOCAL does not exist"
    exit 1
  fi
  echo "  source: $GECKO_CLAUDE_REPO_LOCAL (local)"
  cp -r "$GECKO_CLAUDE_REPO_LOCAL/.claude" .
  cp "$GECKO_CLAUDE_REPO_LOCAL/CLAUDE.md" .
  if [ ! -f .mcp.json ]; then
    cp "$GECKO_CLAUDE_REPO_LOCAL/.mcp.json.template" .mcp.json
  fi
else
  TAR_URL="https://github.com/$GECKO_CLAUDE_REPO/archive/$GECKO_CLAUDE_REF.tar.gz"
  echo "  source: $TAR_URL"
  TMP=$(mktemp -d)
  trap "rm -rf $TMP" EXIT
  curl -fsSL "$TAR_URL" | tar -xz -C "$TMP"
  EXTRACTED=$(find "$TMP" -maxdepth 1 -mindepth 1 -type d | head -1)
  cp -r "$EXTRACTED/.claude" .
  cp "$EXTRACTED/CLAUDE.md" .
  if [ ! -f .mcp.json ]; then
    cp "$EXTRACTED/.mcp.json.template" .mcp.json
  fi
fi
ok ".claude/, CLAUDE.md, .mcp.json installed"

# -----------------------------------------------------------------------------

hdr "4/4  Register MCP with Claude Code"

if [ "$SKIP_MCP_REGISTER" = "true" ]; then
  warn "skipped (run manually: claude mcp add gecko -- gecko-mcp serve)"
elif claude mcp list 2>/dev/null | grep -q "^gecko"; then
  ok "gecko already registered with Claude Code"
else
  claude mcp add gecko -- gecko-mcp serve >/dev/null
  ok "gecko registered with Claude Code"
fi

# -----------------------------------------------------------------------------

cat <<'EOF'

  Open Claude Code in this directory and paste:

      Read https://app.geckovision.tech/skill.md and follow the instructions.

  Claude will walk you through wallet setup (email + OTP), funding,
  and your first paid verdict from the 7-voice panel.

  Strategy oracle for autonomous trading agents · geckovision.tech
  No API keys, just a wallet.
EOF
