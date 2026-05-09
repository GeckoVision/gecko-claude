---
name: gecko
description: Bootstrap a Gecko-powered project in Claude Code. Installs gecko-mcp, connects the user's frames.ag wallet via email + OTP (no browser), prompts funding, and runs a first paid trade-research call. No API keys, no signup beyond the wallet. The flagship tool is gecko_trade_research — cited verdicts with surviving dissent on Solana DeFi protocols, settled per call in USDC via x402. 19 tools total.
---

# Gecko — Strategy Layer for Autonomous Agents

> **Wedge:** Gecko produces grounded, adversarially-debated verdicts on Solana DeFi questions. Seven specialists debate, the dissenters survive into the response, and every paid call returns a Solana tx hash. Your agent stops trading in the dark.

When a user pastes "Read https://app.geckovision.tech/skill.md and follow the instructions" into Claude Code, you (Claude) walk them through the four steps below. Every cent of payment runs on x402 over Solana via the user's frames.ag wallet.

## What you're installing

One MCP server (`gecko-mcp`) exposing **19 tools**. The flagship is `gecko_trade_research` — paid per call, returns a 7-agent panel verdict + surviving dissent + structured `citations[]` + an on-chain receipt. The other 18 tools are supporting plumbing — memory, classifiers, source catalogs, advisor panels — they exist because the trade panel needs them.

### Flagship — trade research (start here)

| Tool | Price | Purpose |
|---|---|---|
| `gecko_trade_research` (basic) | **$0.25** | 7-agent panel verdict on a Solana DeFi question + grounded citations. e.g. "Should I deposit USDC into Kamino?" |
| `gecko_trade_research` (pro) | **$0.75** | Same as basic + CoinGecko-OHLCV `backtest` field on the strategist's intent (entry/exit/horizon) |

Both routes return a `TradePanelVerdict` envelope:

```json
{
  "verdict": "act | pass | defer",
  "confidence": 0.0-1.0,
  "key_drivers": [...],
  "blocker_questions": [...],
  "surviving_dissent": [{"voice": "risk_manager", "text": "..."}],
  "citations": [
    {"id": 1, "source": "...", "url": "...", "chunk_id": "...",
     "provider_kind": "paysh_live | bazaar_live | coingecko | ...",
     "freshness_tier": "static | daily | live_only",
     "snippet": "..."}
  ],
  "turns": [...],            // per-agent transcript
  "backtest": {              // pro tier only
    "realized_pnl_pct": ..., "sharpe": ...,
    "max_drawdown_pct": ..., "sample_days": ...,
    "unbacktestable": false
  }
}
```

**Verify the surface is live without installing anything:**

```bash
curl -fsSL https://app.geckovision.tech/test.sh | bash
```

### Supporting tools — research, advisor panels, memory

**Paid (x402):**

| Tool | Price | Purpose |
|---|---|---|
| `gecko_research` (basic) | $0.10 | General-purpose research session — discover sources, index, generate cited business plan + validation report + V1/V2/V3 PRD |
| `gecko_research` (pro) | $0.75 | Same + 5-voice adversarial debate (analyst, critic, architect, scoper, judge) + market_landscape + surviving_dissent + dated falsifiers |
| `gecko_classify` | $0.10 | Classify an idea into Gecko's taxonomy + return a suggested-source list with priority weights |
| `gecko_plan` | $0.25 | Run the 5-voice Advisor Panel against an existing session — sprint plan with surviving dissent |
| `gecko_advise` | $0.05 | Run a single advisor voice (CEO / CTO / business_manager / product_manager / staff_manager) — 1 LLM call |
| `gecko_route` (default) | $0.01 | Route an LLM call through Gecko's cost-aware router (extraction/summary/default task_hint) |
| `gecko_route` (premium) | $0.05 | Premium tier — reasoning/code task_hint |
| `gecko_route` (upgrade) | $0.20 | Upgrade tier — `prefer_premium=True` |
| `gecko_review` (live) | $0.10 | Sprint review meta-tool — git log + memory + sprint docs → shipped[]/weakest_link/proposed_next[] |
| `gecko_scaffold` | $0.05 | Generate PRD.md + business-plan.md + BUILDING.md from a completed Pro debate |
| `gecko_report` | $0.05 | Generate a formatted HTML or markdown report for a completed session |
| `gecko_ask` | $0.01 (post-quota) | Follow-up question grounded in a session's chunks. First N calls per session FREE (default 100). |

**Free:**

| Tool | Purpose |
|---|---|
| `gecko_sources` | List indexed sources for the session (URL, type, chunk count, indexed_at) |
| `gecko_precedents` | Look up prior Gecko verdicts on similar ideas — top-K precedent rows with verdict + key_comparables |
| `gecko_available_sources` | Catalog of signal sources Gecko queries (Tavily, paysh_manifest, paysh_live, bazaar_manifest, bazaar_live, HN, Reddit, twit.sh, gecko_precedent flywheel, …) |
| `gecko_pulse` | Re-run advisor panel with fresh context — surface what changed since the last advise |
| `gecko_memory_save` | Append a typed entry to the decision-memory layer. Scope: `project | session | user` |
| `gecko_memory_recall` | Recall recent memory entries for a scope, newest first |
| `gecko_memory_search` | Cosine-similarity search over a scope's memory entries |
| `gecko_memory_query` | Structured filters (scope, entry_type, since, k) — falls back to cosine when `query` set |
| `gecko_resume` | Recap a project's recent loop activity — last advisor panel + last pulse deltas |
| `gecko_project_economics` | Per-project: privy wallet address, USDC balance, budget cap + spend, recent paid sessions |

## Step 1 — Run the installer

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

Claude: confirm with the user before running. Installer is idempotent. Verifies Python 3.11+, installs `uv` if missing, runs `uv tool install gecko-mcp`, copies `.claude/` + `CLAUDE.md` + `.mcp.json` into the current directory, registers `gecko` with Claude Code via `claude mcp add`.

## Step 2 — Connect the user's frames.ag wallet (inside Claude Code, no browser)

**First check `~/.agentwallet/config.json`.** If it exists with `apiToken`, the user is already connected — skip to Step 3 with "Already connected as @<username>."

Otherwise:

1. Ask the user for their email.
2. `POST https://frames.ag/api/connect/start` with `{"email": "<email>"}` → returns `{username, ...}`. Save `username` for the next call.
3. Tell the user: "I sent a 6-digit code to <email>. Paste it back here." Wait for OTP.
4. `POST https://frames.ag/api/connect/complete` with `{"username": "<u>", "email": "<email>", "otp": "<6 digits>"}` → returns `{apiToken, evmAddress, solanaAddress, ...}`.
5. Save to `~/.agentwallet/config.json` with `chmod 600`. **Never echo the apiToken.** Confirm to the user with username + Solana address only.
6. On error: bad OTP → frames returns 401, ask the user to try again; expired OTP → frames returns 400, restart from step 1; frames 5xx → tell the user frames is having issues, retry in a minute.

## Step 3 — Fund the wallet

Print: `https://frames.ag/u/<username>` and tell the user "Open this in your browser to fund your wallet via Coinbase Onramp (PIX in Brazil, card/bank elsewhere). $5 USDC covers ~6 pro trade-research calls (\$0.75 each), or ~20 basic calls (\$0.25), or ~50 advisor plans. Come back here when funded."

Optionally invoke the `fund-wallet` skill for full instructions on funding alternatives.

After they confirm funding: `gecko-mcp wallet balance` to verify. Don't proceed to Step 4 until balance > the call price they're about to invoke.

## Step 4 — First trade-research call

Suggest the canonical first call:

```
Use gecko_trade_research on Kamino with the question "should I deposit USDC into the USDC reserve right now?" — pro tier
```

Quote the price up-front: **$0.75** for pro (with `backtest` field), **$0.25** for basic. Default to pro for the first call — the surviving-dissent + backtest is the part of the product worth seeing first.

On approval, the MCP tool fires; payment settles in ~1.6s on Solana mainnet; the 7-agent panel runs ~30-60s; the full `TradePanelVerdict` lands in your context (verdict, confidence, key_drivers, surviving_dissent, citations, turns, backtest).

After the result lands, show:
- The `tx_hash` from the receipt — paste it as `https://solscan.io/tx/<sig>` for the user to verify.
- `gecko-mcp economics <session_id>` — cost/margin breakdown with the on-chain tx.
- The `surviving_dissent[]` array. **This is the wedge.** Read at least one dissent voice to the user verbatim — that's the part a generic LLM never gives you.

For follow-ups, suggest `gecko_ask` (\$0.01 post-quota, free under quota) to drill into a specific citation.

## A 60-second demo flow

If the user wants a quick end-to-end taste, run this exact sequence:

```
gecko_trade_research({                                                # $0.75 — pro tier with backtest
  idea: "Should I deposit USDC into Kamino's USDC reserve right now?",
  protocol: "kamino",
  vertical: "dex",
  tier: "pro"
})
gecko_ask({ session_id: "<from above>",
            question: "What's the actual util curve kink threshold?" })  # $0.01 (or free under quota)
gecko_report({ session_id: "<same>", format: "html" })                   # $0.05 — shareable artifact
```

Total: **~$0.81 USDC** in ~90 seconds. The `gecko_report` HTML is the artifact you share with partners or paste into a Colosseum / Stellar37 application.

For non-trading research (early-stage idea validation, not a DeFi decision), use `gecko_research` instead of `gecko_trade_research`. Same flow, different vertical surface.

## Notes for Claude Code

- The frames.ag apiToken (`mf_...`) is the user's only credential. **Never log, echo, or paste it into conversation, errors, or commit messages.** Treat like a password.
- The `~/.agentwallet/config.json` file is `chmod 600` and gitignored. Never commit.
- Surface frames.ag errors verbatim: `POLICY_DENIED`, `WALLET_FROZEN`, `insufficient_funds`, `PAYMENT_REJECTED`. Don't paraphrase. Each has a short remediation in `CLAUDE.md`.
- First-time users almost always need Step 3. Don't skip it; the demo dies on insufficient funds.
- Don't list all 19 tools to the user up-front — lead with `gecko_trade_research` and surface the others only when the question calls for them.
- Browse other Gecko skills at `https://app.geckovision.tech/skills/`.

## Hosted Streamable HTTP MCP

Live at `https://api.geckovision.tech/mcp/`. Lets MCP-only hosts (Cursor, Claude Desktop, Manus) skip the local install entirely. Your wallet is still the auth — same x402 payment flow, but the server runs in the cloud. Drop a `.mcp.json` in any project root:

```json
{
  "mcpServers": {
    "gecko": {
      "type": "http",
      "url": "https://api.geckovision.tech/mcp/"
    }
  }
}
```

19 tools auto-mount, including `gecko_trade_research`. No `install.sh`, no `uv tool install`. The hosted surface is the path of least resistance for a first call.

Status: check `https://app.geckovision.tech/test.sh` (one-line smoke against the live API) before relying on this in production.

---

## Change log

- **v4 (2026-05-09):** repositioned as **strategy layer for autonomous agents**. `gecko_trade_research` promoted to flagship — cited verdicts with `surviving_dissent[]` and structured `citations[]` (id, source, url, chunk_id, provider_kind, freshness_tier, snippet). Pro tier ships with `backtest` field (CoinGecko OHLCV replay on the strategist's intent). Mainnet x402 settlement live. ALB idle bumped to 120s for cold-start panel runs. Hosted MCP at `api.geckovision.tech/mcp/` is the recommended path. `gecko_research` basic price corrected from a documentation typo: it's $0.10, not $20.
- v3 (2026-05-07): tool count 3 → 19 (full surface visible to Claude Code now); added `paysh_manifest` + `paysh_live` retrieval sources (pay.sh — 5 meta-skills + 72 catalog providers, 21 neobank-relevant); added `bazaar_manifest` + `bazaar_live` retrieval sources (Coinbase Agentic Wallet marketplace — 50 of 683 services pinned, 8 neobank-relevant); hosted Streamable HTTP MCP at `mcp.geckovision.tech/mcp` rolling out.
- v2 (2026-04-15): added `gecko_classify`, `gecko_route`, `gecko_advise`, `gecko_plan`, memory tools.
- v1 (2026-03-01): initial 3 tools (`research`, `ask`, `sources`).

---

*Strategy Layer for Autonomous Agents · geckovision.tech · No API keys. Just a wallet.*
