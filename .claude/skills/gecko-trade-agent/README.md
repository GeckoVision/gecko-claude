# gecko-trade-agent

> User-facing wrapper for the local `bb trade-agent` runtime. Deploy, list, inspect, pause, stop self-hosted advisor agents — grounded by Gecko's verdict oracle.

## what this is

A thin Claude Code skill on top of the `bb trade-agent` CLI. The runtime is a long-running Python process living on your machine; this skill translates "what's my agent doing?" into the right CLI invocation and reads the result back in plain language.

The runtime calls `gecko_trade_research` (Gecko's verdict oracle) on a schedule and at agent startup. Every entry candidate is checked against surviving dissent and investor-canon citations before being journaled.

## what this is NOT

- Not an execution engine. v0.1 ships **advisor mode only** — opportunities are journaled for you to act on manually. Trader mode lands in v0.2.
- Not a key-holder. The runtime never sees private keys. Funding and execution live in the `gecko-wallet` peer skill.
- Not a hosted service. The runtime runs on your laptop / VPS / wherever you put it. Failure modes (sleep, network drop) are documented in `references/lifecycle.md`.
- Not a strategy designer. The coach skill (`gecko-trade-coach`) emits the spec; this skill deploys it.

## install

The runtime + skill ship together. Install Gecko with:

```bash
curl -fsSL app.geckovision.tech/install.sh | bash
```

Then in Claude Code:

```
Use the gecko-trade-agent skill to deploy my strategy at ~/specs/mean-revert.json.
```

## cost

The skill itself is free. The runtime calls the verdict oracle on your behalf via x402:

- **scheduled daily refresh** — $0.25 USDC (basic tier)
- **startup verdict** — $0.75 USDC (pro tier; cache-first, charged on miss)
- **triggered re-verdicts** (circuit-breaker trips, manual prompts) — $0.25 each, rate-limited

Steady-state expected cost per running agent: **~$1.50/day**. Settled on Solana via x402.

## sample intents

| You say | Skill runs | You see |
|---|---|---|
| "deploy strategy at ~/specs/mr.json" | `bb trade-agent up --spec ~/specs/mr.json` | new agent id + advisor-mode confirmation |
| "show my agents" | `bb trade-agent ls` | one row per agent: id, status, mode, spec version |
| "what is agent_abc123 doing" | `bb trade-agent inspect agent_abc123` | status, heartbeat, open positions, last 20 journal events |
| "pause new entries on agent_abc123" | `bb trade-agent pause agent_abc123` | `paused — existing positions still managed` |
| "stop agent_abc123" | `bb trade-agent stop agent_abc123` | `stopped — foreground process will exit on next status poll` |

## peer skills

- `gecko-trade-coach` — builds the strategy spec this skill deploys
- `gecko-wallet` — funds the agent's wallet; never duplicated here

## license

MIT.
