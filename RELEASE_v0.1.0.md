# v0.1.0 — Strategy oracle for autonomous trading agents

**The verdict your trading agent should have called before it lost your money.**

A 7-voice adversarial panel — grounded in investor canon (Damodaran, Howard Marks, Berkshire) — returns `act / pass / defer` with **surviving dissent** and per-claim citations. Every paid call settles on Solana mainnet via [frames.ag](https://frames.ag). No API keys, no signup, just a wallet.

This is the **Colosseum submission cut** of gecko-claude — the user-facing scaffold (Claude Code skills, MCP wiring, install pipeline) that connects to the Gecko trading oracle.

---

## What you can do in 90 seconds

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

Then in Claude Code:

```
Read https://app.geckovision.tech/skill.md and follow the instructions.
```

Three prompts the demo walks through:

1. *"Should I deposit USDC into the Kamino USDC reserve right now?"* → panel verdict + dissent + citations
2. *"Use the gecko-trade-agent skill to deploy my strategy at ~/specs/kamino-dca.json in advisor mode."* → local advisor agent, your keys, your journal
3. *"What is my agent doing right now? Then fire a fresh verdict from the panel."* → heartbeat + journal + reverdict in ~5s

---

## What's in the box

### Trade-vertical skills (v0.1, new)

- **`gecko-trade-coach`** — conversational strategy builder; emits a schema-validated spec JSON
- **`gecko-trade-agent`** — local advisor runtime; deploy / list / inspect / pause / reverdict / stop. Advisor mode only in v0.1 — never holds keys, never signs.
- **`gecko-wallet`** — wallet ops (fund / balance / receive USDC)

### V1 idea-validation skills (foundation)

- `gecko-research`, `gecko-ask`, `gecko-sources`, `extract-page`, `fund-wallet`

### Examples

- `examples/trading-oracle/` — minimal Python client showing a single-shot `gecko_trade_research` call + envelope parsing
- `examples/dex-on-gecko/` — Next.js demo consuming verdicts in a DEX-style UI
- `examples/neobank-on-gecko/` — v1 builder example consuming `gecko_research`

---

## The numbers

```
4,874 corpus chunks · 7 panel voices · 80 settled mainnet tx · $0.17 lifetime spend per heavy user
```

- **Corpus:** Damodaran (NYU Stern PDFs), Howard Marks (Oaktree memos), Berkshire (1977–2024 shareholder letters) — all free + public-domain in v0.1
- **Panel:** 7 specialist voices in pro tier (5 in basic) running adversarial debate via AutoGen GroupChat
- **Settlement:** x402 protocol on Solana mainnet via frames.ag wallet — non-custodial, programmatic, ~1.6s confirmation

---

## Chain proof — verify yourself

Every paid call settles on Solana mainnet. Representative settled tx:

```
4FPSxDGJQykp3j5cbnkGjAd8DVebsHBmazLQNCfEFZ3okKrgWCQi81ujr7aJS8MEbHUDXPEqn7EMAVBdAxwUyWoY
```

[View on Solscan →](https://solscan.io/tx/4FPSxDGJQykp3j5cbnkGjAd8DVebsHBmazLQNCfEFZ3okKrgWCQi81ujr7aJS8MEbHUDXPEqn7EMAVBdAxwUyWoY)

Confirmed in 1.6 seconds. Real USDC settlement on mainnet.

---

## Why this is structurally different

| Existing surface | Sells | Picks a side? |
|---|---|---|
| Marketplaces (frames.ag, Bazaar, PaySH) | Directories of paid agents | ❌ Would have to take a side on every listing |
| LLM chat (ChatGPT, Claude, Perplexity) | Conversation | ❌ Sycophant by default — tells you what you want to hear |
| Vector DBs (Pinecone, Weaviate) | Retrieval | ❌ No verdict; just chunks |
| **Gecko** | **The verdict** + dissent + citations + on-chain proof | ✅ |

The strategy-oracle layer is structurally ours because anyone who runs a marketplace cannot also pick winners inside their own catalog.

---

## Architecture (three layers, never collapsed)

```
gecko-trade-coach  →  spec.json (schema-validated)
         ↓
gecko_trade_research  →  verdict + dissent + citations  (7-voice oracle, investor-canon grounded)
         ↓
gecko-trade-agent  →  local advisor (your keys, your laptop; cache-then-charge; journal in Mongo)
         ↓
Execution adapters (v0.2): okx · sendai · backpack  (venue-neutral)
```

The agent runtime never reads the corpus directly — it calls the oracle. The oracle never touches keys. The execution layer never picks a verdict. Each layer is independently swappable.

---

## What's pinned in this release

- `gecko-mcp` Python package: `0.2.25` (PyPI; GitHub fallback at the same tag)
- Investor-canon corpus: Damodaran + Howard Marks + Berkshire (v0.1 scope, free + public-domain only)
- Settlement protocol: x402 via frames.ag on Solana mainnet
- Hosted MCP surface: `https://api.geckovision.tech/mcp/`

---

## Force of will

Caught a retrieval bug 2026-05-11 that hid the entire 4,800-chunk investor-canon corpus from the panel. Fixed it as architectural cleanup — session-scoped retrieval filters MUST tolerate permanent corpus — not a workaround. Validated in production smoke (11/11 pass). [See `docs/strategy/2026-05-11-retrieval-wedge-sprint.md` in the API repo](https://github.com/ernanibmurtinho/gecko-mcpay-api/blob/main/docs/strategy/2026-05-11-retrieval-wedge-sprint.md) for the root-cause writeup.

---

## Roadmap

- ✅ **v0.1** (this release) — trade oracle live, advisor mode, frames.ag settlement, investor-canon corpus
- ⏳ **v0.2** — trader mode (signed execution via okx / sendai / backpack adapters); licensed canon behind a tier flag
- 🔜 **v1.0** — multi-agent daemon mode; creator-attribution settlements on-chain to canonical-source contributors

---

## Sister repos

- [`gecko-mcpay-api`](https://github.com/ernanibmurtinho/gecko-mcpay-api) — Python backend (uv workspace: SDK, MCP server, FastAPI, CLI)
- `gecko-mcpay-app` — Next.js frontend at `app.geckovision.tech` (v3)

---

## License

MIT.

*Strategy oracle for autonomous trading agents · geckovision.tech · No API keys, just a wallet.*
