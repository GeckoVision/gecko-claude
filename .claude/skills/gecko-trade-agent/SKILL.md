---
name: gecko-trade-agent
description: User-facing wrapper for the local `bb trade-agent` runtime. Deploy, list, inspect, pause, stop long-running advisor agents that surface opportunities grounded by Gecko's verdict oracle. Never holds keys; never executes in v0.1 — advisor mode only, opportunities journaled for review. Triggers — deploy strategy, deploy my agent, show my agents, list my agents, what is my agent doing, inspect agent, stop agent, pause agent, resume agent, agent status, agent health, running agents, gecko agent, trade agent.
license: MIT
version: "0.1.0"
metadata:
  author: gecko
  homepage: "https://geckovision.tech"
  oracle_tool: gecko_trade_research
  runtime_cli: "bb trade-agent"
  peer_skills:
    - gecko-trade-coach
    - gecko-wallet
---

# Gecko Trade Agent

> The user-facing surface for Gecko's self-hosted advisor runtime. The runtime is a local Python process; this skill is the thin Claude Code layer that turns "what's my agent doing?" into the right `bb trade-agent` invocation.

## Scope

- Lifecycle management for self-hosted trade agents: deploy, list, inspect, pause, resume, stop.
- **Advisor mode only for v0.1.** The runtime surfaces opportunities and journals them. It does NOT sign transactions and does NOT hold keys. Trader mode is a v0.2 surface.
- Execution-venue neutral by design — when trader mode lands, the same skill will route through OKX OnchainOS, SendAI, or Backpack peer skills with no user-visible change.
- This skill is a wrapper. Every action shells out to `bb trade-agent <subcommand>`. If the CLI isn't installed, the skill stops and points at the install command.

## Step 0 — Re-route check (run before every other step)

Classify the user's intent before any shell call. Four classes.

| Intent class | Signals | Action |
|---|---|---|
| **A. Agent lifecycle** | "deploy", "show my agents", "what's agent X doing", "stop agent", "pause", "resume", "inspect" | **Stay.** Use the intent map in Step 2. |
| **B. Strategy design** | "build a strategy", "should I deploy this spec", "what entry rule should I use", "coach me through a trade" | Re-route to `gecko-trade-coach`. The coach emits the spec; this skill deploys it. |
| **C. Wallet ops** | "fund my agent", "do I have enough SOL", "swap tokens", "should I bridge" | Re-route to `gecko-wallet`. The agent runtime never moves funds. |
| **D. Single-shot judgment** | "should I deposit USDC into Kamino now?" (no agent involved) | Re-route to `gecko_trade_research` direct. No agent needed. |

If you have started running commands and only then realise a re-route applies, halt and invoke the correct skill — do not continue lifecycle ops in this skill.

## Step 1 — Preflight

Run these checks before the first lifecycle command.

1. **Runtime installed.** Verify `bb trade-agent --help` returns successfully. If not, stop and say: *"This skill wraps the local Gecko trade-agent runtime. Install with: `curl -fsSL https://app.geckovision.tech/install.sh | bash` and restart your shell."*
2. **Mongo reachable.** The runtime requires `MONGODB_URI` set for durable journal + state. If missing, instruct the user to set it (or run with `GECKO_TRADE_AGENT_INMEMORY=1` for ephemeral dev-only mode — flag this as non-production).
3. **Advisor-mode callout.** v0.1 ships advisor mode only. If the user asks for trader mode or `--mode trader`, reply: *"Trader mode lands in v0.2 — advisor mode for now surfaces opportunities without signing. Your agent will journal entries for you to act on manually."* Do NOT surface a `--mode trader` flag in any sample command.
4. **Cost expectation.** The runtime calls `gecko_trade_research` on schedule (~$0.25 daily refresh) and at startup (~$0.75 pro verdict, charged on cache miss). Steady-state cost per running agent is ~$1.50/day. Quote this once in the first deploy of a session.

## Step 2 — Intent → CLI map

Every user intent in class A resolves to one `bb trade-agent` subcommand. The skill confirms what changed and reads back the new state — never just "ok".

| User says | Skill executes | Echo back |
|---|---|---|
| "Deploy strategy at `~/specs/mean-revert.json`" | `bb trade-agent up --spec ~/specs/mean-revert.json` | `agent <id> up — mode=advisor spec=<name>@<version>` |
| "Deploy with my wallet `<addr>`" | `bb trade-agent up --spec <path> --user-wallet <addr>` | id + wallet binding |
| "Show my agents" / "list agents" | `bb trade-agent ls` | rows: `<id>  status=<state>  mode=advisor  spec=<n>@<v>` |
| "Show agents owned by `<wallet>`" | `bb trade-agent ls --user-wallet <addr>` | filtered rows |
| "What is agent `<id>` doing" / "inspect" | `bb trade-agent inspect <id>` | status + open positions count + last 20 journal events + **last_tick_at** (heartbeat) |
| "Tail more events on `<id>`" | `bb trade-agent inspect <id> --limit 100` | extended journal |
| "Pause new entries on `<id>`" | `bb trade-agent pause <id>` | `agent <id> paused — existing positions still managed, no new entries` |
| "Resume `<id>`" / "unpause" | `bb trade-agent up --spec <original-spec> --agent-id <id>` (re-up; see lifecycle) | `agent <id> running` |
| "Stop `<id>`" | `bb trade-agent stop <id>` | `agent <id> stopped — foreground process will exit on next status poll` |
| "Fire a verdict now" / "what's the panel saying right now" / "force a re-check" | `bb trade-agent reverdict <id> --tier basic` | `verdict=<act\|pass\|defer>  confidence=<f>  citations=<n>  dissent=<n>` (journaled as `verdict_called` event) |
| "Get a pro verdict on the strategy" | `bb trade-agent reverdict <id> --tier pro` | same shape + `backtest` field present in the cached verdict |
| "Clean up old stopped agents" / "purge orphans" | `bb trade-agent purge --status stopped` | per-row `PURGED <id>` lines |
| "What would purge delete" | `bb trade-agent purge --dry-run` | per-row `WOULD PURGE <id>` lines, no deletion |

The runtime's `up` is foreground for v0.1. The user should run it in a `tmux` / `screen` / `systemd --user` / `launchd` wrapper for durability. Surface this on the first `up` of a session.

### Running `up` from inside Claude Code

When the user asks to deploy from a Claude Code chat (not their own terminal), `bb trade-agent up` is a long-running foreground process and CANNOT be invoked as a blocking shell call — Claude's Bash tool will hang waiting for it to exit.

Two acceptable patterns:

1. **Recommended — background mode.** Invoke the Bash tool with `run_in_background: true`. Claude returns immediately with the agent_id parsed from the boot line; the user can `inspect` from chat afterward. Stopping happens via `bb trade-agent stop <id>` (state-only), then the background process exits cleanly on its next poll.

2. **Acceptable — point the user at a fresh terminal.** If background mode isn't supported in the harness, surface the exact `bb trade-agent up …` command and tell the user: *"Run this in a separate terminal (or `tmux new -s gecko-agent`). I'll inspect and reverdict from here."*

Never block the chat on a foreground `up`. If the harness doesn't background well, do pattern 2.

### Demo flow inside Claude Code

For a 90-second demo from a single chat session:

1. User: *"Deploy my Kamino DCA strategy at `~/.gecko/specs/example-kamino-dca.json` in advisor mode."* → invoke `bb trade-agent up …` in background mode; parse + return agent_id.
2. User: *"What's it doing?"* → `bb trade-agent inspect <id>` → surface status + heartbeat + journal.
3. User: *"Fire a verdict right now."* → `bb trade-agent reverdict <id> --tier basic` → returns verdict + citations + dissent in ~30s; re-inspect to show the journal entry landed.
4. User: *"Stop the agent."* → `bb trade-agent stop <id>` (state-only flip; the background process exits on next status poll).

This is the v0.1 demo loop. No terminal switch required.

### Lifecycle confirmations are loud

Stop, pause, and resume each write a journal entry on the runtime side. The skill MUST echo:

1. What changed (status transition: `running → paused`).
2. The new state (re-run `bb trade-agent inspect <id>` automatically after pause/stop and surface the relevant lines).
3. What it means for the user (paused = existing positions still tracked, no new entry signals journaled; stopped = process exits, no more ticks).

A bare `ok` is a Skill Quality regression. Always read back.

### Inspect is the heartbeat surface

Per the design spec §8 risk register, self-hosted runtimes on user laptops are brittle (sleep, network drops, OS quirks). The `inspect` flow MUST give the user a one-glance answer to "is my agent alive?".

Surface, in this order:

1. **Status + mode + spec version.** Single line.
2. **Heartbeat.** `last tick: 14 min ago` (healthy if < ~2× tick cadence; flag stale otherwise). If the runtime hasn't ticked in 10+ minutes, surface a loud `DEAD or asleep — last tick at HH:MM` warning and suggest checking the foreground process.
3. **Open positions count + each position one-line.** Mint, size, entry. v0.1 advisor never opens real positions — this list is journaled candidates only; label as `(advisor-mode opportunity)` if applicable.
4. **Recent journal events.** Last 20 by default. Highlight `circuit_breaker_trip`, `exec_error`, `oracle_call` lines.

If the runtime's `inspect` output doesn't carry a `last_tick_at` (early v0.1 builds), say so plainly: *"This runtime build doesn't report heartbeats yet — check the foreground `bb trade-agent up` process directly."* Don't fake it.

## Step 3 — Lifecycle states

Four states. Always name the state the agent is in when you describe it; never improvise synonyms.

| State | What it means | How you got here | How you leave |
|---|---|---|---|
| `running` | Foreground process up, ticking, journaling, calling oracle on cadence. | Successful `bb trade-agent up`. | `stop` (clean exit), `pause` (still running but no new entries), or process crash. |
| `paused` | Process still up; existing positions tracked; no new entry candidates journaled. | `bb trade-agent pause <id>`. | Re-run `up` with same `--agent-id` to resume; or `stop` to terminate. |
| `stopped` | State row flipped; foreground process polls status and exits cleanly on next tick. | `bb trade-agent stop <id>`. | Fresh `up` (same spec or edited) — see hot-swap note below. |
| `halted` | Circuit breaker tripped (daily loss exceeded, or surviving-dissent strength crossed threshold). Existing positions managed; no new entries; cool-down ticking. | Automatic. The runtime sets this and journals a `circuit_breaker_trip` event. | Cool-down expires automatically, or the user `stop`s + `up`s a fixed spec. |

**Cold restart resume:** if the foreground process dies (laptop sleep, network drop), re-running `bb trade-agent up --spec <same-path> --agent-id <same-id>` re-attaches to the existing state row. The journal is durable in Mongo; no positions are lost.

**Hot-swap (founder mental model only):** when a user edits their spec, the cleanest user-visible flow is `stop` → `up`. Do NOT advertise in-place atomic cutover in skill copy. Users see "edit spec → re-deploy" — not "in-place ECS cutover". The runtime may handle the swap atomically under the hood; the surface stays simple.

## Step 4 — Failure modes

| Symptom | Likely cause | Skill says |
|---|---|---|
| `bb: command not found` | Runtime not installed | Pointer to the `install.sh` curl command. |
| `MONGODB_URI is not set` | Required env missing | Tell user to export `MONGODB_URI`, or run `GECKO_TRADE_AGENT_INMEMORY=1` for dev only. |
| `spec invalid: …` | Coach-emitted JSON failed schema check | Re-route to `gecko-trade-coach` to regenerate the spec. |
| `agent '<id>' not found` | Typo or wrong state store | Show `bb trade-agent ls` output, confirm the id. |
| Inspect shows `last tick > 10 min ago` | Foreground process dead or asleep | Tell user to check their tmux/launchd wrapper; offer to re-`up` with the original spec + agent-id. |
| Journal shows `circuit_breaker_trip` | Daily loss or dissent threshold breached | Read back the trip event verbatim; surface the citation IDs from the trip's verdict; route the user to `gecko-trade-coach` to revise the spec if the breach is structural. |

## Re-route table

| Intent | Skill |
|---|---|
| Build a strategy from scratch / revise a spec | `gecko-trade-coach` |
| Fund the agent's wallet / check balance | `gecko-wallet` |
| Swap tokens manually (not the agent's job) | `okx-dex-swap` |
| Single-shot judgment ("should I deposit USDC into Kamino?") | `gecko_trade_research` direct |
| Validate a non-trading idea | `gecko_research` |
| Audit a past trade / review on-chain history | `okx-audit-log` |
| "Is this contract safe to approve" | `okx-security` |

## Output contract

This skill emits **no JSON spec**. Outputs:

1. The exact `bb trade-agent` command that was run (or would be run, on a dry-run request).
2. A plain-language read-back of the new state after the command — what changed, what it means.
3. For `inspect`: a structured but human-readable summary of status + heartbeat + positions + journal.

No improvising. No CLI call → no state claim. Loud failure beats silent ungroundedness.

## References

- `references/cli-bridge.md` — exact mapping: user intent class → `bb trade-agent` subcommand → flags → expected output shape.
- `references/lifecycle.md` — state machine, heartbeat semantics, cold-restart behavior, advisor vs trader applicability.
