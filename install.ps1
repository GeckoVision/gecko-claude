# =============================================================================
# Gecko one-line installer (Windows / PowerShell)
#
#   irm https://app.geckovision.tech/install.ps1 | iex
#
# The bash installer (install.sh) is the macOS / Linux path. This is the
# native Windows equivalent — same four steps, PowerShell idioms.
#
# What this does:
#   1. Verifies prereqs (Python 3.11+, uv, Claude Code CLI).
#   2. Installs `gecko-mcp` via `uv tool install` (PyPI; GitHub tag fallback).
#   3. Fetches the gecko-claude .claude/ + CLAUDE.md + .mcp.json.template into
#      the current directory (never clobbers an existing .claude/ or CLAUDE.md
#      unless GECKO_FORCE=1).
#   4. Registers the gecko MCP server with Claude Code.
#
# Env overrides (piped `irm | iex` cannot take CLI args — use env vars):
#   $env:GECKO_FORCE = "1"               Overwrite existing .claude/ + CLAUDE.md.
#   $env:GECKO_SKIP_MCP_REGISTER = "1"   Skip the `claude mcp add` step.
#   $env:GECKO_MCP_VERSION               Pinned release tag. Never `latest`.
#   $env:GECKO_MCP_REPO                  git URL override for gecko-mcp.
#   $env:GECKO_CLAUDE_REPO               GitHub repo for the scaffold archive.
#   $env:GECKO_CLAUDE_REF                Git ref for the archive. Default: main.
#   $env:GECKO_CLAUDE_REPO_LOCAL         Local gecko-claude path (skip fetch).
# =============================================================================

$ErrorActionPreference = "Stop"

# Pinned release tag — keep in lockstep with install.sh and
# packages/gecko-mcp/pyproject.toml. Never `latest`, never `main`:
# pipe-to-shell installers must be reproducible.
$GeckoMcpVersion   = if ($env:GECKO_MCP_VERSION) { $env:GECKO_MCP_VERSION } else { "0.2.25" }
$GeckoMcpRepo      = $env:GECKO_MCP_REPO
$GeckoClaudeRepo   = if ($env:GECKO_CLAUDE_REPO) { $env:GECKO_CLAUDE_REPO } else { "ernanibmurtinho/gecko-claude" }
$GeckoClaudeRef    = if ($env:GECKO_CLAUDE_REF) { $env:GECKO_CLAUDE_REF } else { "main" }
$GeckoClaudeLocal  = $env:GECKO_CLAUDE_REPO_LOCAL
$Force             = $env:GECKO_FORCE -eq "1"
$SkipMcpRegister   = $env:GECKO_SKIP_MCP_REGISTER -eq "1"

function Write-Ok   { param($m) Write-Host "  [ok] "   -ForegroundColor Green  -NoNewline; Write-Host $m }
function Write-Warn { param($m) Write-Host "  [!]  "    -ForegroundColor Yellow -NoNewline; Write-Host $m }
function Write-Fail { param($m) Write-Host "  [x] "     -ForegroundColor Red    -NoNewline; Write-Host $m }
function Write-Hdr  { param($m) Write-Host ""; Write-Host "> $m" -ForegroundColor White }

# Copy CLAUDE.md from $SrcDir, but never silently clobber a user's existing
# CLAUDE.md — overwrite only when GECKO_FORCE=1.
function Copy-ClaudeMd {
  param($SrcDir)
  if ((Test-Path "CLAUDE.md") -and (-not $Force)) {
    Write-Warn "CLAUDE.md already exists - keeping yours (set GECKO_FORCE=1 to overwrite)"
  } else {
    Copy-Item "$SrcDir\CLAUDE.md" "." -Force
  }
}

# -----------------------------------------------------------------------------
Write-Hdr "1/4  Prereqs"

# Python 3.11+
$pythonCmd = $null
foreach ($candidate in @("python", "py")) {
  if (Get-Command $candidate -ErrorAction SilentlyContinue) { $pythonCmd = $candidate; break }
}
if (-not $pythonCmd) {
  Write-Fail "Python not found - install Python 3.11+ from https://www.python.org/downloads/windows/"
  exit 1
}
$pyVerRaw = (& $pythonCmd --version 2>&1) -replace "Python\s+", ""
$pyParts  = $pyVerRaw.Split(".")
if (([int]$pyParts[0] -lt 3) -or ([int]$pyParts[0] -eq 3 -and [int]$pyParts[1] -lt 11)) {
  Write-Fail "Python 3.11+ required (found $pyVerRaw)"
  exit 1
}
Write-Ok "Python $pyVerRaw"

# uv — auto-install if missing
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Warn "uv not found - installing"
  Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
  $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Fail "uv install failed - install manually from https://docs.astral.sh/uv/getting-started/installation/"
  exit 1
}
Write-Ok "uv $((uv --version) -replace 'uv\s+', '')"

# Claude Code CLI
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Fail "Claude Code CLI not found - install from https://docs.anthropic.com/claude/claude-code"
  exit 1
}
Write-Ok "Claude Code CLI present"

# -----------------------------------------------------------------------------
Write-Hdr "2/4  Install gecko-mcp"

$installedVersion = ""
if (Get-Command bb -ErrorAction SilentlyContinue) {
  $line = (uv tool list 2>$null | Select-String -Pattern "^gecko-mcp ")
  if ($line) { $installedVersion = ($line -split "\s+")[1] }
}

if ($GeckoMcpRepo) {
  Write-Host "  source: $GeckoMcpRepo"
  uv tool install --force "$GeckoMcpRepo"
  Write-Ok "gecko-mcp installed (from override)"
}
elseif ($installedVersion -eq "v$GeckoMcpVersion" -or $installedVersion -eq $GeckoMcpVersion) {
  Write-Ok "gecko-mcp $GeckoMcpVersion already installed"
}
else {
  # PyPI default, pinned. --reinstall-package gecko-core forces a fresh
  # workspace-dep resolve so a stale local gecko-core can't cause an
  # import mismatch.
  Write-Host "  source: PyPI (gecko-mcp==$GeckoMcpVersion)"
  uv tool install --force --reinstall-package gecko-core "gecko-mcp==$GeckoMcpVersion" 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Warn "PyPI install failed (gecko-mcp==$GeckoMcpVersion not yet published?)"
    Write-Host "    falling back to GitHub source at the pinned tag"
    uv tool install --force "git+https://github.com/ernanibmurtinho/gecko-mcpay-api.git@v$GeckoMcpVersion#subdirectory=packages/gecko-mcp"
    if ($LASTEXITCODE -ne 0) {
      Write-Fail "gecko-mcp install failed from both PyPI and GitHub"
      exit 1
    }
  }
  Write-Ok "gecko-mcp installed ($GeckoMcpVersion)"
}

# -----------------------------------------------------------------------------
Write-Hdr "3/4  Install scaffolding into $($PWD.Path)"

if ((Test-Path ".claude") -and (-not $Force)) {
  Write-Fail ".claude/ already exists in this directory. Set GECKO_FORCE=1 to overwrite."
  exit 1
}

if ($GeckoClaudeLocal) {
  if (-not (Test-Path $GeckoClaudeLocal)) {
    Write-Fail "GECKO_CLAUDE_REPO_LOCAL=$GeckoClaudeLocal does not exist"
    exit 1
  }
  Write-Host "  source: $GeckoClaudeLocal (local)"
  Copy-Item "$GeckoClaudeLocal\.claude" "." -Recurse -Force
  Copy-ClaudeMd $GeckoClaudeLocal
  if (-not (Test-Path ".mcp.json")) {
    Copy-Item "$GeckoClaudeLocal\.mcp.json.template" ".mcp.json"
  }
}
else {
  # GitHub serves a .zip archive — native to Expand-Archive, no tar dependency.
  $zipUrl = "https://github.com/$GeckoClaudeRepo/archive/$GeckoClaudeRef.zip"
  Write-Host "  source: $zipUrl"
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("gecko-" + [System.Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  try {
    $zipPath = Join-Path $tmp "repo.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $tmp -Force
    $extracted = (Get-ChildItem -Path $tmp -Directory | Select-Object -First 1).FullName
    Copy-Item "$extracted\.claude" "." -Recurse -Force
    Copy-ClaudeMd $extracted
    if (-not (Test-Path ".mcp.json")) {
      Copy-Item "$extracted\.mcp.json.template" ".mcp.json"
    }
  }
  finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
Write-Ok ".claude/, CLAUDE.md, .mcp.json installed"

# -----------------------------------------------------------------------------
Write-Hdr "4/4  Register MCP with Claude Code"

if ($SkipMcpRegister) {
  Write-Warn "skipped (run manually: claude mcp add gecko -- gecko-mcp serve)"
}
elseif ((claude mcp list 2>$null) -match "^gecko") {
  Write-Ok "gecko already registered with Claude Code"
}
else {
  claude mcp add gecko -- gecko-mcp serve | Out-Null
  Write-Ok "gecko registered with Claude Code"
}

# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "  Open Claude Code in this directory and paste:"
Write-Host ""
Write-Host "      Read https://app.geckovision.tech/skill.md and follow the instructions."
Write-Host ""
Write-Host "  Claude will walk you through wallet setup (email + OTP), funding,"
Write-Host "  and your first paid verdict from the 7-voice panel."
Write-Host ""
Write-Host "  Strategy oracle for autonomous trading agents - geckovision.tech"
Write-Host "  No API keys, just a wallet."
