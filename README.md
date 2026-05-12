# gecko-claude — strategy oracle for autonomous trading agents

[![Claude Code](https://img.shields.io/badge/claude--code-MCP-D97757.svg)](https://docs.anthropic.com/claude/claude-code)
[![x402](https://img.shields.io/badge/x402-Solana-9945FF.svg)](https://x402.org/)
[![frames.ag](https://img.shields.io/badge/wallet-frames.ag-000000.svg)](https://frames.ag/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

**The verdict your trading agent should have called before it lost your money.**

A 7-voice adversarial panel — grounded in investor canon (Damodaran, Howard Marks, Berkshire) — returns `act / pass / defer` with **surviving dissent** and per-claim citations. Every paid call settles on Solana mainnet via [frames.ag](https://frames.ag). No API keys, no signup, just a wallet.

> *"I lost money on my last three Solana trades because the LLM just told me what I wanted to hear. So I built the oracle my agent should have called instead."* — Ernani, founder

---

## Install (60 seconds, one line)

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

Then in Claude Code, paste:

```
Read https://app.geckovision.tech/skill.md and follow the instructions.
```

Claude walks you through wallet setup (email + OTP, ~30s) and funding (~$5 USDC covers ~50 verdicts).

---

## What you can do in 90 seconds

### 1. Ask the panel a single trade question

```
Should I deposit USDC into the Kamino USDC reserve right now?
```

Returns a verdict envelope:

```
verdict:       defer
confidence:    0.7
dissent_count: 2  (surviving — visible on screen)
citations:     [Damodaran "Equity Risk Premium" · Howard Marks Oaktree memo · …]
```

Every citation links to the actual source — investor canon, not LLM hallucination.

### 2. Deploy a local advisor agent

```
Use the gecko-trade-agent skill to deploy my strategy at ~/specs/kamino-dca.json in advisor mode.
```

Returns an `agent_id`. The agent lives on your laptop — your keys, your journal — and surfaces opportunities on a schedule. It **never signs** anything in v0.1.

### 3. Inspect + fire a fresh verdict

```
What is my agent doing right now? Then fire a fresh verdict from the panel.
```

The agent reports heartbeat, journal, and a re-cached panel verdict in ~5 seconds.

---

## Why this is structurally different

| Existing surface | Sells | Picks a side? |
|---|---|---|
| Marketplaces ([frames.ag](https://frames.ag), Bazaar) | **Directories** of paid agents | ❌ Would have to take a side on every listing |
| LLM chat (ChatGPT, Claude, Perplexity) | **Conversation** | ❌ Sycophant by default — tells you what you want to hear |
| Vector DBs (Pinecone, Weaviate) | **Retrieval** | ❌ No verdict; just chunks |
| **Gecko** | **The verdict** + dissent + citations + on-chain proof | ✅ |

The strategy-oracle layer is structurally ours because anyone who runs a marketplace cannot also pick winners inside their own catalog.

---

## What's in this repo

| Path | Purpose |
|---|---|
| `install.sh` | One-line installer (`curl \| bash`); idempotent, mac+linux. |
| `skill.md` | Master entry point hosted at `app.geckovision.tech/skill.md`. |
| `.claude/skills/` | 8 skills — 3 trade-vertical (coach / agent / wallet) + 5 V1 (research / ask / sources / extract / fund). |
| `.claude/agents/` | 5 sub-agent personas (analyst, validator, architect, builder). |
| `examples/trading-oracle/` | Minimal Python client showing a single-shot `gecko_trade_research` call + envelope parsing. |
| `examples/dex-on-gecko/` | Next.js demo app consuming Gecko verdicts in a DEX-style UI. |
| `CLAUDE.md` | Working agreement that ships into the user's project. |
| `docs/flow.md` | End-to-end sequence diagram (cold install → first paid verdict). |

---

## The tool surface

| MCP tool | Cost | Returns |
|---|---|---|
| **`gecko_trade_research`** | **$0.25** (basic, 5 voices) / **$0.75** (pro, 7 voices + backtest) | Verdict + confidence + citations + surviving dissent. *The wedge.* |
| `gecko_research` | $0.10 / $0.75 | Idea validation: business plan, market report, V1/V2/V3-scoped PRD. *The v1 product — same panel architecture, different vertical.* |
| `gecko_ask` | free | Follow-up Q&A grounded in the active session's sources. |
| `gecko_sources` | free | Lists every source with chunk counts. |
| `extract-page` | ~$0.004/URL | Tavily Extract for bot-walled pages. |
| `fund-wallet` | — | Walks the user through topping up their frames.ag wallet. |

---

## The skills

### Trade vertical (v0.1)

| Skill | Purpose |
|---|---|
| **`gecko-trade-coach`** | Conversational strategy builder. Emits a schema-validated spec JSON the agent runtime consumes. |
| **`gecko-trade-agent`** | Local advisor runtime. Deploy / list / inspect / pause / reverdict / stop a long-running agent. Advisor mode only in v0.1 — never holds keys, never signs. |
| **`gecko-wallet`** | Wallet ops (fund / check balance / receive USDC). |

### V1 — idea validation

| Skill | Purpose |
|---|---|
| `gecko-research` | Paid validation entry point. |
| `gecko-ask` | Free follow-ups grounded in indexed sources. |
| `gecko-sources` | Free; lists sources for the active session. |
| `extract-page` | Paid Tavily Extract (~$0.004/URL) for bot-walled pages. |
| `fund-wallet` | Wallet topping-up flow. |

---

## Chain proof — verify the demo yourself

Every paid call settles on Solana mainnet. A representative settled tx:

```
4FPSxDGJQykp3j5cbnkGjAd8DVebsHBmazLQNCfEFZ3okKrgWCQi81ujr7aJS8MEbHUDXPEqn7EMAVBdAxwUyWoY
```

[View on Solscan →](https://solscan.io/tx/4FPSxDGJQykp3j5cbnkGjAd8DVebsHBmazLQNCfEFZ3okKrgWCQi81ujr7aJS8MEbHUDXPEqn7EMAVBdAxwUyWoY)

Confirmed in 1.6 seconds. Real USDC settlement on mainnet. No API key, no signup.

---

## The numbers

```
4,874 corpus chunks · 7 panel voices · 80 settled mainnet tx · $0.17 lifetime spend per heavy user
```

- **Corpus:** Damodaran (NYU Stern PDFs), Howard Marks (Oaktree memos), Berkshire (1977–2024 shareholder letters) — all free + public-domain in v0.1.
- **Panel:** 7 specialist voices in pro tier (5 in basic) running adversarial debate via AutoGen GroupChat.
- **Settlement:** x402 protocol on Solana mainnet via frames.ag wallet — non-custodial, programmatic, ~1.6s confirmation.

---

## How it works

```
1. You paste one line into Claude Code
   ↓
2. Claude orchestrates: install → wallet OTP → fund prompt → MCP register
   ↓
3. You ask: "Should I deposit USDC into Kamino now?"
   ↓
4. frames.ag wallet pays $0.25 USDC on Solana → gecko-api runs the panel
   ↓
5. Verdict + dissent + citations land in your context. Decide from there.
```

End-to-end: ~3 minutes from cold install to first verdict. Full sequence in [`docs/flow.md`](./docs/flow.md).

---

## Architecture (three layers, never collapsed)

```
┌─────────────────────────────────────────────────────────────────┐
│  gecko-trade-coach  →  spec.json (schema-validated)             │
│  (conversational strategy builder)                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  gecko_trade_research  →  verdict + dissent + citations         │
│  (7-voice oracle; investor-canon grounded; on cadence + trigger)│
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  gecko-trade-agent  →  local advisor (your keys, your laptop)   │
│  (cache-then-charge; journal in Mongo; advisor mode in v0.1)    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Execution adapters (v0.2): okx · sendai · backpack             │
│  (venue-neutral; agent doesn't pick the wallet provider)        │
└─────────────────────────────────────────────────────────────────┘
```

The agent runtime never reads the corpus directly — it calls the oracle. The oracle never touches keys. The execution layer never picks a verdict. Each layer is independently swappable.

---

## Sub-agents (`.claude/agents/`)

After a verdict lands, five pre-baked personas help you act on it:

| Agent | Role |
|---|---|
| `research-analyst` | Explore the verdict; run free `gecko_ask` follow-ups. |
| `market-validator` | Adversarial reader of the verdict + dissent. |
| `technical-architect` | Translate strategy spec into runnable code. |
| `validator` | Pre-execution sanity check. |
| `builder` | Scaffolds the integration. |

---

## Cost transparency

Per `gecko_trade_research` basic at $0.25 retail:

| Line | Real cost |
|---|---|
| LLM (5-voice debate, gpt-4o-mini) | $0.012 |
| Embeddings (text-embedding-3-small) | $0.002 |
| Retrieval (Mongo Atlas Search) | $0.001 |
| **Total** | **$0.015** |
| **Margin** | **$0.235 (94%)** |

Run `gecko-mcp economics <session_id>` after any session for the full breakdown.

---

## Examples

- [`examples/trading-oracle/`](./examples/trading-oracle/) — minimal Python client showing `gecko_trade_research` call + envelope parsing.
- [`examples/dex-on-gecko/`](./examples/dex-on-gecko/) — Next.js demo consuming verdicts in a DEX-style UI.
- [`examples/neobank-on-gecko/`](./examples/neobank-on-gecko/) — v1 builder example consuming `gecko_research` for a neobank scaffold.

---

## Roadmap

- ✅ **v0.1** (now) — trade oracle live, advisor mode, frames.ag settlement, investor-canon corpus.
- ⏳ **v0.2** — trader mode (signed execution via okx / sendai / backpack adapters); licensed canon (O'Reilly, Perlego) behind a tier flag.
- 🔜 **v1.0** — multi-agent daemon mode; creator-attribution settlements on-chain to canonical-source contributors.

---

## Sister repos

- [`gecko-mcpay-api`](https://github.com/ernanibmurtinho/gecko-mcpay-api) — Python backend (uv workspace: SDK, MCP server, FastAPI, CLI).
- `gecko-mcpay-app` — Next.js frontend at `app.geckovision.tech` (v3).

---

## License

MIT. See [`LICENSE`](./LICENSE).

---

*Strategy oracle for autonomous trading agents · geckovision.tech · No API keys, just a wallet.*
