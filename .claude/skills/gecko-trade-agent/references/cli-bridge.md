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

## `reverdict` — fire a manual verdict cycle (demo-friendly)

```
bb trade-agent reverdict <agent_id> [--tier basic|pro] [--dry-run | --live]
```

Forces a manual oracle cycle on-demand instead of waiting on the 24h scheduled cadence. Looks up the agent's spec from `agent_state`, calls the oracle with `trigger=manual + force_refresh=True`, writes the result to `agent_verdict_cache`, and journals `verdict_called`.

| Flag | Effect | When |
|---|---|---|
| (default) | Talks to prod `/trade_research` with stub-signature. Free in current prod posture. Returns real verdict + real citations. | **Demo + dogfood path** |
| `--dry-run` | Uses in-process stub caller. No network. Synthetic `act` verdict. | Fastest sanity check |
| `--live` | Real x402 signing — NOT WIRED in v0.1. Raises `OraclePaymentRequired`. | Reserved for v0.2 |
| `--tier basic` | $0.25 single-pass verdict | Default |
| `--tier pro` | $0.75 — includes `backtest` field in the cached verdict | Higher-fidelity demo |

Expected stdout (default mode, against prod):

```
firing manual basic verdict for <agent_id> (protocol=<p>, idea='session:<spec_name>')...
  verdict=<act|pass|defer>  confidence=<0.0-0.85>  citations=<n>  dissent=<n>
```

Skill echo MUST: after running, run `inspect <id>` and surface the new `verdict_called` journal entry so the user sees the cycle landed durably. This is the load-bearing artifact of the demo loop.

## `purge` — clean up orphan rows

```
bb trade-agent purge [--status stopped|running|paused|halted] [--dry-run]
```

Deletes `agent_state` rows by status. Cleans up orphans from earlier runs where SIGKILL prevented the Mongo state update (so `ls` shows a row claiming `running` with no OS process backing it). Default purges `stopped`.

Does NOT delete journal entries — those are TTL-managed at 90 days.

Expected stdout:

```
PURGED       agent_abc123…
WOULD PURGE  agent_def456…    (with --dry-run)
no agents with status='stopped'   (when nothing matches)
```

Skill echo: surface the count purged. If 0, say so. If the user passes `--status running` without `--dry-run`, double-check: this purges Mongo rows for things that might still be running OS processes — confirm with the user first.

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
