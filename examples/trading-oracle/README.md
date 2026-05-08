# trading-oracle

Reference Claude Code skill demonstrating **Gecko's KaaS oracle pattern**.

## Three lanes, no overlap

| Lane | Owner | Responsibility |
|---|---|---|
| **Knowledge** | Gecko (this skill calls it) | Adversarial-debate verdict from a Solana-DeFi corpus tagged per protocol. |
| **Intent shape** | `solana-claude` `defi-engineer` agent (Superteam Brasil bundle) | Kamino / Jupiter / Drift / Raydium / Orca / Meteora request payloads. |
| **Settlement** | User's devnet keypair (or Kamino webapp / lana.ai on mainnet) | Local sign + submit. Gecko never sees the keypair. |

## What's in here

- **`skill.md`** — Claude Code skill manifest. Setup + use instructions.
- **`.mcp.json`** — mounts `mcp.geckovision.tech` (Gecko's hosted MCP, 19 tools).
- **`example_call.py`** — local helper for devnet sign + submit. The Claude Code session is the orchestrator; this file is a callable when the session needs to actually execute.
- **`README.md`** — this file.

## What this proves

The integration shape works end-to-end:

1. Partner skill calls Gecko via MCP for grounded research. ✅
2. Gecko's verdict cites real chunks from x402-paid Bazaar sources (Zerion portfolio data, Exa web search) tagged per protocol. ✅
3. Verdict hands off cleanly to a separate execution-expertise agent. ✅
4. Execution stays client-side; Gecko has no key access. ✅

Today's corpus: 27 chunks across 5 Solana-DeFi protocols (Jupiter, Kamino, Pyth, Drift, Jito). Each chunk paid via x402 EIP-3009 settlement on Base mainnet through twit.sh's funded buyer wallet.

## What's NOT in here (yet)

- **paysh integration** (Phase 7) — Solana-native x402 sources via Solana Foundation's pay.sh catalog. Requires a Solana-capable buyer (separate keypair scheme).
- **Real mainnet execution** — out of scope for a reference skill. Use Kamino's web app, lana.ai, Jito bundles, or your own venue.
- **Full LLM-gateway coverage** — Bazaar's Claude/DeepSeek/Perplexity listings have upstream issues today (blockrun.ai is a static page, Venice uses non-standard SIWE x402, paysponge Perplexity gateway broken). As marketplaces upgrade their listings, more chunks will land in the corpus automatically.

## Architecture references

- Gecko KaaS positioning memo: `gecko-mcpay-api/memory/project_kaas_positioning_2026_05_08.md`
- Trading-oracle design spec: `gecko-mcpay-api/docs/superpowers/specs/2026-05-08-trading-oracle-reference-skill-design.md`
- Implementation plan + commits: `gecko-mcpay-api/docs/superpowers/plans/2026-05-08-trading-oracle-reference-skill.md` and `git log feat/trading-oracle-reference-skill --oneline | head -25`.

## Validation checklist

A working install means:

- [ ] `cat .mcp.json` shows the Gecko MCP entry.
- [ ] In Claude Code, after mounting this directory, `Use the trading-oracle skill: research Kamino USDC reserve` produces a verdict that cites at least one URL from `agentic.market` or `api.zerion.io` (paid Bazaar chunks).
- [ ] `python example_call.py` prints the helper banner without errors (no env required).
- [ ] If a devnet keypair exists, `submit_signed_tx_devnet(<unsigned-tx-b64>)` sign+submits to devnet.
