# CLI bridge — intent → `bb trade-agent` subcommand

> Audience: the Claude Code instance executing this skill. Every user intent in class A (agent lifecycle) resolves to exactly one CLI invocation below. Anything not on this table re-routes per `SKILL.md` Step 0.

The runtime CLI is defined at `packages/gecko-core/src/gecko_core/trade_agent/cli.py` in the `gecko-mcpay-api` repo. This document is the contract; if the CLI signature drifts, update this file and bump skill `version`.

## `up` — start an agent

```
bb trade-agent up --spec <path> [--mode advisor] [--agent-id <id>] [--user-wallet <addr>]
```

| Flag | Required | Default | Notes |
|---|---|---|---|
| `--spec` | yes | — | Path to coach-emitted JSON. Must conform to the coach `schema.json`. |
| `--mode` | no | `advisor` | **Only `advisor` is supported in v0.1.** Never surface `--mode trader` in any sample command. If the user explicitly asks for trader mode, decline and explain v0.2. |
| `--agent-id` | no | fresh `agent_<uuid12>` | Pass an existing id to resume a stopped/paused agent against the same state row. |
| `--user-wallet` | no | unbound | Owner wallet — used by `ls --user-wallet <addr>` to filter. |
| `--exec-rail` | no | unset | **Do not pass in v0.1.** It's only valid with `--mode trader`. |

Expected stdout (first line, then runtime blocks on tick loop):

```
agent agent_<id> up — mode=advisor spec=<spec-name>@<version>
```

The process is foreground for v0.1. Surface the durability note ("run inside tmux / screen / systemd --user / launchd") on the first `up` of a session.

Common errors:
- `spec invalid: …` — coach must re-emit the spec; re-route to `gecko-trade-coach`.
- `MONGODB_URI is not set` — instruct the user to export it (or `GECKO_TRADE_AGENT_INMEMORY=1` for dev only).

## `ls` — list agents

```
bb trade-agent ls [--user-wallet <addr>]
```

| Flag | Required | Default | Notes |
|---|---|---|---|
| `--user-wallet` | no | all | Filter by binding from `up --user-wallet`. |

Expected stdout (zero or more rows):

```
agent_<id>  status=<state>  mode=advisor  spec=<spec-id>@<spec-version>
```

Or:

```
(no agents)
```

Skill behavior: re-emit the table in a more readable form (markdown table is acceptable). If the user asked "show MY agents" and `--user-wallet` is known, pass it; otherwise list all.

## `inspect` — heartbeat surface

```
bb trade-agent inspect <agent_id> [--limit 20]
```

| Flag | Required | Default | Notes |
|---|---|---|---|
| `<agent_id>` | yes | — | Positional. |
| `--limit` | no | 20 | Tail size for the journal section. Bump to 100 if user asks for "full" or "more". |

Expected stdout shape:

```
agent <id>  status=<state>  mode=<mode>  spec=<spec-id>@<spec-version>
open positions: <N>
  <position_id>  mint=<mint>  size_usd=<usd>  entry=<price>
  ...
recent journal (<N>):
  <iso-ts>  <event-name>  <payload-dict>
  ...
```

Skill must surface, in this order:

1. Status line.
2. **Heartbeat.** If a `last_tick_at` journal entry exists in the tail, compute `now - last_tick_at` and flag stale (> 10 min for the default 30s tick cadence). If the build doesn't journal heartbeats yet, say so plainly — do not fabricate.
3. Open positions count + each position one-line.
4. Journal tail with highlights on `circuit_breaker_trip`, `exec_error`, `oracle_call`, `opportunity` events.

This is THE place to answer "is my agent alive?". Treat it as the user's diagnostic dashboard, not a log dump.

Common error: `agent '<id>' not found` — run `ls` and confirm the id.

## `pause` — stop new entries

```
bb trade-agent pause <agent_id>
```

Flips `agent_state.status` to `paused`. The foreground process keeps running and managing existing positions; no new entry candidates are journaled.

Expected stdout:

```
agent <id> paused
```

Skill echo MUST include: "existing positions still managed, no new entries" — never a bare "paused" without that context.

After running, run `inspect` and surface the updated status line as confirmation.

## `stop` — terminate

```
bb trade-agent stop <agent_id>
```

Flips `agent_state.status` to `stopped`. The foreground `up` process polls status on each tick and exits cleanly.

Expected stdout:

```
agent <id> marked stopped
```

Skill echo MUST include: "foreground process will exit on next status poll — typically within a tick (~30s)". After running, optionally run `inspect` and surface the updated status.

## resume (no dedicated subcommand)

Resume = `up` with the same `--agent-id` (and original `--spec` path). The runtime re-attaches to the existing state row; the journal is durable, no positions are lost.

```
bb trade-agent up --spec <original-spec-path> --agent-id <existing-id>
```

If the user only remembers the id (not the spec path), the skill can fetch the spec id from `inspect`'s status line — but the on-disk spec file must still exist. If it doesn't, re-route to `gecko-trade-coach` to regenerate.

## flags the skill must NEVER surface in v0.1

- `--mode trader` — v0.2 only.
- `--exec-rail <anything>` — only valid with trader mode.
- `GECKO_TRADE_AGENT_INMEMORY=1` — fine to mention as a dev escape hatch, but NEVER as default; in-memory state means stop/restart loses everything.
