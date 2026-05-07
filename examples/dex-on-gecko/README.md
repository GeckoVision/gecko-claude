# dex-on-gecko

Minimal example: a builder uses Claude Code + Gecko (via MCP) to scaffold a Solana DEX — AMM design, slippage policy, MEV mitigation, oracle integration — with adversarial verdict synthesis.

This example is the **DEX vertical** counterpart to [`../neobank-on-gecko/`](../neobank-on-gecko/). Same shape, different vertical: neobank tests the regulated-fintech corpus; DEX tests the on-chain-trading corpus.

See parent: [`../../README.md`](../../README.md). Runbook: [`../SMOKE_TEST.md`](../SMOKE_TEST.md).

---

## Setup

```bash
git clone https://github.com/ernanibmurtinho/gecko-claude.git
cd gecko-claude/examples/dex-on-gecko
npm install
claude code
```

`.mcp.json` points at `https://api.geckovision.tech/mcp/` by default (hosted MCP, live).

For local stdio against a sibling `gecko-mcpay-api` clone:

```bash
claude code --mcp-config .mcp.local.json
```

---

## First query

In Claude Code, type:

```
Use gecko_research --tier pro --vertical dex --idea "build a Solana CLMM DEX with concentrated liquidity, MEV-resistant routing, and Pyth oracles. What's the V1 that materially differentiates from Orca, Raydium, and Meteora — and what would falsify the wedge in 14 days?"
```

More prompts in [`PROMPTS.md`](./PROMPTS.md).

## What you'll see

Same shape as `neobank-on-gecko` but specific to DEX:

- **Surviving dissent** — likely about MEV exposure, oracle manipulation, or LP impermanent loss
- **Market landscape** with axis-by-axis comparison vs Orca / Raydium / Meteora
- **Falsifiers** — dated next-steps. Example: "if 3 LPs don't commit $10k each in 7 days, kill the wedge"
- **5-voice debate** — architect proposes the AMM math, critic flags the regulatory ambiguity, scoper cuts to a 4-day V1

Pro tier session ≈ $0.75 USDC.

## Why a second vertical example

Proves Gecko's architecture isn't single-vertical. Same MCP, same tools, same wallet, different domain corpus → different verdict. The retrieval layer routes by `vertical` automatically (when seeded — neobank live today; DEX seeding is queued for S23 alongside the marketplace catalog ingestion).

> If your `gecko_research` against a DEX prompt comes back grounded mostly in Tavily web sources rather than DEX-specific paysh/bazaar chunks, you've reproduced the FIX-12 source-routing gap. The verdict shape (debate, dissent, falsifiers) is correct; the corpus depth is what S23 fills in.
