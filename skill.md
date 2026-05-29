---
name: gecko
description: Build a Solana DeFi trading strategy in Claude Code in under 5 minutes. Three skills compose around one paid oracle — `gecko-trade-coach` builds the spec, `gecko_trade_research` produces grounded verdicts ($0.25 basic / $0.75 pro), `gecko-trade-agent` runs the spec as a long-running advisor on your machine. Wallet-only auth via frames.ag. Every paid verdict carries a Solana tx signature + Solscan link. 19 MCP tools total.
---

# Gecko — Coach. Oracle. Advisor.

> **Wedge:** Gecko is the strategy layer for autonomous agents. A conversational coach builds your spec, a paid oracle returns adversarially-debated verdicts grounded in cited sources, and a local advisor agent surfaces opportunities on your machine. Every paid call returns an on-chain Solana receipt.

When a user pastes "Read https://app.geckovision.tech/skill.md and follow the instructions" into Claude Code, you (Claude) walk them through the **three-minute install → first paid verdict** path below.

## The path — coach → oracle → advisor

```
gecko-trade-coach           gecko_trade_research              gecko-trade-agent
(conversational builder) →  (paid oracle: $0.25 / $0.75)  →  (local advisor process)
   "Should I LP in        ──▶  cited verdict + dissent  ──▶  Spec runs on user's
    Kamino USDC?"              + Solana tx signature          machine, surfaces ops
```

Three skills, one paid oracle. The oracle is the flagship — everything else exists because the oracle's verdict is worth deploying around.

## Flagship — `gecko_trade_research`

**Pricing (advertised up-front, before first call):**

| Tier | Price | What you get |
|---|---|---|
| basic | **$0.25** | 7-agent panel verdict, surviving dissent, structured citations, on-chain receipt |
| pro   | **$0.75** | Same + CoinGecko-OHLCV `backtest` field (entry/exit replay on the strategist's intent) |

Both tiers return a `TradePanelVerdict` envelope:

```json
{
  "verdict": "act | pass | defer",
  "confidence": 0.0-1.0,
  "key_drivers": [...],
  "blocker_questions": [...],
  "dissent_count": 2,
  "citations": [
    {"id": 1, "source": "paysh", "url": "...", "chunk_id": "...",
     "provider_kind": "paysh_live", "freshness_tier": "live_only",
     "snippet": "..."}
  ],
  "turns": [...],
  "backtest": { "pnl_pct": ..., "drawdown_pct": ..., "hit_rate": ... },
  "tx_signature": "5J7pRecorded...",
  "solscan_url": "https://solscan.io/tx/5J7pRecorded...",
  "settlement_mode": "live"
}
```

**Receipt fields** (`tx_signature`, `solscan_url`, `settlement_mode`) are present on every envelope. In stub mode (free / test calls), `tx_signature` and `solscan_url` are `null` and `settlement_mode="stub"`. On mainnet x402 settle, all three fields point at the real transaction.

## The three-minute happy path

### Step 1 — Install (60 seconds)

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

Idempotent. Verifies Python 3.11+, installs `uv` if missing, runs `uv tool install gecko-mcp`, copies `.claude/` + `CLAUDE.md` + `.mcp.json` into the cwd, and registers `gecko` with Claude Code (`claude mcp add gecko -- gecko-mcp serve`). Auto-installs the three companion skills (`gecko-trade-coach`, `gecko-wallet`, `gecko-trade-agent`).

Confirm with the user before running. After install, the user has 19 MCP tools available and three skill manifests in `~/.claude/skills/`.

### Step 2 — Connect a frames.ag wallet (60 seconds, inside Claude Code, no browser)

First check `~/.agentwallet/config.json`. If it exists with `apiToken`, the user is already connected — skip to Step 3 with "Already connected as @<username>."

Otherwise:

1. Ask the user for their email.
2. `POST https://frames.ag/api/connect/start` with `{"email": "<email>"}` → returns `{username, ...}`.
3. Tell the user: "I sent a 6-digit code to <email>. Paste it back here." Wait for OTP.
4. `POST https://frames.ag/api/connect/complete` with `{"username", "email", "otp"}` → returns `{apiToken, evmAddress, solanaAddress, ...}`.
5. Save to `~/.agentwallet/config.json` with `chmod 600`. **Never echo the apiToken.** Confirm with username + Solana address only.
6. Errors: bad OTP → 401, retry; expired OTP → 400, restart; frames 5xx → retry in a minute.

### Step 3 — Fund + first paid verdict (60 seconds)

Print: `https://frames.ag/u/<username>`. Tell the user: "Open this to fund your wallet via Coinbase Onramp (PIX in Brazil; card/bank elsewhere). $5 USDC covers ~6 pro verdicts ($0.75 each) or ~20 basic ($0.25). Come back here when funded." Then `gecko-mcp wallet balance` to verify.

Once funded, suggest the canonical first call (pro tier — the backtest + surviving dissent is the part worth seeing first):

```
Use gecko_trade_research on Kamino with the question
"should I deposit USDC into the USDC reserve right now?" — pro tier
```

Quote the price up-front: **$0.75**. On approval, x402 settles in ~1.6s on Solana mainnet; the 7-agent panel runs ~30-60s; the `TradePanelVerdict` lands in your context with the Solscan URL embedded.

After the result lands, **always** show the user:

1. The `solscan_url` field — clickable proof of on-chain settlement.
2. At least one entry from `surviving_dissent[]` read verbatim — this is the wedge a generic LLM never gives.
3. The `citations[]` count and one snippet — proof the verdict is grounded.

For follow-ups: `gecko_ask` ($0.01 post-quota, free under quota) to drill into a specific citation.

## Companion skills

Three Claude Code skills auto-installed by `install.sh`. They make the oracle deployable.

| Skill | What it does | When to invoke |
|---|---|---|
| `gecko-trade-coach` | Multi-step conversational strategy builder. Each decision grounded by a coach-internal oracle call. Emits a schema-validated JSON spec with citation IDs baked into every rule. | "Build me a trading strategy" / "help me think through a Solana DeFi position" |
| `gecko-wallet` | Natural-language wallet co-pilot. Routes execution to `okx-agentic-wallet` / `okx-dex-swap`; consults `gecko_trade_research` when the intent carries judgment ("should I top up", "is now a good time to bridge"). Never holds keys. | "I need some SOL", "fund my agent", "should I bridge USDC to Base" |
| `gecko-trade-agent` | Wraps the local `bb trade-agent` CLI. Deploys a coach-emitted spec as a long-running advisor process (v0.1: advisor-only, never auto-signs). Calls `gecko_trade_research` on cadence + triggers, cache-then-charge — typical agent costs ~$1.50/day. | "Deploy strategy X", "show my agents", "what is my agent doing", "stop agent Y" |

Cost shape: oracle calls inside the coach + wallet skills cost the same $0.25 / $0.75. The trade-agent runtime adds scheduled re-verdicts (1 basic/day + ~3 triggered/day) — ~$1.50/day per running agent. All cache-first; identical ideas don't double-charge.

## Due-diligence skills (rigor layer above other marketplaces)

Standalone skills that grade other people's bots / traders / strategies — the rigor layer above any marketplace that ranks by raw cumulative PnL. Live at `app.geckovision.tech/skills/`.

| Skill | What it does | When to invoke |
|---|---|---|
| `gecko-copy-trade-grader` | Pulls live OKX `smartmoney` leaderboards, computes Sharpe + Sortino + true max-DD + catastrophic-rate + stability + selection-deflated Sharpe, outputs A/B/C/D grade with reasoning. Catches the 34% of OKX top-50 that grade D under rigor + the 89% of leaderboard appearances that are period-rotation noise. | "Grade this OKX trader" · "Should I copy [nickname]" · "Run rigor on the OKX leaderboard" · "Most underrated traders" · "Cross-period stability" |

Empirically validated 2026-05-28: of OKX top-50 over 30d, only 5 grade A, 17 grade D, and ~11% of leaderboard appearances are persistently skilled across 30d AND 90d. Documented in `skills/gecko-copy-trade-grader/examples/`.

Pricing (post-MVP): $0.05 USDC per grade via x402 → ~300x ROI vs OKX's $125 min copy size.

## Security-validation skills (rigor layer on agent safety)

Standalone skills that generate adversarial inputs to test your agent's defenses BEFORE shipping. Built as Gecko's own internal QA process for adopting on-chain security partners (Bento Guard); released MIT so any Solana agent team can run the same test on their own stack.

| Skill | What it does | When to invoke |
|---|---|---|
| `gecko-honeypot-generator` | Generates 112+ adversarial inputs across 5 attack classes — typo variants, unicode lookalikes (Cyrillic Р→P), hidden zero-width chars, mint substitution (same symbol, different mint), contract honeypot patterns (sell-disabled, tax-100%, hidden mint authority, etc). Outputs a JSON corpus consumable by any pre-flight security SDK. Run BEFORE shipping. | "Generate adversarial inputs for my trading agent" · "Test my bot against honeypot tokens" · "Show me typo variants of PYTH" · "Validate my pre-flight security check" |

Empirical signal from our own bot (2026-05-28): static allowlist catches 92% of the 112-input corpus; the 8% bypass is ALL mint substitution — the class that only pre-flight TX simulation can catch. That 8% is the empirical case for adopting an on-chain guardrail like Bento Guard. The catch rate of `(your stack + your guardrail)` on the corpus is your auditable safety claim.

## Supporting MCP tools (you rarely surface these — invoke when called for)

**Paid (x402):**

| Tool | Price | Purpose |
|---|---|---|
| `gecko_research` (basic) | $0.10 | General-purpose research session — discover sources, index, generate cited business plan + V1/V2/V3 PRD |
| `gecko_research` (pro) | $0.75 | Same + 5-voice adversarial debate + market_landscape + surviving_dissent |
| `gecko_classify` | $0.10 | Classify an idea into Gecko's taxonomy + suggested-source list |
| `gecko_plan` | $0.25 | 5-voice Advisor Panel sprint plan with surviving dissent |
| `gecko_advise` | $0.05 | Single advisor voice |
| `gecko_route` | $0.01-$0.20 | Cost-aware LLM router |
| `gecko_review` | $0.10 | Sprint review meta-tool |
| `gecko_scaffold` | $0.05 | PRD.md + business-plan.md + BUILDING.md from a Pro debate |
| `gecko_report` | $0.05 | Formatted HTML/markdown report |
| `gecko_ask` | $0.01 (free under quota) | Follow-up question grounded in a session's chunks |

**Free:**

`gecko_sources`, `gecko_precedents`, `gecko_available_sources`, `gecko_pulse`, `gecko_memory_save/recall/search/query`, `gecko_resume`, `gecko_project_economics`.

## Verify the surface is live (zero install)

```bash
curl -fsSL https://app.geckovision.tech/test.sh | bash
```

## Hosted Streamable HTTP MCP

For MCP-only hosts (Cursor, Claude Desktop, Manus) — skip the local install:

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

19 tools auto-mount including `gecko_trade_research`. Your wallet is still the auth — same x402 payment flow, server runs in the cloud.

## Notes for Claude Code

- The frames.ag apiToken (`mf_...`) is the user's only credential. **Never log, echo, or paste it into conversation, errors, or commit messages.**
- `~/.agentwallet/config.json` is `chmod 600` and gitignored. Never commit.
- Surface frames.ag errors verbatim: `POLICY_DENIED`, `WALLET_FROZEN`, `insufficient_funds`, `PAYMENT_REJECTED`. Don't paraphrase.
- First-time users almost always need Step 3 (funding). Don't skip it; the demo dies on insufficient funds.
- Lead with `gecko_trade_research` — surface other tools only when the question calls for them.
- If anything in the install path is unclear, run `gecko-mcp doctor` — it walks the user through every missing piece with a one-line remediation per row.
- Browse other Gecko skills at `https://app.geckovision.tech/skills/`.

---

## Change log

- **v5 (2026-05-12):** Repositioned around the **coach → oracle → advisor** path. Three-minute install + first-verdict happy path lifted to the top. Pricing surfaced before first call. Settlement receipt fields (`tx_signature`, `solscan_url`, `settlement_mode`) documented on the envelope. Legacy idea-validation framing de-emphasised (`gecko_research` moved to supporting tools).
- v4 (2026-05-09): repositioned as strategy layer for autonomous agents. `gecko_trade_research` promoted to flagship.
- v3 (2026-05-07): tool count 3 → 19; added paysh + bazaar retrieval sources; hosted Streamable HTTP MCP.
- v2 (2026-04-15): added `gecko_classify`, `gecko_route`, `gecko_advise`, `gecko_plan`, memory tools.
- v1 (2026-03-01): initial 3 tools.

---

*Strategy Layer for Autonomous Agents · geckovision.tech · No API keys. Just a wallet.*
