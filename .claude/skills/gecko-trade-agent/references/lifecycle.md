# Agent lifecycle

> State machine, heartbeat semantics, cold-restart behavior, and the v0.1/v0.2 advisor-vs-trader split.

## States

Four named states. The skill should always name the state literally — never improvise synonyms like "active" or "frozen".

| State | Set by | Process | Positions | Entry signals | How to leave |
|---|---|---|---|---|---|
| `running` | successful `up` | foreground, ticking | tracked | journaled | `pause`, `stop`, crash |
| `paused` | `bb trade-agent pause <id>` | still foreground, ticking | tracked | suppressed | re-run `up` (resume), or `stop` |
| `stopped` | `bb trade-agent stop <id>` | exits on next poll | last-known snapshot in journal | none | fresh `up` |
| `halted` | runtime auto (circuit breaker) | foreground, in cool-down | tracked | suppressed | cool-down expires, or `stop` + `up` after spec fix |

### Transitions

```
                pause
running ─────────────────► paused
   │                         │
   │ stop          resume    │ stop
   ▼                ▲        ▼
stopped ◄─── up ────┘    stopped
   │
   │ up
   ▼
running

(running | paused) ─── circuit breaker trip ──► halted ──► (cooldown expires) ──► running
```

`halted` is automatic. The runtime journals a `circuit_breaker_trip` event with the trigger (`daily_loss_pct >= X` or `dissent_strength >= Y`) and the verdict_id that justified it. Cool-down duration is spec-defined.

## Heartbeat semantics

The runtime ticks on a ~30 second cadence (subject to mode + spec config). Each tick writes a journal entry with the current `ts`. The most recent journal `ts` is treated as `last_tick_at`.

| `now - last_tick_at` | Skill should say |
|---|---|
| < 2 minutes | `healthy — last tick <secs>s ago` |
| 2 – 10 minutes | `slow — last tick <mins>m ago; check process and network` |
| > 10 minutes | `**DEAD or asleep** — last tick at <HH:MM>; foreground process likely exited or laptop slept` |

If the runtime build doesn't journal an explicit `last_tick_at` event, the skill must NOT fabricate a heartbeat. Say plainly: *"This runtime build doesn't report heartbeats yet — check the foreground `bb trade-agent up` process directly."*

## Cold restart

The runtime is intentionally restart-safe. State (positions, journal, last verdict, mode, spec snapshot) lives in Mongo. A foreground process is just the consumer of that state.

To resume after a crash / sleep / network drop:

```
bb trade-agent up --spec <original-spec-path> --agent-id <existing-id>
```

The runtime detects the existing `agent_state` row by id, re-attaches, and resumes ticking. No positions are lost; the journal is append-only.

If the user lost the spec file but knows the agent id, the skill can read the `spec_id` and `spec_version` from `inspect`'s status line — but the actual JSON spec must still exist on disk. If it doesn't, re-route to `gecko-trade-coach` to regenerate from the same source.

## Hot-swap (founder mental model — not user-visible)

The runtime supports atomic spec cutover under the hood (new spec spawns in parallel, assumes positions, old process drains). The skill does NOT advertise this. From the user's perspective the flow is:

1. Edit your spec file.
2. `stop` the agent.
3. `up` with the new spec (same `--agent-id` if you want to keep journal continuity).

The atomic-cutover detail is an implementation choice; surfacing it now invites questions we don't want to answer in v0.1.

## Advisor mode (v0.1)

The only mode shipping in v0.1.

- Runtime listens to hot-path events (Helius / Pyth via the runtime's websocket layer).
- Each candidate is evaluated against the spec's primitives.
- Candidates that pass the spec are journaled as `opportunity` events — never signed, never executed.
- The verdict oracle is still called on schedule (daily basic refresh + startup pro verdict + triggered events) so the journaled opportunity carries a verdict_id + citations.
- User reads the journal via `inspect` and acts manually (typically via `gecko-wallet` or `okx-dex-swap`).

This is the only mode. If the user asks for trader mode, say:

> Trader mode lands in v0.2. Advisor mode is shipping now — it surfaces opportunities with verdict + citations for you to act on, but never signs transactions or holds keys.

## Trader mode (v0.2 — documented, blocked)

Not in v0.1. When it lands:

- Same runtime, `--mode trader`.
- Requires `--exec-rail <okx|sendai|backpack>`.
- Verdict cache must be warm; the entry gate is cache-first.
- Circuit breaker thresholds become live exit triggers, not just journal entries.

Until then: blocked. The flag exists in the CLI signature (`--mode {advisor,trader}`) but `--exec-rail` selection is gated and SendAI/Backpack adapters ship behind a stub/live mode toggle (Pattern C — contract test gates the live flip).

## Failure recovery cheat sheet

| Symptom | What it means | What to do |
|---|---|---|
| `inspect` shows `last tick > 10 min ago` | Foreground died (sleep, crash, network) | `up --spec <same> --agent-id <same>` to resume; check tmux/launchd wrapper |
| `circuit_breaker_trip` in journal | Daily loss or dissent threshold breached | Read trip event verbatim; surface citations from the trip verdict; if structural, re-route to `gecko-trade-coach` to revise the spec |
| `agent '<id>' not found` | Wrong id, wrong Mongo, or state row deleted | Run `ls` to confirm; check `MONGODB_URI` points at the same DB |
| `spec invalid` on `up` | Coach-emitted JSON failed schema | Re-route to `gecko-trade-coach` |
| No `opportunity` events for hours | Either market quiet (expected) or hot-path layer disconnected | Tail journal for `helius_disconnect` / `pyth_disconnect`; restart `up` if needed |
